app.directive 'overflow', ->
  restrict: 'A'
  link: ($scope, $element, $attrs) ->
    element = $element[0]

    $scope.$watch ->
      if element.offsetWidth < element.scrollWidth
        $element.addClass 'overflow'
      else
        $element.removeClass 'overflow'
      return

    return
