app.directive 'zoomButtons', ($rootScope) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/zoom-buttons.html'
  link: ($scope, $element, $attrs) ->
    $scope.zoomIn = ->
      $rootScope.$broadcast 'zoomButtons.zoomIn'
      return

    $scope.zoomOut = ->
      $rootScope.$broadcast 'zoomButtons.zoomOut'
      return

    return
