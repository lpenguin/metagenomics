app.directive 'tips', ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/tips.html'
  link: ($scope, $element, $attrs) ->
    $scope.isInfoShown =
      upload: false
      about: false

    return
