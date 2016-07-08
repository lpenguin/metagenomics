app.directive 'infoBlock', ($rootScope, colors, colorScale) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/info-block.html'
  scope:
    data: '='
  link: ($scope, $element, $attrs) ->
    legendHeight = $element.find('.gradient').height()
    legendScaleRange = d3.range 0, legendHeight, legendHeight / (colors.gradient.length - 1)
    legendScaleRange.push legendHeight

    $scope.legendGradient = colors.gradient
    $scope.legendPointerY = 0
    $scope.legendScale = d3.scale.log()
      .domain colorScale.getDomain()
      .range legendScaleRange

    # → Events
    $scope.$on 'filters.substanceChanged', (event, eventData) ->
      $scope.substance = eventData
      return

    $scope.$on 'heatmap.cellChanged', (event, eventData) ->
      $scope.abundanceValue = eventData.abundanceValue
      $scope.nOfSamples = eventData.samples.length
      $scope.legendPointerY = unless eventData.abundanceValue then 0 else $scope.legendScale eventData.abundanceValue
      return

    return
