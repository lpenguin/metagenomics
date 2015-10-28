app.directive 'barChart', ->
  restrict: 'E'
  replace: true
  templateUrl: 'templates/directives/bar-chart.html'
  scope:
    data: '='
    filteredSamples: '='
    filters: '='
    filterValues: '='
    quantityCheckbox: '='
    barChart: '='
    dotChart: '='
    colorScale: '='
  link: ($scope, $element, $attrs) ->
    element = $element[0]
    d3element = d3.select element

    $scope.tooltip =
      shown: false
      coordinates:
        x: undefined
        y: undefined
      substance: undefined
      abundance: undefined
      nOfSamples: undefined

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
    resistance = undefined
    substances = []

    nOfCohorts = 0
    nOfAxisCaptions = 4

    $scope.degree = 0
    multiplier = 0

    barWidthScale = d3.scale.linear()
    yScale = d3.scale.linear().range [height, 0]

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
      nOfCohorts = 0

      if $scope.filterValues['cohorts'].value is 'gender'
        $scope.data.genders.forEach (c) ->
          cohorts[c] = $scope.filteredSamples.filter (fS) -> fS['gender'] is c
          nOfCohorts++ if cohorts[c].length
          return
      else if $scope.filterValues['cohorts'].value is 'age'
        $scope.data.ages.forEach (c) ->
          cohorts[c] = $scope.filteredSamples.filter (fS) -> c[0] <= fS['age'] <= c[1]
          nOfCohorts++ if cohorts[c].length
          return
      else if $scope.filterValues['cohorts'].value is 'country'
        $scope.data.countries.forEach (c) ->
          cohorts[c] = $scope.filteredSamples.filter (fS) -> fS['country'] is c
          nOfCohorts++ if cohorts[c].length
          return
      else if $scope.filterValues['cohorts'].value is 'diagnosis'
        $scope.data.diagnosis.forEach (c) ->
          cohorts[c] = $scope.filteredSamples.filter (fS) -> fS['diagnosis'] is c
          nOfCohorts++ if cohorts[c].length
          return
      return

    updateResistanceAndSubstances = ->
      resistance = $scope.filterValues['resistance'].value

      if resistance is 'antibiotic resistance'
        substances = $scope.data.antibiotics.slice(0).reverse()
      return

    getSubstanceMeanValue = (substance, samples) ->
      mean = d3.mean _.pluck(samples, resistance).map (p) ->
        _.result _.find(p, {'category': substance}), 'sum_abund'
      mean = 0 unless mean
      mean

    updateBarWidthScale = ->
      if $scope.quantityCheckbox.on
        barWidthScale.domain [0, $scope.filteredSamples.length]
      else
        barWidthScale.domain [0, nOfCohorts]

      barWidthScale.range [0, width - (nOfCohorts - 1) * barGap]
      return

    updateYScaleAndAxis = ->
      maxAbund = d3.max _.keys(cohorts).map (key) ->
        d3.sum substances.map (s) ->
          d3.mean _.pluck(cohorts[key], resistance).map (cR) ->
            _.result _.find(cR, {'category': s}), 'sum_abund'

      yScale.domain [0, maxAbund]

      maxExponent = maxAbund.toExponential()
      $scope.degree = parseInt(maxExponent.split('-')[1]) + 1
      multiplier = Math.pow 10, $scope.degree

      yAxis
      .tickValues ->
        values = d3.range 0, maxAbund + maxAbund / (nOfAxisCaptions - 1), maxAbund / (nOfAxisCaptions - 1)

        values.map (v, i) -> unless i is values.length - 1 then (v * multiplier).toFixed(0) / multiplier else v
      .tickFormat (d, i) ->
        isLast = i is nOfAxisCaptions - 1

        (d * multiplier).toFixed(unless isLast then 0 else 2) + (unless isLast then '' else ' × 10')
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
        .text -> unless $scope.filterValues['cohorts'].value is 'age' then key else key.replace(',', '–').replace('–Infinity', '+')

        captionGroup.append 'text'
        .classed 'quantity-caption', true
        .attr 'y', 15

        substances.forEach (s) ->
          cohortGroup.append 'rect'
          .classed 'bar', true
          .datum s
          .attr 'y', height
          .attr 'height', 0
          .style 'fill', $scope.colorScale s
          .on 'mouseover', ->
            samples = cohorts[key].filter (cs) -> _.find cs[resistance], {'category': s}
            mean = getSubstanceMeanValue s, samples
            abundance = (mean * multiplier).toFixed(2)

            $scope.tooltip.shown = true
            $scope.tooltip.coordinates.x = d3.event.pageX
            $scope.tooltip.coordinates.y = d3.event.pageY
            $scope.tooltip.substance = s
            $scope.tooltip.abundance = abundance
            $scope.tooltip.nOfSamples = samples.length
            $scope.$apply()
            return
          .on 'mousemove', ->
            $scope.tooltip.coordinates.x = d3.event.pageX
            $scope.tooltip.coordinates.y = d3.event.pageY
            $scope.$apply()
            return
          .on 'mouseout', ->
            $scope.tooltip.shown = false
            $scope.$apply()
            return
          .on 'click', ->
            $scope.filterValues[resistance] = _.find _.find($scope.filters, {'key': resistance}).dataset, {'value': s}
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
      .append 'tspan'
      .style 'baseline-shift', 'super'
      .style 'display', (d, i) -> 'none' unless i is nOfAxisCaptions - 1
      .text '−' + $scope.degree

      yAxisGroup.selectAll 'line'
      .style 'display', (d, i) -> 'none' unless i

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

        caption.select '.quantity-caption'
        .text cohortSamples.length

        caption.style 'display', -> 'none' unless cohortSamples.length and caption.node().getBBox().width < barWidth

        substances
        .sort (a, b) ->
          a = getSubstanceMeanValue a, cohortSamples
          b = getSubstanceMeanValue b, cohortSamples
          b - a
        .forEach (s) ->
          bar = cohortBars.filter (b) -> b is s
          mean = getSubstanceMeanValue s, cohortSamples

          bar
          .transition()
          .duration 300
          .attr 'x', x
          .attr 'y', yScale(meanSum + mean)
          .attr 'width', barWidth
          .attr 'height', yScale(meanSum) - yScale(meanSum + mean)

          meanSum += mean
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

        bars
        .filter (b) -> b is substance
        .transition()
        .delay 400
        .duration 300
        .attr 'y', (d) -> height - d3.select(@).node().getBBox().height
      else
        updateGraph()

        bars
        .transition()
        .delay 400
        .duration 300
        .style 'opacity', 1
        .style 'display', ''
      return

    updateCohorts()
    updateResistanceAndSubstances()
    updateBarWidthScale()
    updateYScaleAndAxis()
    prepareGraph()
    updateGraph()

    $scope.$watch 'filterValues[filterValues["resistance"].value]', (newValue, oldValue) ->
      unless newValue is oldValue
        showSpecificSubstance $scope.filterValues[resistance].value
      return

    $scope.$watch 'filteredSamples', (newValue, oldValue) ->
      unless newValue is oldValue
        updateCohorts()
        updateBarWidthScale()
        updateYScaleAndAxis()
        updateGraph()
      return
    , true

    $scope.$watch 'filterValues["cohorts"]', (newValue, oldValue) ->
      unless newValue is oldValue
        updateCohorts()
        updateBarWidthScale()
        updateYScaleAndAxis()
        prepareGraph()
        updateGraph()
      return

    $scope.$watch 'quantityCheckbox.on', (newValue, oldValue) ->
      unless newValue is oldValue
        updateBarWidthScale()
        updateGraph()
      return

    return
