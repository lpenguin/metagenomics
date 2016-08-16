app.directive 'filters', ($rootScope) ->
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
          isHighlighted: true

        return if $scope.data.resistances[key].length < 2

        $scope.data.resistances[key].forEach (s) ->
          dataset.push
            title: s
            value: s
            parent: key
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
      $scope.checkboxesValues[c] = if c is 'f-countries' or c is 'f-diagnosis' then true else false
      return

    # Events →
    $scope.$watch 'substanceFilterValue', ->
      if isSubstanceChangedFromOutside
        isSubstanceChangedFromOutside = false
      else
        defaultSubstanceFilterValue = $scope.substanceFilterValue

      eventData =
        resistance: $scope.substanceFilterValue.parent
        substance: $scope.substanceFilterValue.value

      $rootScope.$broadcast 'filters.substanceChanged', eventData
      return

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

    # → Events
    $scope.$on 'heatmap.substanceChanged', (event, eventData) ->
      isSubstanceChangedFromOutside = true unless isSubstanceChangedFromOutside

      if eventData
        $scope.substanceFilterValue = _.find $scope.substanceFilter.dataset, 'value': eventData
      else
        $scope.substanceFilterValue = defaultSubstanceFilterValue
      return

    return
