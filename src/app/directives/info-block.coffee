app.directive 'infoBlock', ($rootScope, colorScale) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/info-block.html'
  link: ($scope, $element, $attrs) ->
    legendWidth = $element.find('.gradient').width()
    legendScaleRange = d3.range 0, legendWidth, legendWidth / (colorScale.getRange().length - 1)
    legendScaleRange.push legendWidth

    isFrozen = false

    $scope.legendGradient = colorScale.getRange()
    $scope.legendPointerX = 0
    $scope.legendScale = d3.scale.log()
      .domain colorScale.getDomain()
      .range legendScaleRange
    $scope.maxBarWidth = 76

    getLegendPointerX = (value) -> unless value then 0 else $scope.legendScale value

    # → Events
    changeCellInfo = (eventData) ->
      $scope.countryName = eventData.countryName
      $scope.flag = eventData.flag
      $scope.abundanceValue = eventData.abundanceValue
      $scope.abundanceValueType = eventData.abundanceValueType
      $scope.nOfSamples = eventData.nOfSamples
      $scope.topFiveList = eventData.topFiveList
      $scope.legendPointerX = getLegendPointerX eventData.abundanceValue
      return

    changeSubstanceInfo = (eventData) ->
      $scope.substance = eventData.substance
      $scope.infoLink = eventData.infoLink
      $scope.database = eventData.database
      return

    $scope.$on 'substanceFilter.substanceChanged', (event, eventData, ignoreFrozen) ->
      return if isFrozen and not ignoreFrozen

      changeSubstanceInfo eventData
      return

    $scope.$on 'substanceFilter.defaultSubstanceChanged', (event, eventData) ->
      changeSubstanceInfo eventData
      changeCellInfo {}
      isFrozen = false
      return

    $scope.$on 'heatmapChart.cellChanged', (event, eventData, ignoreFrozen) ->
      return if isFrozen and not ignoreFrozen

      changeCellInfo eventData
      return

    $scope.$on 'mapChart.countryInOut', (event, eventData) ->
      return if isFrozen

      changeCellInfo eventData
      return

    $scope.$on 'heatmapChart.cellIsFrozen', ->
      isFrozen = true
      return

    $scope.$on 'heatmapChart.cellIsUnfrozen', ->
      isFrozen = false
      return

    $scope.getBarColor = (value) ->
      colorScale.getColorByValue value

    return
