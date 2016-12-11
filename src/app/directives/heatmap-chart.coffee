app.directive 'heatmapChart', ($rootScope, abundanceCalculator, topFiveGenerator, colorScale, samplesFilter, tools) ->
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

      nOfGroupSamples = {}

      _.uniq permutations.map (p) -> p[0]
        .forEach (u) ->
          groupProperties = {}
          groupProperties[order[0]] = u
          nOfGroupSamples[u] = samplesFilter.getFilteredSamples(samples, groupProperties).length
          return

      permutations.forEach (p, i) ->
        cohortProperties = {}

        order.forEach (o, j) ->
          cohortProperties[o] = p[j]
          return

        cohortSamples = samplesFilter.getFilteredSamples samples, cohortProperties

        return unless cohortSamples.length
        return if cohortSamples.length is samples.length

        flag = if cohortProperties['f-countries'] then _.find($scope.data.countries, 'name': cohortProperties['f-countries'])['code'] else undefined
        gender = cohortProperties['f-genders']
        name = p
        displayName = p
        displayName = displayName.filter((prop) -> prop isnt cohortProperties['f-countries']) if flag and p.length > 1
        displayName = displayName.filter((prop) -> prop isnt gender) if gender
        displayName = displayName.join ', '

        permutationsCohorts.push
          permutation: p
          name: name
          displayName: displayName
          flag: flag
          gender: gender
          samples: cohortSamples
          abundances: getCohortAbundances cohortSamples
          nOfSamplesInGroup: nOfGroupSamples[p[0]]
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

        roots
          .sort tools.sortAlphabetically
          .forEach (root, i) ->
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

            $scope.cohorts.push
              name: name
              displayName: displayName
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
                  secondRow.push createExcelbuilderCell '', 'string'
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

    $scope.substanceMouseClick = (cohort, resistance, substance) ->
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

      $rootScope.$broadcast 'heatmapChart.defaultSubstanceChanged'
      return

    # → Events
    $scope.$on 'substanceFilter.defaultSubstanceChanged', (event, eventData) ->
      $scope.frozenCell = undefined
      $scope.defaultResistance = if eventData.resistance then eventData.resistance else eventData.substance
      $scope.defaultSubstance = if eventData.resistance then eventData.substance else 'overall'
      return

    $scope.$on 'filters.groupingChanged', (event, eventData) ->
      createCohorts eventData.studyCountryFiltersValues, eventData.checkboxesValues
      return

    return
