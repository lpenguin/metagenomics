app.directive 'dotChart', ($timeout, tools, colors) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/dot-chart.html'
  scope:
    data: '='
    substanceFilters: '='
    sampleFilters: '='
    rscFilterValues: '='
    sampleFilterValues: '='
    barChart: '='
    dotChart: '='
    substanceColorScale: '='
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

    filteredSamples = []
    cohorts = {}
    nOfCohorts = 0
    bins = []
    nOfBins = 200
    histograms = {}

    sampleRadius = 3

    timer = undefined

    duration = 300

    tooltip = d3element.select '.dot-chart__tooltip'
    tooltipOffset = 20

    sampleXScale = d3.scale.linear()

    sampleYScale = d3.scale.log()
      .range [height, 0]

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

    updateResistance = ->
      resistance = $scope.rscFilterValues.resistance.value
      return

    updateSubstance = ->
      substance = $scope.rscFilterValues.substance.value
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

      _.find($scope.sampleFilters, 'key': cohort).dataset.forEach (p) ->
        cohorts[p.title] = filteredSamples.filter (fS) ->
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
      histograms = {}
      extent = d3.extent filteredSamples.map (fS) ->
        if substance then fS[resistance][substance] else d3.sum _.values fS[resistance]
      step = (extent[1] - extent[0]) / (nOfBins - 1)
      bins = d3.range extent[0], extent[1] + step, step

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

    updateAxis = ->
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
        .text (d) ->
          power = '' + Math.round Math.log(d) / Math.LN10
          power.replace '-', tools.goodMinus()
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

      updateAxis()

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
          .duration duration
          .attr 'transform', 'translate(' + (x - sampleRadius) + ', 0)'

        caption.select '.quantity-caption'
          .text cohorts[key].length

        caption.style 'display', -> 'none' unless caption.node().getBBox().width < cohortWidth

        cohortGroup.attr 'transform', 'translate(' + x + ', 0)'

        cohortHistogram.forEach (bin) ->
          groupBin = cohortBins.append 'g'
            .classed 'bin', true

          groupBin
            .transition()
            .duration duration
            .attr 'transform', (d) -> 'translate(0, ' + sampleYScale(bin.x) + ')'

          bin.forEach (s, i) ->
            groupBin.append 'circle'
              .classed 'sample', true
              .datum s
              .attr 'cx', 0
              .attr 'r', sampleRadius
              .style 'fill', if substance then $scope.substanceColorScale(substance) else colors.neutral
              .style 'opacity', .7
              .on 'mouseover', ->
                d3.select(@).style 'opacity', 1

                timer = $timeout ->
                  $scope.dotChart.sample = s
                  $scope.dotChart.cohort = key
                  $scope.$apply()
                , 500

                abund = if substance then s[resistance][substance] else d3.sum _.values s[resistance]
                power = parseInt abund.toExponential().split('-')[1]
                multiplier = Math.pow 10, power

                tooltip.html s['short_names'] + ': ' + (abund * multiplier).toFixed(2) + ' × 10<sup>' + tools.goodMinus() + power + '</sup>'

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
                d3.select(@).style 'opacity', .7

                $timeout.cancel timer

                if $scope.dotChart.sample or $scope.dotChart.cohort
                  $scope.dotChart.sample = undefined
                  $scope.dotChart.cohort = undefined
                  $scope.$apply()

                tooltip.style 'display', ''
                return
              .transition()
              .delay duration
              .duration duration
              .attr 'cx', sampleXScale i
            return
          return

        cohortMedian
          .attr 'width', 0
          .attr 'height', 1
          .attr 'x', -3
          .attr 'y', tools.preventNaN sampleYScale medianValue
          .style 'fill', '#333'
          .transition()
          .delay duration * 2
          .duration duration
          .attr 'width', cohortWidth

        x += cohortWidth + cohortGap if cohortWidth
        return
      return

    highlightSamples = ->
      d3element.selectAll '.sample'
        .transition()
        .duration duration
        .style 'fill', (d) ->
          if $scope.barChart.substance
            if d[resistance][$scope.barChart.substance] then $scope.substanceColorScale($scope.barChart.substance) else colors.neutral
          else
            colors.neutral
      return

    updateResistance()
    updateSubstance()
    updateCohort()
    filterSamples()
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
        $timeout ->
          updateGraph()
        , 500
      return

    $scope.$watch 'rscFilterValues.cohort', (newValue, oldValue) ->
      unless newValue is oldValue
        updateCohort()
        updateCohorts()
        updateHistograms()
        updateSampleScales()
        $timeout ->
          updateGraph()
        , 500
      return

    $scope.$watch 'sampleFilterValues', (newValue, oldValue) ->
      unless newValue is oldValue
        filterSamples()
        updateCohorts()
        updateHistograms()
        updateSampleScales()
        $timeout ->
          updateGraph()
        , 500
      return
    , true

    $scope.$watch 'barChart.substance', (newValue, oldValue) ->
      unless newValue is oldValue
        unless substance
          highlightSamples()
      return

    return
