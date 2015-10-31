app.directive 'barChart', ->
  restrict: 'E'
  replace: true
  templateUrl: 'templates/directives/bar-chart.html'
  scope:
    substanceFilters: '='
    sampleFilters: '='
    rscFilterValues: '='
    filteredSamples: '='
    barChart: '='
    dotChart: '='
    quantityCheckbox: '='
    colorScale: '='
    getNumWithSuperscript: '='
  link: ($scope, $element, $attrs) ->
    element = $element[0]
    d3element = d3.select element

    tooltip = d3element.select '.bar-chart__tooltip'
    tooltipSubstance = tooltip.select '.substance'
    tooltipAbundance = tooltip.select '.abundance'
    tooltipNofSamples = tooltip.select '.n-of-samples'

    tooltipOffset = 20

    outerWidth = $element.parent().width()
    outerHeight = $element.parent().height()

    padding =
      top: 20
      right: 30
      bottom: 30
      left: 30

    width = outerWidth - padding.left - padding.right
    height = outerHeight - padding.top - padding.bottom

    barGap = width * .01

    cohorts = {}
    nOfCohorts = 0

    resistance = undefined
    substances = []
    cohort = undefined

    nOfAxisCaptions = 4

    degree = 0
    multiplier = 0

    barWidthScale = d3.scale.linear()
    barYScale = d3.scale.linear().range [height, 0]

    yAxis = d3.svg.axis()
    .scale barYScale
    .tickSize width
    .orient 'right'

    svg = d3element.append 'svg'
    .classed 'bar-chart__svg', true
    .attr 'width', outerWidth
    .attr 'height', outerHeight

    g = svg.append 'g'
    .classed 'main', true
    .attr 'transform', 'translate(' + padding.left + ', ' + padding.top + ')'

    barsGroup = g.append 'g'
    .classed 'bars', true

    captionsGroup = g.append 'g'
    .classed 'captions', true
    .attr 'transform', 'translate(0, ' + height + ')'

    yAxisGroup = g.append 'g'
    .classed 'y-axis', true

    updateResistance = ->
      resistance = $scope.rscFilterValues.resistance.value
      return

    updateSubstances = ->
      substances = _.pluck(_.find($scope.substanceFilters, {'key': resistance}).dataset.slice(1), 'value').reverse()
      return

    updateCohort = ->
      cohort = $scope.rscFilterValues.cohort.value
      return

    updateCohorts = ->
      cohorts = {}
      nOfCohorts = 0

      _.find($scope.sampleFilters, {'key': cohort}).dataset.forEach (p) ->
        cohorts[p.title] = $scope.filteredSamples.filter (fS) ->
          if cohort is 'f-ages'
            p.value[0] <= fS[cohort] <= p.value[1]
          else
            fS[cohort] is p.value
        nOfCohorts++ if cohorts[p.title].length
        return
      return

    getSubstanceMedianValue = (substance, samples) ->
      median = d3.median _.pluck(samples, resistance).map (p) -> _.result p, substance
      median = 0 unless median
      median

    updateBarWidthScale = ->
      if $scope.quantityCheckbox.on
        barWidthScale.domain [0, $scope.filteredSamples.length]
      else
        barWidthScale.domain [0, nOfCohorts]

      barWidthScale.range [0, width - (nOfCohorts - 1) * barGap]
      return

    updateBarYScaleAndAxis = ->
      maxAbund = d3.max _.keys(cohorts).map (key) ->
        d3.sum substances.map (s) ->
          d3.median _.pluck(cohorts[key], resistance).map (cR) -> _.result cR, s

      barYScale.domain [0, maxAbund]

      maxExponent = maxAbund.toExponential()
      degree = parseInt(maxExponent.split('-')[1]) + 1
      multiplier = Math.pow 10, degree

      yAxis
      .tickValues ->
        values = d3.range 0, maxAbund + maxAbund / (nOfAxisCaptions - 1), maxAbund / (nOfAxisCaptions - 1)

        values.map (v, i) -> unless i is values.length - 1 then (v * multiplier).toFixed(0) / multiplier else v
      .tickFormat (d, i) ->
        if i is nOfAxisCaptions - 1
          $scope.getNumWithSuperscript (d * multiplier).toFixed(2), degree
        else
          (d * multiplier).toFixed(0)
      return

    prepareGraph = ->
      barsGroup.selectAll('*').remove()
      captionsGroup.selectAll('*').remove()

      _.keys(cohorts).forEach (key) ->
        captionGroup = captionsGroup.append 'g'
        .classed 'caption', true
        .datum key

        captionGroup.append 'text'
        .classed 'cohort-caption', true
        .attr 'y', 3
        .text -> key

        captionGroup.append 'text'
        .classed 'quantity-caption', true
        .attr 'y', 18

        cohortGroup = barsGroup.append 'g'
        .classed 'cohort', true
        .datum key

        substances.forEach (s) ->
          cohortGroup.append 'rect'
          .classed 'bar', true
          .datum s
          .attr 'y', height
          .attr 'height', 0
          .style 'fill', $scope.colorScale s
          .on 'mouseover', ->
            samples = cohorts[key].filter (cs) -> cs[resistance][s]
            median = getSubstanceMedianValue s, samples
            abundance = $scope.getNumWithSuperscript (median * multiplier).toFixed(2), degree

            tooltipSubstance.html s
            tooltipAbundance.html 'Abundance: ' + abundance
            tooltipNofSamples.html samples.length + ' ' + if samples.length is 1 then 'sample' else 'samples'

            tooltip
            .style 'display', 'block'
            .style 'top', d3.event.pageY + 'px'
            .style 'left', d3.event.pageX + tooltipOffset + 'px'
            return
          .on 'mousemove', ->
            tooltip
            .style 'top', d3.event.pageY + 'px'
            .style 'left', d3.event.pageX + tooltipOffset + 'px'
            return
          .on 'mouseout', ->
            tooltip.style 'display', ''
            return
          .on 'click', ->
            $scope.rscFilterValues.substance = _.find _.find($scope.substanceFilters, {'key': resistance}).dataset, {'value': s}
            $scope.$apply()
            return
          return
        return
      return

    updateGraph = ->
      yAxisGroup.call yAxis

      yAxisGroup.selectAll 'text'
      .attr 'dy', (d, i) -> if i is nOfAxisCaptions - 1 then -5 else 0
      .attr 'x', -15

      yAxisGroup.select 'line'
      .style 'display', 'none'

      x = 0

      _.keys(cohorts).forEach (key, i) ->
        medianSum = 0
        cohortSamples = cohorts[key]
        barWidth = barWidthScale if $scope.quantityCheckbox.on then cohortSamples.length else 1
        caption = d3element.selectAll('.caption').filter (c) -> c is key
        cohortGroup = barsGroup.selectAll('.cohort').filter (c) -> c is key
        cohortBars = cohortGroup.selectAll '.bar'

        caption
        .transition()
        .duration 300
        .attr 'transform', 'translate(' + x + ', 0)'

        caption.select '.quantity-caption'
        .text cohortSamples.length

        caption.style 'display', -> 'none' unless cohortSamples.length and caption.node().getBBox().width < barWidth

        cohortGroup
        .transition()
        .duration 300
        .attr 'transform', 'translate(' + x + ', 0)'

        substances.forEach (s) ->
          bar = cohortBars.filter (b) -> b is s
          median = getSubstanceMedianValue s, cohortSamples

          bar
          .transition()
          .duration 300
          .attr 'y', barYScale(medianSum + median)
          .attr 'width', barWidth
          .attr 'height', barYScale(medianSum) - barYScale(medianSum + median)

          medianSum += median
          return

        x += barWidth + barGap if cohortSamples.length
        return
      return

    showSpecificSubstance = (substance) ->
      bars = d3element.selectAll('.bar')

      if substance
        bars
        .filter (b) -> b isnt substance
        .transition()
        .duration 300
        .style 'opacity', 0
        .transition()
        .delay 300
        .style 'display', 'none'
        .style 'y', ''

        bars
        .filter (b) -> b is substance
        .style 'display', ''
        .transition()
        .duration 300
        .style 'opacity', 1
        .transition()
        .delay 300
        .duration 300
        .style 'y', (d) -> height - d3.select(@).node().getBBox().height
      else
        bars
        .style 'display', ''
        .style 'y', ''
        .attr 'y', (d) -> height - d3.select(@).node().getBBox().height

        updateGraph()

        bars
        .transition()
        .delay 300
        .duration 300
        .style 'opacity', 1
      return

    updateResistance()
    updateSubstances()
    updateCohort()
    updateCohorts()
    updateBarWidthScale()
    updateBarYScaleAndAxis()
    prepareGraph()
    updateGraph()

    $scope.$watch 'rscFilterValues.resistance', (newValue, oldValue) ->
      unless newValue is oldValue
        updateResistance()
        updateSubstances()
        updateBarYScaleAndAxis()
        prepareGraph()
      return

    $scope.$watch 'rscFilterValues.substance', (newValue, oldValue) ->
      unless newValue is oldValue
        showSpecificSubstance $scope.rscFilterValues.substance.value
      return

    $scope.$watch 'rscFilterValues.cohort', (newValue, oldValue) ->
      unless newValue is oldValue
        updateCohort()
        updateCohorts()
        updateBarWidthScale()
        updateBarYScaleAndAxis()
        prepareGraph()
        updateGraph()
      return

    $scope.$watch 'filteredSamples', (newValue, oldValue) ->
      unless newValue is oldValue
        updateCohorts()
        updateBarWidthScale()
        updateBarYScaleAndAxis()
        updateGraph()
      return
    , true

    $scope.$watch 'dotChart', (newValue, oldValue) ->
      unless newValue is oldValue
        console.log 'W: dot chart'
      return

    $scope.$watch 'quantityCheckbox.on', (newValue, oldValue) ->
      unless newValue is oldValue
        updateBarWidthScale()
        updateGraph()
      return

    return
