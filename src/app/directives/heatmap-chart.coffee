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
          cohortAbundances[key] =
            overall: abundanceCalculator.getAbundanceValue samples, key, 'overall'
          resistanceSubstances = $scope.data.resistances[key]

          return unless resistanceSubstances.length > 1

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

        flag = if cohortProperties['f-countries'] then _.find($scope.data.countries, 'name': cohortProperties['f-countries'])['code'] else undefined
        gender = cohortProperties['f-genders']
        name = p
        name = name.filter((prop) -> prop isnt cohortProperties['f-countries']) if flag and p.length > 1
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

      studies = filtersValues['f-studies'].map (fv) -> fv.value
      countries = filtersValues['f-countries'].map (fv) -> fv.value

      groupingOrder = _.keys checkboxesValues
        .filter (key) ->
          checkboxesValues[key] and
          (if studies.length then key isnt 'f-studies' else true) and
          (if countries.length then key isnt 'f-countries' else true)

      if studies.length or countries.length
        roots = []

        if studies.length and countries.length
          roots = tools.getPermutations [studies, countries]
        else if studies.length
          roots = studies
        else
          roots = countries

        roots.forEach (root, i) ->
          rootProperties = {}

          if _.isArray(root)
            rootProperties['f-studies'] = root[0]
            rootProperties['f-countries'] = root[1]
          else
            rootProperties[if studies.length then 'f-studies' else 'f-countries'] = root

          rootSamples = samplesFilter.getFilteredSamples $scope.data.samples, rootProperties

          return unless rootSamples.length

          flag = if countries.length then _.find($scope.data.countries, 'name': rootProperties['f-countries'])['code'] else undefined
          name = if _.isArray(root) then root[0] else root

          $scope.cohorts.push
            name: name
            flag: flag
            isPushed: i
            samples: rootSamples
            abundances: getCohortAbundances rootSamples

          permutationsCohorts = getPermutationsCohorts rootSamples, groupingOrder

          return unless permutationsCohorts.length

          permutationsCohorts[0].isPushed = true
          $scope.cohorts = $scope.cohorts.concat permutationsCohorts
          return
      else
        $scope.cohorts = getPermutationsCohorts $scope.data.samples, groupingOrder
      return

    $scope.getCellColor = (cohort, resistance, substance) ->
      colorScale.getColorByValue cohort.abundances[resistance][substance]

    # Events →
    prepareInfoBlockData = (cohort, resistance, substance) ->
      countryName: _.find($scope.data.countries, 'code': cohort.flag)?['name']
      flag: cohort.flag
      abundanceValue: cohort.abundances[resistance][substance]
      abundanceValueType: if resistance.indexOf('ABX') isnt -1 and substance is 'overall' then 'Mean' else 'Median'
      nOfSamples: cohort.samples.length
      genes: []

    $scope.substanceMouseOver = (cohort, resistance, substance) ->
      if cohort
        $rootScope.$broadcast 'heatmapChart.cellChanged', prepareInfoBlockData cohort, resistance, substance

      $rootScope.$broadcast 'heatmapChart.substanceChanged', if substance is 'overall' then resistance else substance
      return

    $scope.substanceMouseOut = ->
      $rootScope.$broadcast 'heatmapChart.cellChanged', {}
      $rootScope.$broadcast 'heatmapChart.substanceChanged', undefined
      return

    $scope.substanceMouseClick = (cohort, resistance, substance) ->
      if cohort
        eventData = prepareInfoBlockData cohort, resistance, substance

        if $scope.frozenCell and
        cohort is $scope.frozenCell.cohort and
        resistance is $scope.frozenCell.resistance and
        substance is $scope.frozenCell.substance
          $scope.frozenCell = {}
        else
          $scope.frozenCell = {cohort, resistance, substance, eventData}

        $rootScope.$broadcast 'heatmapChart.cellChanged', eventData, $scope.frozenCell

      $scope.frozenCell = {} unless cohort
      $rootScope.$broadcast 'heatmapChart.defaultSubstanceChanged'
      return

    # → Events
    changeDefaults = (eventData) ->
      $scope.defaultResistance = if eventData.resistance then eventData.resistance else eventData.substance
      $scope.defaultSubstance = if eventData.resistance then eventData.substance else 'overall'
      $rootScope.$broadcast 'heatmapChart.cellChanged', {}, $scope.frozenCell
      return

    $scope.$on 'substanceFilter.substanceChanged', (event, eventData) ->
      $scope.tempResistance = if eventData.resistance then eventData.resistance else eventData.substance
      $scope.tempSubstance = if eventData.resistance then eventData.substance else 'overall'

      return if eventData.isSubstanceChangedFromOutside

      $scope.frozenCell = {}
      changeDefaults eventData
      return

    $scope.$on 'substanceFilter.defaultSubstanceChanged', (event, eventData) ->
      changeDefaults eventData
      return

    $scope.$on 'filters.groupingChanged', (event, eventData) ->
      createCohorts eventData.studyCountryFiltersValues, eventData.checkboxesValues
      return

    return
