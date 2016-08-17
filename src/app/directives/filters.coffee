app.directive 'filters', ($rootScope) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/filters.html'
  scope:
    data: '='
  link: ($scope, $element, $attrs) ->
    # Study & country filters
    filteringFields = [
      'f-studies'
      'f-countries'
    ]

    $scope.studyCountryFilters = []
    $scope.studyCountryFiltersValues = {}

    filteringFields.forEach (ff) ->
      plural =
        title: undefined
        value: undefined

      if ff is 'f-studies'
        plural.title = 'all studies'
      else if ff is 'f-countries'
        plural.title = 'in all countries'

      dataset = $scope.data.filteringFieldsValues[ff]
        .map (u) ->
          title: u
          value: u

      dataset = [plural].concat dataset

      filter =
        key: ff
        dataset: dataset
        multi: false
        toggleFormat: -> $scope.studyCountryFiltersValues[ff].title
        disabled: false

      $scope.studyCountryFilters.push filter

      $scope.studyCountryFiltersValues[ff] = dataset[0]
      return

    # Checkboxes
    $scope.checkboxes = _.keys $scope.data.filteringFieldsValues

    $scope.checkboxesValues = {}

    $scope.checkboxes.forEach (c) ->
      $scope.checkboxesValues[c] = c is 'f-countries'
      return

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
          if $scope.studyCountryFiltersValues[key].value
            eventData[key] = $scope.studyCountryFiltersValues[key].value
          return

      $rootScope.$broadcast 'filters.filtersChanged', eventData

      onGroupingChanged()
      return
    , true

    $scope.$watch 'checkboxesValues', ->
      onGroupingChanged()
      return
    , true

    return
