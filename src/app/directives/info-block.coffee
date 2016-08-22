app.directive 'infoBlock', ($rootScope, colorScale) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/info-block.html'
  link: ($scope, $element, $attrs) ->
    legendHeight = $element.find('.gradient').height()
    legendScaleRange = d3.range 0, legendHeight, legendHeight / (colorScale.getRange().length - 1)
    legendScaleRange.push legendHeight

    $scope.legendGradient = colorScale.getRange()
    $scope.legendPointerY = 0
    $scope.legendScale = d3.scale.log()
      .domain colorScale.getDomain()
      .range legendScaleRange

    getLegendPointerY = (value) -> unless value then 0 else $scope.legendScale value

    # → Events
    $scope.$on 'filters.substanceChanged', (event, eventData) ->
      $scope.substance = eventData.substance
      $scope.infoLink = eventData.infoLink
      $scope.database = eventData.database
      return

    $scope.$on 'heatmap.cellChanged', (event, eventData) ->
      $scope.countryName = eventData.countryName
      $scope.abundanceValue = eventData.abundanceValue
      $scope.abundanceValueType = eventData.abundanceValueType
      $scope.nOfSamples = eventData.nOfSamples

      $scope.legendPointerY = getLegendPointerY eventData.abundanceValue
      return

    $scope.$on 'map.countryInOut', (event, eventData) ->
      $scope.countryName = eventData.countryName
      $scope.abundanceValue = eventData.abundanceValue
      $scope.abundanceValueType = eventData.abundanceValueType
      $scope.nOfSamples = eventData.nOfSamples

      $scope.legendPointerY = getLegendPointerY eventData.abundanceValue
      return

    return
