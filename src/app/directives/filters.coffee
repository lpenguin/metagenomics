app.directive 'filters', ($rootScope, tools) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/filters.html'
  scope:
    data: '='
  link: ($scope, $element, $attrs) ->
    # Substance filter
    dataset = []

    _.keys $scope.data.resistances
      .forEach (key) ->
        dataset.push
          title: key
          value: key
          type: 'r'

        return if $scope.data.resistances[key].length < 2

        $scope.data.resistances[key].forEach (s) ->
          dataset.push
            title: s
            value: s
            type: 's'
          return
        return

    $scope.substanceFilter =
      key: 'substance'
      dataset: dataset
      multi: false
      toggleFormat: -> 'Resistomap for ' + $scope.substanceFilterValue.title
      disabled: false

    $scope.substanceFilterValue = dataset[0]
    defaultSubstanceFilterValue = dataset[0]
    isSubstanceChangedFromOutside = false

    # Study & country filters
    filteringFields = [
      'studies'
      'countries'
    ]

    $scope.studyCountryFilters = []
    $scope.studyCountryFiltersValues = {}

    filteringFields.forEach (ff) ->
      dataset = _.uniq _.map $scope.data.samples, 'f-' + ff
        .sort tools.sortAlphabeticaly
        .map (u) ->
          title: u
          value: u

      plural =
        title: ''
        value: undefined

      if ff is 'studies'
        plural.title = 'all studies'
      else if ff is 'countries'
        plural.title = 'in all countries'

      dataset = [ plural ].concat dataset

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
    $scope.checkboxes = [
      'studies'
      'countries'
      'diagnosis'
      'gender'
      'age'
    ]

    $scope.checkboxesValues = {}

    $scope.checkboxes.forEach (c) ->
      $scope.checkboxesValues[c] = true
      return

    # Watches
    $scope.$watch 'substanceFilterValue', ->
      unless isSubstanceChangedFromOutside
        defaultSubstanceFilterValue = $scope.substanceFilterValue
      else
        isSubstanceChangedFromOutside = false

      eventData =
        value: $scope.substanceFilterValue.value
        type: $scope.substanceFilterValue.type

      $rootScope.$broadcast 'filters.substanceChanged', eventData
      return

    $scope.$watch '[studyCountryFiltersValues, checkboxesValues]', ->
      eventData =
        studyCountryFiltersValues: $scope.studyCountryFiltersValues
        checkboxesValues: $scope.checkboxesValues

      $rootScope.$broadcast 'filters.groupingChanged', eventData
      return
    , true

    # Events
    $scope.$on 'heatmap.substanceChanged', (event, eventData) ->
      isSubstanceChangedFromOutside = true unless isSubstanceChangedFromOutside

      if eventData
        $scope.substanceFilterValue = _.find $scope.substanceFilter.dataset, 'value': eventData
      else
        $scope.substanceFilterValue = defaultSubstanceFilterValue
      return

    return
