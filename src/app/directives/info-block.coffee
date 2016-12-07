app.directive 'infoBlock', ($rootScope, colorScale) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/info-block.html'
  link: ($scope, $element, $attrs) ->
    legendWidth = $element.find('.gradient').width()
    legendScaleRange = d3.range 0, legendWidth, legendWidth / (colorScale.getRange().length - 1)
    legendScaleRange.push legendWidth
    frozenData = undefined

    $scope.legendGradient = colorScale.getRange()
    $scope.legendPointerX = 0
    $scope.legendScale = d3.scale.log()
      .domain colorScale.getDomain()
      .range legendScaleRange

    getLegendPointerX = (value) -> unless value then 0 else $scope.legendScale value

    # → Events
    $scope.$on 'substanceFilter.substanceChanged', (event, eventData) ->
      $scope.substance = eventData.substance
      $scope.infoLink = eventData.infoLink
      $scope.database = eventData.database
      return

    $scope.$on 'heatmapChart.cellChanged', (event, eventData, frozenCell) ->
      frozenData = frozenCell.eventData if frozenCell
      eventData = frozenData if _.isEmpty(eventData) and frozenData

      $scope.countryName = eventData.countryName
      $scope.flag = eventData.flag
      $scope.abundanceValue = eventData.abundanceValue
      $scope.abundanceValueType = eventData.abundanceValueType
      $scope.nOfSamples = eventData.nOfSamples

      $scope.legendPointerX = getLegendPointerX eventData.abundanceValue
      return

    $scope.$on 'mapChart.countryInOut', (event, eventData) ->
      eventData = frozenData if _.isEmpty(eventData) and frozenData

      $scope.countryName = eventData.countryName
      $scope.flag = eventData.flag
      $scope.abundanceValue = eventData.abundanceValue
      $scope.abundanceValueType = eventData.abundanceValueType
      $scope.nOfSamples = eventData.nOfSamples

      $scope.legendPointerX = getLegendPointerX eventData.abundanceValue
      return

    return
