app.controller 'MainController', ($scope, $timeout, abundanceCalculator, dataLoader, tools) ->
  $scope.initializing = true

  parseData = (error, rawData) ->
    $scope.mapData = rawData[0]

    $scope.data = {}

    $scope.data.countries = rawData[1].map (d) ->
      code: parseInt d['iso_3166_code']
      continent: d.continent
      name: d.name

    substances = _.values rawData[3].categories

    $scope.data.resistances = {}

    _.uniq _.map substances, 'group'
      .sort tools.sortAlphabeticaly
      .forEach (resistance) ->
        resistanceSubstances = substances.filter (s) -> s.group is resistance
        $scope.data.resistances[resistance] = _.uniq _.map resistanceSubstances, 'category_name'
          .sort tools.sortAlphabeticaly
        return

    abundanceCalculator.init $scope.data.resistances

    # Prepare samples
    $scope.data.samples = _.values rawData[2]

    $scope.data.samples.forEach (s) ->
      # Prepare gender
      unless s['f-genders'] is 'NA'
        s['f-genders'] = _.capitalize _.head s['f-genders']

      # Prepare sample abundances
      sampleAbundances = rawData[4].filter (d) -> d['sample'] is s.names

      _.keys $scope.data.resistances
        .forEach (key) ->
          s[key] = {}

          $scope.data.resistances[key].forEach (substance) ->
            s[key][substance] = parseFloat _.find(sampleAbundances, 'groups': key, 'category': substance)['sum_abund']
            return
          return
      return

    # Studies for footer
    $scope.studies = _.uniq _.map $scope.data.samples, 'f-studies'
      .sort tools.sortAlphabeticaly
      .join ', '

    # Prepare filters data
    filteringFields = [
      'f-studies'
      'f-countries'
      'f-diagnosis'
      'f-genders'
      'f-ages'
    ]

    ageIntervals = [
      '0...9'
      '10...16'
      '17...25'
      '26...35'
      '36...50'
      '51...70'
      '71...∞'
    ]

    $scope.data.filteringFieldsValues = {}

    filteringFields.forEach (ff) ->
      if ff is 'f-ages'
        $scope.data.filteringFieldsValues[ff] = ageIntervals
      else
        $scope.data.filteringFieldsValues[ff] = _.uniq _.map $scope.data.samples, ff
          .sort tools.sortAlphabeticaly
      return

    $scope.initializing = false
    $scope.$apply()
    $timeout -> $('.loading-cover').fadeOut()
    return

  dataLoader
    .getData()
    .awaitAll parseData

  return
