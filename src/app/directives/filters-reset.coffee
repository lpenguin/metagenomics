app.directive 'filtersReset', ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/filters-reset.html'
  scope:
    sampleFilters: '='
    sampleFilterValues: '='
  link: ($scope, $element, $attrs) ->
    $scope.isResetShown = ->
      _.some $scope.sampleFilters, (f) ->
        filterValue = $scope.sampleFilterValues[f.key]

        if f.multi
          filterValue.length
        else
          filterValue isnt f.dataset[0]

    $scope.resetFilters = ->
      _.keys($scope.sampleFilterValues).forEach (key) ->
        filter = _.find $scope.sampleFilters, 'key': key

        $scope.sampleFilterValues[key] = if filter.multi then [] else filter.dataset[0]
        return
      return

    return
