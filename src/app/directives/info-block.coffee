app.directive 'infoBlock', ($rootScope) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/info-block.html'
  link: ($scope, $element, $attrs) ->
    $scope.maxPower = 11

    # → Events
    $scope.$on 'filters.substanceChanged', (event, eventData) ->
      $scope.substance = eventData
      return

    $scope.$on 'heatmap.cohortChanged', (event, eventData) ->
      $scope.abundanceValue = eventData.abundanceValue
      $scope.nOfSamples = eventData.samples.length
      return

    $scope.getLegendPointerY = ->
      0

    return
