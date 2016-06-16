app.directive 'filters', ($rootScope) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/filters.html'
  scope:
    data: '='
  link: ($scope, $element, $attrs) ->
    $scope.filters = []
    $scope.filterValues = {}

    filteringFields = [
      'f-studies'
      'f-ages'
      'f-genders'
      'f-diagnosis'
    ]

    ageIntervals = [
      [10, 16]
      [17, 25]
      [26, 35]
      [36, 50]
      [51, 70]
      [71, Infinity]
    ]

    prepareFilters = ->
      filteringFields.forEach (ff) ->
        dataset = []

        if ff is 'f-ages'
          dataset = ageIntervals.map (aI) ->
            title: aI[0] + (if aI[1] is Infinity then '+' else '–' + aI[1])
            value: aI
        else
          dataset = _.uniq _.map $scope.data.samples, ff
            .sort (a, b) ->
              return -1 if a.toLowerCase() < b.toLowerCase()
              return 1 if a.toLowerCase() > b.toLowerCase()
              0
            .map (u) ->
              title: u
              value: u

        filter =
          key: ff
          dataset: dataset
          multi: true
          toggleFormat: ->
            toggleTitle = ''

            unless $scope.filterValues[ff].length
              toggleTitle = ff.split('-')[1]
            else if $scope.filterValues[ff].length is 1
              toggleTitle = $scope.filterValues[ff][0].title
            else
              toggleTitle = $scope.filterValues[ff][0].title

              $scope.filterValues[ff].forEach (fV, i) ->
                toggleTitle += ', ' + fV.title if i
                return

            toggleTitle
          disabled: false

        $scope.filters.push filter

        $scope.filterValues[ff] = []
        return
      return

    filterSamples = ->
      $scope.data.samples.filter (s) ->
        _.every $scope.filters, (sF) ->
          filterValues = $scope.filterValues[sF.key]

          if filterValues.length
            _.some filterValues, (fV) ->
              if sF.key is 'f-ages'
                fV.value[0] <= s[sF.key] <= fV.value[1]
              else
                s[sF.key] is fV.value
          else
            true

    prepareFilters()

    $scope.isResetShown = ->
      _.some $scope.filters, (f) ->
        filterValue = $scope.filterValues[f.key]

        if f.multi
          filterValue.length
        else
          filterValue isnt f.dataset[0]

    $scope.resetFilters = ->
      _.keys($scope.filterValues).forEach (key) ->
        filter = _.find $scope.filters, 'key': key

        $scope.filterValues[key] = if filter.multi then [] else filter.dataset[0]
        return
      return

    $scope.$watch 'filterValues', ->
      filteredSamples = filterSamples()
      $rootScope.$broadcast 'samplesFiltered', filteredSamples
      return
    , true

    return
