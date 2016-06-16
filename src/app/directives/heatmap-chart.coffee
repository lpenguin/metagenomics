app.directive 'heatmapChart', (calculators, colors) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/heatmap-chart.html'
  scope:
    data: '='
    colorScale: '='
  link: ($scope, $element, $attrs) ->
    $scope.cells = {}
    $scope.SMP = {}

    $scope.gradient = colors.gradient

    $scope.abundanceValuesExtent = $scope.colorScale.domain()
    $scope.maxPower = parseInt $scope.abundanceValuesExtent[1].toExponential().split('-')[1]

    filteredSamples = []

    legendWidth = $element.find('.legend-gradient').width()

    legendScale = d3.scale.linear()
      .domain $scope.abundanceValuesExtent
      .range [0, legendWidth]

    $scope.tooltip =
      substance: ''
      abundanceValue: undefined
      nOfSamples: undefined
      coordinates:
        x: undefined
        y: undefined

    prepareCells = ->
      $scope.data.countries.forEach (c) ->
        $scope.cells[c['name']] = {}
        _.keys($scope.data.resistances).forEach (r) ->
          $scope.cells[c['name']][r] = {}
          $scope.data.substances.forEach (s) ->
            $scope.cells[c['name']][r][s['category_name']] = 0
            return
          return
        return
      return

    prepareSMP = ->
      $scope.data.countries.forEach (c) ->
        $scope.SMP[c['name']] = 0
        return
      return

    updateCells = ->
      $scope.data.countries.forEach (c) ->
        _.keys($scope.data.resistances).forEach (r) ->
          $scope.data.substances.forEach (s) ->
            cSamples = filteredSamples.filter (fs) -> fs['f-countries'] is c['name']
            $scope.cells[c['name']][r][s['category_name']] = calculators.getAbundanceValue cSamples, r, s
            return
          return
        return
      return

    updateSMP = ->
      $scope.data.countries.forEach (c) ->
        cSamples = filteredSamples.filter (fs) -> fs['f-countries'] is c['name']
        $scope.SMP[c['name']] = cSamples.length
        return
      return

    prepareCells()
    prepareSMP()

    $scope.getCellColor = (countryName, resistance, substance) ->
      value = $scope.cells[countryName][resistance][substance]
      unless value then colors.neutral else $scope.colorScale value

    $scope.substanceCellMouseover = (countryName, resistance, substance) ->
      csSamples = filteredSamples.filter (fs) ->
        fs['f-countries'] is countryName and
        fs[resistance][substance]

      $scope.tooltip.substance = substance
      $scope.tooltip.abundanceValue = $scope.cells[countryName][resistance][substance]
      $scope.tooltip.nOfSamples = csSamples.length
      return

    $scope.substanceCellMouseout = ->
      $scope.tooltip.substance = ''
      $scope.tooltip.abundanceValue = undefined
      return

    $scope.substanceCellMousemove = ($event) ->
      $scope.tooltip.coordinates.x = $event.clientX
      $scope.tooltip.coordinates.y = $event.clientY
      return

    $scope.getLegendPointerX = ->
      Math.min legendWidth, legendScale $scope.tooltip.abundanceValue ? 0

    $scope.$on 'samplesFiltered', (event, data) ->
      filteredSamples = data
      updateCells()
      updateSMP()
      return

    return
