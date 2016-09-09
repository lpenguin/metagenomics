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
        groupProperties = {}

        order.forEach (o, j) ->
          cohortProperties[o] = p[j]
          groupProperties[o] = p[j] if not j
          return

        cohortSamples = samplesFilter.getFilteredSamples samples, cohortProperties
        groupSamples = samplesFilter.getFilteredSamples samples, groupProperties

        return unless cohortSamples.length
        return if cohortSamples.length is samples.length

        flag = if order[0] is 'f-countries' then _.find($scope.data.countries, 'name': p[0])['code'] else undefined
        gender = cohortProperties['f-genders']
        gender = undefined if gender is 'NA'
        name = p
        name = _.tail(p) if order[0] is 'f-countries' and p.length > 1
        name = name.filter((prop) -> prop isnt gender) if gender
        name = name.join ', '

        permutationsCohorts.push
          permutation: p
          name: name
          flag: flag
          gender: gender
          samples: cohortSamples
          abundances: getCohortAbundances cohortSamples
          nOfSamplesInGroup: groupSamples.length
        return

      permutationsCohorts.sort (a, b) ->
        return 1 if a.nOfSamplesInGroup < b.nOfSamplesInGroup
        return -1 if a.nOfSamplesInGroup > b.nOfSamplesInGroup
        return 1 if a.name > b.name
        return -1 if a.name < b.name
        0

      permutationsCohorts.forEach (p, i) ->
        previousCohort = permutationsCohorts[i - 1]
        isPushed = false

        if previousCohort
          isPushed = _.some _.dropRight(order, 1), (o, j) -> p.permutation[j] isnt previousCohort.permutation[j]

        p.isPushed = isPushed
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

        flag = if countries and not studies then _.find($scope.data.countries, 'name': countries)['code'] else undefined
        name = if studies and countries then [studies, countries].join(', ') else studies or countries

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
        $scope.cohorts = getPermutationsCohorts $scope.data.samples, groupingOrder
      return

    $scope.getCellColor = (cohort, resistance, substance) ->
      colorScale.getColorByValue cohort.abundances[resistance][substance]

    # Events →
    $scope.substanceMouseOver = (cohort, resistance, substance) ->
      if cohort
        eventData =
          countryName: _.find($scope.data.countries, 'code': cohort.flag)?['name']
          flag: cohort.flag
          abundanceValue: cohort.abundances[resistance][substance]
          abundanceValueType: if resistance.indexOf('ABX') isnt -1 and substance is 'overall' then 'Mean' else 'Median'
          nOfSamples: cohort.samples.length

        $rootScope.$broadcast 'heatmapChart.cellChanged', eventData

      $rootScope.$broadcast 'heatmapChart.substanceChanged', if substance is 'overall' then resistance else substance
      return

    $scope.substanceMouseOut = ->
      $rootScope.$broadcast 'heatmapChart.cellChanged', {}
      $rootScope.$broadcast 'heatmapChart.substanceChanged', undefined
      return

    $scope.substanceMouseClick = ->
      $rootScope.$broadcast 'heatmapChart.defaultSubstanceChanged'
      return

    # → Events
    $scope.$on 'substanceFilter.substanceChanged', (event, eventData) ->
      $scope.tempResistance = if eventData.resistance then eventData.resistance else eventData.substance
      $scope.tempSubstance = if eventData.resistance then eventData.substance else 'overall'

      return if eventData.isSubstanceChangedFromOutside

      $scope.defaultResistance = if eventData.resistance then eventData.resistance else eventData.substance
      $scope.defaultSubstance = if eventData.resistance then eventData.substance else 'overall'
      return

    $scope.$on 'filters.groupingChanged', (event, eventData) ->
      createCohorts eventData.studyCountryFiltersValues, eventData.checkboxesValues
      return

    return
