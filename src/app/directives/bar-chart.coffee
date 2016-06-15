app.directive 'barChart', (tools) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/bar-chart.html'
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
    substance = undefined
    cohort = undefined

    substances = []

    filteredSamples = []
    cohorts = {}
    nOfCohorts = 0

    nOfAxisCaptions = 4
    power = 0
    multiplier = 0

    duration = 300

    tooltip = d3element.select '.bar-chart__tooltip'
    tooltipSubstance = tooltip.select '.substance'
    tooltipAbundance = tooltip.select '.abundance'
    tooltipCohort = tooltip.select '.cohort'
    tooltipNofSamples = tooltip.select '.n-of-samples'
    tooltipOffset = 20

    barWidthScale = d3.scale.linear()

    barYScale = d3.scale.linear()
      .range [height, 0]

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

    updateResistance = ->
      resistance = $scope.rscFilterValues.resistance.value
      return

    updateSubstance = ->
      substance = $scope.rscFilterValues.substance.value
      return

    updateSubstances = ->
      sFilter = _.find $scope.substanceFilters, 'key': resistance
      substances = _.map sFilter.dataset.slice(1), 'value'
      substances = substances.reverse()
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

        nOfCohorts++ if cohorts[p.title].length
        return
      return

    getSubstanceMedianValue = (substance, samples) ->
      tools.preventNaN d3.median _.map(samples, resistance).map (p) -> p[substance]

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
          getSubstanceMedianValue s, cohorts[key]

      barYScale.domain [0, max]

      power = parseInt max.toExponential().split('-')[1]
      power += 1
      multiplier = Math.pow 10, power

      yAxis
        .tickValues ->
          step = max / (nOfAxisCaptions - 1)
          values = d3.range 0, max + step, step
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
              d3.select(@).style 'opacity', .7

              $scope.barChart.substance = s
              $scope.$apply()

              samples = cohorts[key].filter (cs) -> cs[resistance][s]
              median = getSubstanceMedianValue s, samples
              abundance = (median * multiplier).toFixed(2)

              tooltipSubstance.html s
              tooltipAbundance.html 'Median abundance: ' + abundance + ' × 10<sup>' + tools.goodMinus() + power + '</sup>'
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
              d3.select(@).style 'opacity', 1

              $scope.barChart.substance = undefined
              $scope.$apply()

              tooltip.style 'display', ''
              return
            .on 'click', ->
              sFilter = _.find $scope.substanceFilters, 'key': resistance
              $scope.rscFilterValues.substance = _.find sFilter.dataset, 'value': s
              $scope.$apply()
              return
          return
        return
      return

    updateAxis = ->
      yAxisGroup.call yAxis

      yAxisGroup.selectAll 'text'
        .attr 'x', -15
        .attr 'dy', 0

      d3.select yAxisGroup.selectAll('text')[0].pop()
        .attr 'dy', -5
        .append 'tspan'
        .style 'baseline-shift', 'super'
        .text tools.goodMinus() + power

      yAxisGroup.select 'line'
        .style 'display', 'none'
      return

    updateGraph = ->
      updateAxis()

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
          .duration duration
          .attr 'transform', 'translate(' + x + ', 0)'

        caption.select '.quantity-caption'
          .text cohortSamples.length

        caption.style 'display', -> 'none' unless cohortSamples.length and caption.node().getBBox().width < barWidth

        cohortGroup
          .transition()
          .duration duration
          .attr 'transform', 'translate(' + x + ', 0)'

        substances.forEach (s) ->
          sBar = cohortBars.filter (b) -> b is s
          median = getSubstanceMedianValue s, cohortSamples
          barHeight = barYScale(medianSum) - barYScale medianSum + median

          sBar
            .transition()
            .duration duration
            .attr 'y', ->
              if substance
                if s is substance then height - barHeight else barYScale medianSum + median
              else
                barYScale medianSum + median
            .attr 'width', barWidth
            .attr 'height', barHeight
            .style 'visibility', ->
              if substance
                if s is substance then 'visible' else 'hidden'
              else
                'visible'

          medianSum += median
          return

        x += barWidth + cohortGap if cohortSamples.length
        return
      return

    showSampleBars = (newValue, oldValue) ->
      currentCohort = newValue.cohort or oldValue.cohort
      sampleCohort = cohortsGroup.selectAll('.cohort').filter (c) -> c is currentCohort
      barWidth = barWidthScale if $scope.quantityCheckbox.on then cohorts[currentCohort].length else 1
      barWidth = (barWidth - cohortGap) / 2 if newValue.cohort

      sampleCohort.selectAll '.bar'
        .transition()
        .duration duration
        .attr 'width', barWidth

      if newValue.sample
        sampleBars = sampleCohort.append 'g'
          .classed 'sample-bars', true

        if substance
          sampleBars.append 'rect'
            .attr 'x', barWidth + cohortGap
            .attr 'y', height
            .attr 'width', barWidth
            .attr 'height', 0
            .style 'fill', $scope.colorScale substance
            .transition()
            .delay duration
            .duration duration
            .attr 'y', barYScale newValue.sample[resistance][substance]
            .attr 'height', height - barYScale newValue.sample[resistance][substance]
        else
          sumAbund = 0

          substances.forEach (s) ->
            bar = sampleBars.append 'rect'
            abund = newValue.sample[resistance][s]
            abund = 0 unless abund
            barHeight = barYScale(sumAbund) - barYScale sumAbund + abund

            bar
              .attr 'x', barWidth + cohortGap
              .attr 'y', height
              .attr 'width', barWidth
              .attr 'height', 0
              .style 'fill', $scope.colorScale s
              .transition()
              .delay duration
              .duration duration
              .attr 'y', barYScale sumAbund + abund
              .attr 'height', barHeight

            sumAbund += abund
            return
      else
        sampleCohort.select('.sample-bars').remove()
      return

    updateResistance()
    updateSubstance()
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
        updateSubstance()
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
        showSampleBars newValue, oldValue
      return
    , true

    $scope.$watch 'quantityCheckbox.on', (newValue, oldValue) ->
      unless newValue is oldValue
        updateBarWidthScale()
        updateGraph()
      return

    return
