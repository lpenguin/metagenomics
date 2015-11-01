app.directive 'dotChart', ($timeout) ->
  restrict: 'E'
  replace: true
  templateUrl: 'templates/directives/dot-chart.html'
  scope:
    substanceFilters: '='
    sampleFilters: '='
    rscFilterValues: '='
    filteredSamples: '='
    barChart: '='
    dotChart: '='
    colorScale: '='
  link: ($scope, $element, $attrs) ->
    element = $element[0]
    d3element = d3.select element

    outerWidth = $element.parent().width()
    outerHeight = $element.parent().height()

    padding =
      top: 20
      right: 30
      bottom: 50
      left: 50

    width = outerWidth - padding.left - padding.right
    height = outerHeight - padding.top - padding.bottom

    cohortGap = width * .01

    resistance = undefined
    substance = undefined
    cohort = undefined

    cohorts = {}
    nOfCohorts = 0
    bins = []
    nOfBins = 200
    histograms = {}

    sampleXScale = d3.scale.linear()
    sampleYScale = d3.scale.log().range [height, 0]
    yAxis = d3.svg.axis()
    .scale sampleYScale
    .tickSize width + 10
    .orient 'right'

    svg = d3element.append 'svg'
    .classed 'dot-chart__svg', true
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
    .attr 'transform', 'translate(' + -10 + ', 0)'

    tooltip = d3element.select '.dot-chart__tooltip'
    tooltipOffset = 20

    updateResistance = ->
      resistance = $scope.rscFilterValues.resistance.value
      return

    updateSubstance = ->
      substance = $scope.rscFilterValues.substance.value
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

        if substance
          cohorts[p.title] = cohorts[p.title].filter (cS) -> cS[resistance][substance]

        nOfCohorts++ if cohorts[p.title].length
        return
      return

    updateHistograms = ->
      extent = d3.extent $scope.filteredSamples.map (fS) ->
        if substance then fS[resistance][substance] else d3.sum _.values fS[resistance]
      bins = d3.range(extent[0], extent[1], extent[1] / nOfBins).concat extent[1]
      histograms = {}

      _.forOwn cohorts, (value, key) ->
        histograms[key] = d3.layout.histogram()
        .value (d) ->
          if substance then d[resistance][substance] else d3.sum _.values d[resistance]
        .bins(bins)(value)
        return
      return

    updateSampleScales = ->
      max = d3.sum _.keys(histograms).map (key) ->
        d3.max histograms[key].map (bin) -> bin.length

      sampleXScale
      .domain [0, max]
      .range [0, width - (nOfCohorts - 1) * cohortGap]

      sampleYScale.domain [bins[0], bins[bins.length - 1]]
      return

    updateGraph = ->
      cohortsGroup.selectAll('*').remove()
      captionsGroup.selectAll('*').remove()

      _.keys(cohorts).forEach (key) ->
        cohortSamples = cohorts[key]

        captionGroup = captionsGroup.append 'g'
        .classed 'caption', true
        .datum key

        captionGroup.append 'text'
        .classed 'cohort-caption', true
        .attr 'y', 23
        .text -> key

        captionGroup.append 'text'
        .classed 'quantity-caption', true
        .attr 'y', 38

        cohortGroup = cohortsGroup.append 'g'
        .classed 'cohort', true
        .datum key

        cohortGroup.append 'g'
        .classed 'bins', true

        cohortGroup.append 'rect'
        .classed 'median', true
        return

      yAxisGroup.call yAxis

      yAxisGroup.selectAll '.tick'
      .style 'display', 'none'

      goodTicks = yAxisGroup.selectAll '.tick'
      .filter (d) -> d / 10 ** Math.ceil(Math.log(d) / Math.LN10 - 1e-12) is 1

      goodTicks.style 'display', ''

      goodTicks.selectAll 'text'
      .attr 'dy', 0
      .attr 'x', -20
      .text 10
      .append 'tspan'
      .style 'baseline-shift', 'super'
      .text (d) -> Math.round Math.log(d) / Math.LN10

      x = 0

      _.keys(cohorts).forEach (key, i) ->
        cohortHistogram = histograms[key]
        cohortWidth = sampleXScale d3.max cohortHistogram.map (bin) -> bin.length
        caption = d3element.selectAll('.caption').filter (c) -> c is key
        cohortGroup = cohortsGroup.selectAll('.cohort').filter (c) -> c is key
        cohortBins = cohortGroup.select '.bins'
        cohortMedian = cohortGroup.select '.median'
        medianValue = d3.median cohorts[key].map (s) ->
          if substance then s[resistance][substance] else d3.sum _.values s[resistance]

        caption
        .transition()
        .duration 300
        .attr 'transform', 'translate(' + x + ', 0)'

        caption.select '.quantity-caption'
        .text cohorts[key].length

        caption.style 'display', -> 'none' unless caption.node().getBBox().width < cohortWidth

        cohortGroup.attr 'transform', 'translate(' + x + ', 0)'

        cohortHistogram.forEach (bin) ->
          groupBin = cohortBins.append 'g'
          .classed 'bin', true

          groupBin
          .transition()
          .duration 300
          .attr 'transform', (d) -> 'translate(0, ' + sampleYScale(bin.x) + ')'

          bin.forEach (s, i) ->
            groupBin.append 'circle'
            .classed 'sample', true
            .attr 'cx', 0
            .attr 'r', 3
            .style 'fill', if substance then $scope.colorScale(substance) else '#aaa'
            .style 'opacity', .7
            .on 'mouseover', ->
              abund = if substance then s[resistance][substance] else d3.sum _.values s[resistance]
              power = parseInt(abund.toExponential().split('-')[1])
              multiplier = Math.pow 10, power

              tooltip.html s['short_names'] + ': ' + (abund * multiplier).toFixed(2) + ' × 10<sup>−' + power + '</sup>'

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
              return
            .transition()
            .delay 300
            .duration 300
            .attr 'cx', sampleXScale i
            return
          return

        cohortMedian
        .attr 'width', 0
        .attr 'height', 1
        .attr 'x', -3
        .attr 'y', sampleYScale medianValue
        .style 'fill', '#333'
        .transition()
        .delay 600
        .duration 300
        .attr 'width', cohortWidth

        x += cohortWidth + cohortGap if cohortWidth
        return
      return

    updateResistance()
    updateSubstance()
    updateCohort()
    updateCohorts()
    updateHistograms()
    updateSampleScales()
    updateGraph()

    $scope.$watch 'rscFilterValues.resistance', (newValue, oldValue) ->
      unless newValue is oldValue
        updateResistance()
      return

    $scope.$watch 'rscFilterValues.substance', (newValue, oldValue) ->
      unless newValue is oldValue
        updateSubstance()
        updateCohorts()
        updateHistograms()
        updateSampleScales()
        $timeout (->updateGraph()), 500
      return

    $scope.$watch 'rscFilterValues.cohort', (newValue, oldValue) ->
      unless newValue is oldValue
        updateCohort()
        updateCohorts()
        updateHistograms()
        updateSampleScales()
        $timeout (->updateGraph()), 500
      return

    $scope.$watch 'filteredSamples', (newValue, oldValue) ->
      unless newValue is oldValue
        updateCohorts()
        updateHistograms()
        updateSampleScales()
        $timeout (->updateGraph()), 500
      return
    , true

    $scope.$watch 'barChart', (newValue, oldValue) ->
      unless newValue is oldValue
        console.log 'W: bar chart'
      return

    return
