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

    # → Events
    $scope.$on 'filters.substanceChanged', (event, eventData) ->
      $scope.substance = eventData.substance
      return

    $scope.$on 'heatmap.cellChanged', (event, eventData) ->
      $scope.abundanceValue = eventData.abundanceValue
      $scope.nOfSamples = eventData.nOfSamples
      $scope.legendPointerY = unless eventData.abundanceValue then 0 else $scope.legendScale eventData.abundanceValue
      return

    $scope.$on 'map.countryOver', (event, eventData) ->
      $scope.abundanceValue = eventData.abundanceValue
      $scope.countryName = eventData.countryName
      $scope.nOfSamples = eventData.nOfSamples
      $scope.legendPointerY = unless eventData.abundanceValue then 0 else $scope.legendScale eventData.abundanceValue
      return

    $scope.$on 'map.countryOut', ->
      $scope.abundanceValue = undefined
      $scope.countryName = undefined
      $scope.nOfSamples = 0
      $scope.legendPointerY = 0
      return

    return
