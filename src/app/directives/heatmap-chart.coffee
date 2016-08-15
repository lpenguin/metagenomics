app.directive 'heatmapChart', ($rootScope, abundanceCalculator, colorScale, samplesFilter, tools) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/heatmap-chart.html'
  scope:
    data: '='
  link: ($scope, $element, $attrs) ->
    getCohortAbundances = (samples) ->
      cohortAbundances = {}

      _.keys $scope.data.resistances
        .forEach (key) ->
          cohortAbundances[key] = 'overall': abundanceCalculator.getAbundanceValue samples, key, 'overall'
          resistanceSubstances = $scope.data.resistances[key]

          return if resistanceSubstances.length < 2

          resistanceSubstances.forEach (s) ->
            cohortAbundances[key][s] = abundanceCalculator.getAbundanceValue samples, key, s
            return
          return

      cohortAbundances

    getPermutationsCohorts = (samples, order) ->
      permutationsCohorts = []
      permutations = tools.getPermutations order.map (o) -> $scope.data.filteringFieldsValues[o]

      permutations.forEach (p, i) ->
        cohortProperties = {}

        order.forEach (o, j) ->
          cohortProperties[o] = p[j]
          return

        cohortSamples = samplesFilter.getFilteredSamples samples, cohortProperties

        return unless cohortSamples.length
        return if cohortSamples.length is samples.length

        flag = if order[0] is 'f-countries' then p[0] else undefined
        name = (if order[0] is 'f-countries' and p.length > 1 then _.tail(p) else p).join ', '

        previousCohort = _.last permutationsCohorts
        isPushed = false

        if previousCohort
          isPushed = _.some _.dropRight(order, 1), (o, j) -> p[j] isnt previousCohort.permutation[j]

        permutationsCohorts.push
          permutation: p
          name: name
          flag: flag
          isPushed: isPushed
          samples: cohortSamples
          abundances: getCohortAbundances cohortSamples
        return

      permutationsCohorts

    createCohorts = (filtersValues, checkboxesValues) ->
      $scope.cohorts = []

      studies = filtersValues['f-studies'].value
      countries = filtersValues['f-countries'].value
      groupingOrder = _.keys checkboxesValues
        .filter (key) ->
          checkboxesValues[key] and
          (if studies then key isnt 'f-studies' else true) and
          (if countries then key isnt 'f-countries' else true)

      if studies or countries
        rootProperties = {}
        rootProperties['f-studies'] = studies if studies
        rootProperties['f-countries'] = countries if countries
        rootSamples = samplesFilter.getFilteredSamples $scope.data.samples, rootProperties

        return unless rootSamples.length

        name = if studies and countries then [studies, countries].join(', ') else studies or countries
        flag = if countries and not studies then countries else undefined

        $scope.cohorts.push
          name: name
          flag: flag
          isPushed: false
          samples: rootSamples
          abundances: getCohortAbundances rootSamples

        permutationsCohorts = getPermutationsCohorts rootSamples, groupingOrder

        return unless permutationsCohorts.length

        permutationsCohorts[0].isPushed = true
        $scope.cohorts = $scope.cohorts.concat permutationsCohorts
      else
        $scope.cohorts = getPermutationsCohorts $scope.data.samples, ['f-countries']
      return

    $scope.getCellColor = (cohort, resistance, substance) ->
      colorScale.getColorByValue cohort.abundances[resistance][substance]

    # Events →
    $scope.substanceCellMouseover = (cohort, resistance, substance) ->
      substanceSamples = cohort.samples.filter (s) ->
        if substance is 'overall'
          _.some s[resistance], (s) -> s
        else
          s[resistance][substance]

      eventData =
        abundanceValue: cohort.abundances[resistance][substance]
        nOfSamples: substanceSamples.length

      $rootScope.$broadcast 'heatmap.cellChanged', eventData
      $rootScope.$broadcast 'heatmap.substanceChanged', if substance is 'overall' then resistance else substance
      return

    $scope.substanceCellMouseout = ->
      eventData =
        abundanceValue: undefined
        nOfSamples: undefined

      $rootScope.$broadcast 'heatmap.cellChanged', eventData
      $rootScope.$broadcast 'heatmap.substanceChanged', undefined
      return

    # → Events
    $scope.$on 'filters.groupingChanged', (event, eventData) ->
      createCohorts eventData.studyCountryFiltersValues, eventData.checkboxesValues
      return

    return
