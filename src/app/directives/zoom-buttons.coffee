app.directive 'zoomButtons', ($rootScope) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/zoom-buttons.html'
  link: ($scope, $element, $attrs) ->
    $scope.canZoomIn = true
    $scope.canZoomOut = true

    $scope.zoomIn = ->
      $rootScope.$broadcast 'zoomButtons.zoomIn'
      return

    $scope.zoomOut = ->
      $rootScope.$broadcast 'zoomButtons.zoomOut'
      return

    $scope.$on 'mapChart.canZoomIn', (event, eventData) ->
      $scope.canZoomIn = eventData
      return

    $scope.$on 'mapChart.canZoomOut', (event, eventData) ->
      $scope.canZoomOut = eventData
      return

    return
