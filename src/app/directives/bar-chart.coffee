app.directive 'barChart', ->
  restrict: 'E'
  replace: true
  templateUrl: 'templates/directives/bar-chart.html'
  scope:
    data: '='
    filteredSamples: '='
    filterValues: '='
    quantityCheckbox: '='
    barChart: '='
    dotChart: '='
    colorScale: '='
  link: ($scope, $element, $attrs) ->
    element = $element[0]
    d3element = d3.select element

    tooltip = d3element.select '.bar-chart__tooltip'
    tooltipOffset = 20

    outerWidth = $element.parent().width()
    outerHeight = outerWidth * .9
    padding =
      top: 20
      right: 30
      bottom: 30
      left: 30

    width = outerWidth - padding.left - padding.right
    height = outerHeight - padding.top - padding.bottom

    cohorts = {}
    resistance = undefined
    substances = []

    barGap = width * .01

    barWidthScale = d3.scale.linear()

    yScale = d3.scale.linear()

    nOfAxisCaptions = 4

    degree = 0

    yAxis = d3.svg.axis()
    .scale yScale
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

    updateCohorts = ->
      cohorts = {}

      if $scope.filterValues['cohorts'].value is 'country'
        $scope.data.countries.forEach (c) ->
          cohorts[c] = $scope.filteredSamples.filter (fS) -> fS['country'] is c
          return
      return

    updateSubstances = ->
      resistance = $scope.filterValues['resistance'].value
      if resistance is 'antibiotic resistance'
        substances = $scope.data.antibiotics.slice(0).reverse()
      return

    updateBarWidthScale = ->
      nOfCohorts = _.keys(cohorts).length

      if $scope.quantityCheckbox.on
        barWidthScale.domain [0, $scope.filteredSamples.length]
      else
        barWidthScale.domain [0, nOfCohorts]

      barWidthScale.range [0, width - (nOfCohorts - 1) * barGap]
      return

    updateYScale = ->
      max = d3.max _.keys(cohorts).map (key) ->
        d3.sum substances.map (s) ->
          d3.mean _.pluck(cohorts[key], resistance).map (cR) ->
            _.result _.find(cR, {'category': s}), 'sum_abund'

      yScale
      .domain [0, max]
      .range [height, 0]

      maxExponent = max.toExponential()
      degree = parseInt(maxExponent.split('-')[1]) + 1
      multiplier = Math.pow(10, degree)

      yAxis
      .tickValues d3.range 0, max + max / (nOfAxisCaptions - 1), max / (nOfAxisCaptions - 1)
      .tickFormat (d, i) ->
        (d * multiplier).toFixed(0) + (if i is nOfAxisCaptions - 1 then ' × 10' else '')
      return

    prepareGraph = ->
      barsGroup.selectAll('*').remove()
      captionsGroup.selectAll('*').remove()
      yAxisGroup.selectAll('*').remove()

      _.keys(cohorts).forEach (key) ->
        cohortGroup = barsGroup.append 'g'
        .classed 'cohort', true
        .datum key

        captionGroup = captionsGroup.append 'g'
        .classed 'caption', true
        .datum key

        captionGroup.append 'text'
        .classed 'cohort-caption', true
        .attr 'y', 3
        .text key

        captionGroup.append 'text'
        .classed 'quantity-caption', true
        .attr 'y', 15

        substances.forEach (s) ->
          cohortGroup.append 'rect'
          .classed 'bar', true
          .datum s
          .style 'fill', $scope.colorScale s
          return
        return
      return

    updateGraph = ->
      yAxisGroup
      .call yAxis
      .selectAll 'text'
      .attr 'dy', (d, i) ->
        if i is nOfAxisCaptions - 1 then -5 else 0
      .attr 'x', -15
      .append 'tspan'
      .attr 'baseline-shift', 'super'
      .text (d, i) ->
        if i is nOfAxisCaptions - 1 then '−' + degree else ''

      x = 0

      _.keys(cohorts).forEach (key, i) ->
        meanSum = 0
        cohortSamples = cohorts[key]
        barWidth = barWidthScale if $scope.quantityCheckbox.on then cohortSamples.length else 1
        cohortGroup = barsGroup.selectAll('.cohort').filter (c) -> c is key
        cohortBars = cohortGroup.selectAll '.bar'
        caption = d3element.selectAll('.caption').filter (c) -> c is key

        caption
        .transition()
        .duration 300
        .attr 'transform', 'translate(' + x + ', 0)'
        .style 'opacity', if cohortSamples.length then 1 else 0

        caption.select('.quantity-caption').text(cohortSamples.length + (if i is _.keys(cohorts).length - 1 then ' samples' else ''))

        substances.forEach (s) ->
          bar = cohortBars.filter (b) -> b is s
          mean = d3.mean _.pluck(cohortSamples, resistance).map (p) -> _.result _.find(p, {'category': s}), 'sum_abund'
          mean = 0 unless mean

          bar
          .transition()
          .duration 300
          .attr 'x', x
          .attr 'y', yScale(meanSum + mean)
          .attr 'width', barWidth
          .attr 'height', yScale(meanSum) - yScale(meanSum + mean)

          meanSum += mean
          return

        x += (barWidth + barGap)
        return
      return

    updateCohorts()
    updateSubstances()
    prepareGraph()

    updateBarWidthScale()
    updateYScale()

    updateGraph()

    $scope.$watch 'filterValues[filterValues["resistance"].value]', (newValue, oldValue) ->
      return if newValue is oldValue

      substance = $scope.filterValues[resistance].value

      if substance
        d3element.selectAll('.bar')
        .filter (b) -> b isnt substance
        .transition()
        .duration 300
        .style 'opacity', 0

        d3element.selectAll('.bar')
        .filter (b) -> b is substance
        .transition()
        .delay 400
        .duration 300
        .attr 'y', (d) -> height - d3.select(@).node().getBBox().height
      else
        updateGraph()

        d3element.selectAll('.bar')
        .transition()
        .delay 400
        .duration 300
        .style 'opacity', 1
      return

    $scope.$watch 'filteredSamples', (newValue, oldValue) ->
      return if newValue is oldValue

      updateCohorts()
      updateBarWidthScale()
      updateYScale()
      updateGraph()
      return
    , true

    $scope.$watch 'quantityCheckbox.on', (newValue, oldValue) ->
      return if newValue is oldValue

      updateBarWidthScale()
      updateGraph()
      return

    return
