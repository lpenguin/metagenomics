app.directive 'filters', ($rootScope) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/filters.html'
  scope:
    data: '='
  link: ($scope, $element, $attrs) ->
    # Study & country multi filters
    filteringFields = [
      'f-studies'
      'f-countries'
    ]

    $scope.studyCountryFilters = []
    $scope.studyCountryFiltersValues = {}

    filteringFields.forEach (ff) ->
      dataset = $scope.data.filteringFieldsValues[ff]
        .map (u) ->
          title: u
          value: u
          flags: $scope.data.flags[u]

      filter =
        key: ff
        dataset: dataset
        plural: ff.split('-')[1]
        flagsBefore: ff is 'f-countries'

      $scope.studyCountryFilters.push filter

      $scope.studyCountryFiltersValues[ff] = []
      return

    $scope.resetFilters = ->
      _.keys $scope.studyCountryFiltersValues
        .forEach (key) ->
          $scope.studyCountryFiltersValues[key] = []
          return
      return

    # Checkboxes
    $scope.checkboxes = _.keys $scope.data.filteringFieldsValues

    $scope.checkboxesValues = {}

    $scope.checkboxes.forEach (c) ->
      $scope.checkboxesValues[c] = c is 'f-countries'
      return

    # Sort by
    $scope.sortBySelect =
      key: 'sort-by'
      dataset: [
        {title: 'number of samples', value: false}
        {title: 'resistance level', value: true}
      ]

    $scope.sortBySelectValue = $scope.sortBySelect.dataset[0]

    # Events →
    onGroupingChanged = ->
      eventData =
        studyCountryFiltersValues: $scope.studyCountryFiltersValues
        checkboxesValues: $scope.checkboxesValues

      $rootScope.$broadcast 'filters.groupingChanged', eventData
      return

    $scope.$watch 'studyCountryFiltersValues', ->
      eventData = {}

      _.keys $scope.studyCountryFiltersValues
        .forEach (key) ->
          eventData[key] = $scope.studyCountryFiltersValues[key].map (fv) -> fv.value
          return

      $scope.isResetShown = _.some _.keys(eventData), (key) -> eventData[key].length
      $rootScope.$broadcast 'filters.filtersChanged', eventData
      onGroupingChanged()
      return
    , true

    $scope.$watch 'checkboxesValues', ->
      onGroupingChanged()
      return
    , true

    $scope.$watch 'sortBySelectValue', ->
      $rootScope.$broadcast 'filters.sortingStateChanged', $scope.sortBySelectValue.value
      return

    return
