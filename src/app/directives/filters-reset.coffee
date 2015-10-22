app.directive 'filtersReset', ->
  restrict: 'E'
  replace: true
  templateUrl: 'templates/directives/filters-reset.html'
  scope:
    filters: '='
    filterValues: '='
  link: ($scope, $element, $attrs) ->
    $scope.isResetShown = ->
      _.some $scope.filters, (f) ->
        filterValue = $scope.filterValues[f.key]

        if f.multi
          filterValue.length
        else
          filterValue isnt f.dataset[0]

    $scope.resetFilters = ->
      _.keys($scope.filterValues).forEach (key) ->
        filter = _.find $scope.filters, {'key': key}
        
        $scope.filterValues[key] = if filter.multi then [] else filter.dataset[0]
        return
      return

    return
