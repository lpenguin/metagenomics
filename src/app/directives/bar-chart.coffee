app.directive 'barChart', ->
  restrict: 'E'
  replace: true
  templateUrl: 'templates/directives/bar-chart.html'
  scope:
    data: '='
    substanceFilters: '='
    sampleFilters: '='
    rscFilterValues: '='
    sampleFilterValues: '='
    barChart: '='
    dotChart: '='
    quantityCheckbox: '='
    colorScale: '='
  link: ($scope, $element, $attrs) ->
    element = $element[0]
    d3element = d3.select element

    outerWidth = $element.parent().width()
    outerHeight = $element.parent().height()

    padding =
      top: 20
      right: 30
      bottom: 30
      left: 30

    width = outerWidth - padding.left - padding.right
    height = outerHeight - padding.top - padding.bottom

    cohortGap = width * .01

    resistance = undefined
    cohort = undefined

    substances = []

    filteredSamples = []
    cohorts = {}
    nOfCohorts = 0

    nOfAxisCaptions = 4
    power = 0
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

    cohortsGroup = g.append 'g'
    .classed 'cohorts', true

    captionsGroup = g.append 'g'
    .classed 'captions', true
    .attr 'transform', 'translate(0, ' + height + ')'

    yAxisGroup = g.append 'g'
    .classed 'y-axis', true

    tooltip = d3element.select '.bar-chart__tooltip'
    tooltipSubstance = tooltip.select '.substance'
    tooltipAbundance = tooltip.select '.abundance'
    tooltipCohort = tooltip.select '.cohort'
    tooltipNofSamples = tooltip.select '.n-of-samples'
    tooltipOffset = 20

    updateResistance = ->
      resistance = $scope.rscFilterValues.resistance.value
      return

    updateSubstances = ->
      substances = _.pluck(_.find($scope.substanceFilters, {'key': resistance}).dataset.slice(1), 'value').reverse()
      return

    updateCohort = ->
      cohort = $scope.rscFilterValues.cohort.value
      return

    filterSamples = ->
      filteredSamples = $scope.data.samples.filter (s) ->
        _.every $scope.sampleFilters, (sF) ->
          filterValues = $scope.sampleFilterValues[sF.key]

          if filterValues.length
            _.some filterValues, (fV) ->
              if sF.key is 'f-ages'
                fV.value[0] <= s[sF.key] <= fV.value[1]
              else
                s[sF.key] is fV.value
          else
            true
      return

    updateCohorts = ->
      cohorts = {}
      nOfCohorts = 0

      _.find($scope.sampleFilters, {'key': cohort}).dataset.forEach (p) ->
        cohorts[p.title] = filteredSamples.filter (fS) ->
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
        barWidthScale.domain [0, filteredSamples.length]
      else
        barWidthScale.domain [0, nOfCohorts]

      barWidthScale.range [0, width - (nOfCohorts - 1) * cohortGap]
      return

    updateBarYScaleAndAxis = ->
      max = d3.max _.keys(cohorts).map (key) ->
        d3.sum substances.map (s) ->
          d3.median _.pluck(cohorts[key], resistance).map (cR) -> _.result cR, s

      barYScale.domain [0, max]

      power = parseInt(max.toExponential().split('-')[1]) + 1
      multiplier = Math.pow 10, power

      yAxis
      .tickValues ->
        values = d3.range 0, max + max / (nOfAxisCaptions - 1), max / (nOfAxisCaptions - 1)

        values.map (v, i) -> unless i is values.length - 1 then (v * multiplier).toFixed(0) / multiplier else v
      .tickFormat (d, i) ->
        isLast = i is nOfAxisCaptions - 1

        (d * multiplier).toFixed(unless isLast then 0 else 2) + (unless isLast then '' else ' × 10')
      return

    prepareGraph = ->
      cohortsGroup.selectAll('*').remove()
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

        cohortGroup = cohortsGroup.append 'g'
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
            $scope.barChart.substance = s
            $scope.$apply()

            samples = cohorts[key].filter (cs) -> cs[resistance][s]
            median = getSubstanceMedianValue s, samples
            abundance = (median * multiplier).toFixed(2)

            tooltipSubstance.html s
            tooltipAbundance.html 'Median abundance: ' + abundance + ' × 10<sup>−' + power + '</sup>'
            tooltipCohort.html key
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
            $scope.barChart.substance = undefined
            $scope.$apply()

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
      .attr 'x', -15
      .attr 'dy', 0

      d3.select yAxisGroup.selectAll('text')[0].pop()
      .attr 'dy', -5
      .append 'tspan'
      .style 'baseline-shift', 'super'
      .text '−' + power

      yAxisGroup.select 'line'
      .style 'display', 'none'

      x = 0

      _.keys(cohorts).forEach (key) ->
        medianSum = 0
        cohortSamples = cohorts[key]
        barWidth = barWidthScale if $scope.quantityCheckbox.on then cohortSamples.length else 1
        caption = d3element.selectAll('.caption').filter (c) -> c is key
        cohortGroup = cohortsGroup.selectAll('.cohort').filter (c) -> c is key
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
          barHeight = barYScale(medianSum) - barYScale(medianSum + median)

          bar
          .transition()
          .duration 300
          .attr 'y', barYScale(medianSum + median)
          .attr 'width', barWidth
          .attr 'height', barHeight
          .style 'y', ->
            if $scope.rscFilterValues.substance.value
              if s is $scope.rscFilterValues.substance.value
                height - barHeight
              else
                ''
            else
              ''
          .style 'visibility', ->
            if $scope.rscFilterValues.substance.value
              if s is $scope.rscFilterValues.substance.value
                'visible'
              else
                'hidden'
            else
              'visible'

          medianSum += median
          return

        x += barWidth + cohortGap if cohortSamples.length
        return
      return

    updateResistance()
    updateSubstances()
    updateCohort()
    filterSamples()
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
        updateGraph()
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

    $scope.$watch 'sampleFilterValues', (newValue, oldValue) ->
      unless newValue is oldValue
        filterSamples()
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
    , true

    $scope.$watch 'quantityCheckbox.on', (newValue, oldValue) ->
      unless newValue is oldValue
        updateBarWidthScale()
        updateGraph()
      return

    return
