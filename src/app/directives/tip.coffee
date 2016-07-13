app.directive 'tip', ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/tip.html'
  link: ($scope, $element, $attrs) ->
    $scope.isInfoShown = false
    
    return
