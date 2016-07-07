app.directive 'infoBlock', ($rootScope) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/info-block.html'
  link: ($scope, $element, $attrs) ->
    # → Events
    $scope.$on 'filters.substanceChanged', (event, eventData) ->
      $scope.substance = eventData
      return

    $scope.$on 'heatmap.cohortChanged', (event, eventData) ->
      $scope.abundanceValue = eventData.abundanceValue
      $scope.nOfSamples = eventData.nOfSamples
      return

    return
