app.directive 'infoBlock', ($rootScope, colorScale) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/info-block.html'
  link: ($scope, $element, $attrs) ->
    legendWidth = $element.find('.gradient').width()
    legendScaleRange = d3.range 0, legendWidth, legendWidth / (colorScale.getRange().length - 1)
    legendScaleRange.push legendWidth

    $scope.legendGradient = colorScale.getRange()
    $scope.legendPointerX = 0
    $scope.legendScale = d3.scale.log()
      .domain colorScale.getDomain()
      .range legendScaleRange

    getLegendPointerX = (value) -> unless value then 0 else $scope.legendScale value

    # → Events
    $scope.$on 'filters.substanceChanged', (event, eventData) ->
      $scope.substance = eventData.substance
      $scope.infoLink = eventData.infoLink
      $scope.database = eventData.database
      return

    $scope.$on 'heatmap.cellChanged', (event, eventData) ->
      $scope.countryName = eventData.countryName
      $scope.flag = eventData.flag
      $scope.abundanceValue = eventData.abundanceValue
      $scope.abundanceValueType = eventData.abundanceValueType
      $scope.nOfSamples = eventData.nOfSamples

      $scope.legendPointerX = getLegendPointerX eventData.abundanceValue
      return

    $scope.$on 'map.countryInOut', (event, eventData) ->
      $scope.countryName = eventData.countryName
      $scope.flag = eventData.flag
      $scope.abundanceValue = eventData.abundanceValue
      $scope.abundanceValueType = eventData.abundanceValueType
      $scope.nOfSamples = eventData.nOfSamples

      $scope.legendPointerX = getLegendPointerX eventData.abundanceValue
      return

    return
