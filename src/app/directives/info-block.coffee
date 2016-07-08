app.directive 'infoBlock', ($rootScope, colors, colorScale) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/info-block.html'
  scope:
    data: '='
  link: ($scope, $element, $attrs) ->
    legendHeight = $element.find('.gradient').height()

    $scope.legendGradient = colors.gradient
    $scope.legendPointerY = 0
    $scope.legendScale = d3.scale.linear()
      .domain colorScale.getDomain()
      .range [0, legendHeight]

    # → Events
    $scope.$on 'filters.substanceChanged', (event, eventData) ->
      $scope.substance = eventData
      return

    $scope.$on 'heatmap.cellChanged', (event, eventData) ->
      $scope.abundanceValue = eventData.abundanceValue
      $scope.nOfSamples = eventData.samples.length
      $scope.legendPointerY = 0 # TODO: fix issue
      return

    return
