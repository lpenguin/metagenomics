app.directive 'moreFilters', ->
  restrict: 'E'
  replace: true
  templateUrl: 'templates/directives/more-filters.html'
  link: ($scope, $element, $attrs) ->
    return
