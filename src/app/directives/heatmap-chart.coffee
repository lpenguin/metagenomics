app.directive 'heatmapChart', ($rootScope, abundanceCalculator, topFiveGenerator, colorScale, samplesFilter, tools) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/heatmap-chart.html'
  scope:
    data: '='
  link: ($scope, $element, $attrs) ->
    $scope.predicate = {}
    $scope.reverseSorting = true

    studyCountryFiltersValues = undefined
    checkboxesValues = undefined

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
      nOfGroupSamples = {}
      sortingEnabled = $scope.predicate.resistance and $scope.predicate.substance

      _.uniq permutations.map (p) -> p[0]
        .forEach (u) ->
          groupProperties = {}
          groupProperties[order[0]] = u
          nOfGroupSamples[u] = samplesFilter.getFilteredSamples(samples, groupProperties).length
          return
      # lpenguin: linear time permutations
      _cohortSamples = {}
      _cohortSamples = _.groupBy samples, (s)->
        props = order.map (o)->
          if o isnt 'f-ages' then s[o] else tools.searchInIndexedIntervals($scope.data.ageIntervalsIndexed, s[o])
        props.join '::'
      
      _displayedOrders = order.filter (p)-> p isnt 'f-genders' and (order.length == 1 or p isnt 'f-countries')

      _permutationsCohorts =_.map  _cohortSamples, (cohortSamples, order_str)->
        permutation = order_str.split('::')
        cohortProperties = _.zipObject order, permutation
        displayNameTokens = _displayedOrders.map (o)-> cohortProperties[o]
        displayName = displayNameTokens.join ', '

        return {
          permutation: permutation
          name: permutation
          displayName: displayName
          flag: $scope.data.countriesCodeByName[cohortProperties['f-countries']]
          gender: cohortProperties['f-genders']
          samples: cohortSamples
          nOfSamplesInGroup: nOfGroupSamples[permutation[0]]
          abundances: getCohortAbundances cohortSamples
        }
        
      _permutationsCohorts.sort (a, b) ->
        unless sortingEnabled
          return 1 if a.nOfSamplesInGroup < b.nOfSamplesInGroup
          return -1 if a.nOfSamplesInGroup > b.nOfSamplesInGroup
          return 1 if a.name > b.name
          return -1 if a.name < b.name
          0
        else
          aa = a.abundances[$scope.predicate.resistance][$scope.predicate.substance]
          ba = b.abundances[$scope.predicate.resistance][$scope.predicate.substance]
          (if aa is ba then 0 else if aa < ba then -1 else 1) * if $scope.reverseSorting then -1 else 1
      unless sortingEnabled
        _permutationsCohorts.forEach (p, i) ->
          previousCohort = _permutationsCohorts[i - 1]
          isPushed = false

          if previousCohort
            isPushed = _.some _.dropRight(order, 1), (o, j) -> p.permutation[j] isnt previousCohort.permutation[j]

          p.isPushed = isPushed
          return
      
      return _permutationsCohorts

    createCohorts = ->
      $scope.cohorts = []
      sortingEnabled = $scope.predicate.resistance and $scope.predicate.substance

      studies = studyCountryFiltersValues['f-studies'].map (fv) -> fv.value
      countries = studyCountryFiltersValues['f-countries'].map (fv) -> fv.value

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

        rootCohorts = []

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
          name = root
          displayName = if _.isArray(root) then root[0] else root

          rootCohorts.push
            name: name
            displayName: displayName
            flag: flag
            samples: rootSamples
            abundances: getCohortAbundances rootSamples
          return

        rootCohorts
          .sort (a, b) ->
            unless sortingEnabled
              return 1 if a.samples.length < b.samples.length
              return -1 if a.samples.length > b.samples.length
              return 1 if a.name > b.name
              return -1 if a.name < b.name
              0
            else
              aa = a.abundances[$scope.predicate.resistance][$scope.predicate.substance]
              ba = b.abundances[$scope.predicate.resistance][$scope.predicate.substance]
              (if aa is ba then 0 else if aa < ba then -1 else 1) * if $scope.reverseSorting then -1 else 1
          .forEach (root, i) ->
            root.isPushed = i
            $scope.cohorts.push root

            permutationsCohorts = getPermutationsCohorts root.samples, groupingOrder

            return unless permutationsCohorts.length

            permutationsCohorts[0].isPushed = true
            $scope.cohorts = $scope.cohorts.concat permutationsCohorts
            return
      else
        # getPermutationsCohorts $scope.data.samples, groupingOrder
        $scope.cohorts = getPermutationsCohorts $scope.data.samples, groupingOrder
      return

    $scope.getCellColor = (cohort, resistance, substance) ->
      colorScale.getColorByValue cohort.abundances[resistance][substance]

    createExcelbuilderCell = (value, type, format) ->
      value: value
      metadata:
        type: type
        style: format

    $scope.downloadData = ->
      $a = $('.heatmap-chart__download a')

      workbook = ExcelBuilder.createWorkbook()
      sheet = workbook.createWorksheet name: 'Sheet'
      stylesheet = workbook.getStyleSheet()

      formats =
        header: stylesheet.createFormat
          font:
            bold: true

      fileData = []

      $scope.cohorts.forEach (c, i) ->
        cohortRow = []
        cohortRow.push createExcelbuilderCell c.name, 'string'
        cohortRow.push createExcelbuilderCell c.samples.length, 'number'

        unless i
          firstRow = []
          secondRow = []
          firstRow.push createExcelbuilderCell '', 'string'
          firstRow.push createExcelbuilderCell '', 'string'
          secondRow.push createExcelbuilderCell 'Cohort', 'string'
          secondRow.push createExcelbuilderCell 'Samples', 'string'

        _.keys $scope.data.resistances
          .forEach (key) ->
            ['overall']
              .concat (if $scope.data.resistances[key].length < 2 then [] else $scope.data.resistances[key])
              .forEach (substance, j) ->
                unless i
                  unless j
                    firstRow.push createExcelbuilderCell '', 'string'
                    firstRow.push createExcelbuilderCell key, 'string', formats.header.id
                  else
                    firstRow.push createExcelbuilderCell '', 'string'

                  unless j
                    secondRow.push createExcelbuilderCell '', 'string'
                  secondRow.push createExcelbuilderCell (if substance is 'overall' then (if $scope.data.resistances[key].length < 2 then 'median' else 'mean') else substance), 'string'

                unless j
                  cohortRow.push createExcelbuilderCell '', 'string'
                cohortRow.push createExcelbuilderCell c.abundances[key][substance], 'number'
                return
            return

        unless i
          fileData.push firstRow
          fileData.push secondRow

        if c.isPushed
          fileData.push []

        fileData.push cohortRow
        return

      # Download
      sheet.setData fileData
      workbook.addWorksheet sheet
      file = ExcelBuilder.createFile workbook

      $a
        .attr 'download', 'Heatmap.xlsx'
        .attr 'href', 'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,' + file
      return

    # Events →
    prepareCellData = (cohort, resistance, substance) ->
      countryName: _.find($scope.data.countries, 'code': cohort.flag)?['name']
      flag: cohort.flag
      abundanceValue: cohort.abundances[resistance][substance]
      abundanceValueType: if resistance.indexOf('ABX') isnt -1 and substance is 'overall' then 'Mean' else 'Median'
      nOfSamples: cohort.samples.length
      samples: cohort.samples
      resistance: resistance
      substance: substance
      topFiveList: topFiveGenerator.get cohort.samples, cohort.abundances, resistance, substance

    $scope.substanceMouseOver = (cohort, resistance, substance) ->
      $scope.tempResistance = resistance
      $scope.tempSubstance = substance
      if cohort
        $rootScope.$broadcast 'heatmapChart.cellChanged', prepareCellData cohort, resistance, substance
      $rootScope.$broadcast 'heatmapChart.tempSubstanceChanged', if substance is 'overall' then resistance else substance
      return

    $scope.substanceMouseOut = ->
      $scope.tempResistance = undefined
      $scope.tempSubstance = undefined
      $rootScope.$broadcast 'heatmapChart.cellChanged', {}
      $rootScope.$broadcast 'heatmapChart.tempSubstanceChanged', undefined
      return

    $scope.substanceMouseClick = (cohort, resistance, substance, isSortable) ->
      $scope.defaultResistance = resistance
      $scope.defaultSubstance = substance

      if cohort
        if $scope.frozenCell and
        $scope.frozenCell.cohort is cohort and
        $scope.frozenCell.resistance is resistance and
        $scope.frozenCell.substance is substance
          $scope.frozenCell = undefined
          $rootScope.$broadcast 'heatmapChart.cellIsUnfrozen'
        else
          $scope.frozenCell =
            cohort: cohort
            resistance: resistance
            substance: substance
          $rootScope.$broadcast 'heatmapChart.cellIsFrozen'
          $rootScope.$broadcast 'heatmapChart.cellChanged', prepareCellData(cohort, resistance, substance), true
      else
        $scope.frozenCell = undefined
        $rootScope.$broadcast 'heatmapChart.cellIsUnfrozen'
        $rootScope.$broadcast 'heatmapChart.cellChanged', {}

        if $scope.predicate.resistance and $scope.predicate.substance
          if isSortable
            if $scope.predicate.resistance is resistance and $scope.predicate.substance is substance
              $scope.reverseSorting = not $scope.reverseSorting
            else
              $scope.reverseSorting = true
          $scope.predicate.resistance = resistance
          $scope.predicate.substance = substance
          createCohorts()

      $rootScope.$broadcast 'heatmapChart.defaultSubstanceChanged'
      return

    # → Events
    $scope.$on 'substanceFilter.defaultSubstanceChanged', (event, eventData) ->
      $scope.frozenCell = undefined
      $scope.defaultResistance = if eventData.resistance then eventData.resistance else eventData.substance
      $scope.defaultSubstance = if eventData.resistance then eventData.substance else 'overall'
      return

    $scope.$on 'filters.groupingChanged', (event, eventData) ->
      studyCountryFiltersValues = eventData.studyCountryFiltersValues
      checkboxesValues = eventData.checkboxesValues
      createCohorts()
      return

    $scope.$on 'filters.sortingStateChanged', (event, eventData) ->
      $scope.predicate.resistance = if eventData then $scope.defaultResistance else undefined
      $scope.predicate.substance = if eventData then $scope.defaultSubstance else undefined
      createCohorts()
      return

    return
