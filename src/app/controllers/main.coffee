app.controller 'MainController', ($scope, $timeout, abundanceCalculator, dataLoader, tools) ->
  $scope.initializing = true

  parseData = (error, rawData) ->
    $scope.mapData = rawData[0]

    $scope.data = {}

    $scope.data.countries = rawData[1].map (d) ->
      name: d.name
      code: d.code

    $scope.data.substances = _.values rawData[3].categories
      .map (substance) ->
        name: substance['category_name']
        resistance: substance['group']
        infoLink: substance['info_link']

    $scope.data.resistances = {}

    _.uniq _.map $scope.data.substances, 'resistance'
      .sort tools.sortAlphabeticaly
      .forEach (resistance) ->
        resistanceSubstances = $scope.data.substances.filter (s) -> s.resistance is resistance
        $scope.data.resistances[resistance] = _.uniq _.map resistanceSubstances, 'name'
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
      .map (s) ->
        name: s
        link: _.find($scope.data.samples, 'f-studies': s)['f-studies_link']

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
    $scope.data.flags = {}

    filteringFields.forEach (ff) ->
      if ff is 'f-ages'
        $scope.data.filteringFieldsValues[ff] = ageIntervals
      else
        $scope.data.filteringFieldsValues[ff] = _.uniq _.map $scope.data.samples, ff
          .sort tools.sortAlphabeticaly

      if ff is 'f-studies' or ff is 'f-countries'
        $scope.data.filteringFieldsValues[ff].forEach (v) ->
          ffCountries = $scope.data.samples
            .filter (s) -> s[ff] is v
            .map (s) -> s['f-countries']
          $scope.data.flags[v] = _.uniq ffCountries
            .map (c) -> _.find($scope.data.countries, 'name': c)['code']
          return
      return

    $scope.initializing = false
    $scope.$apply()
    likely.initiate()
    $timeout ->
      $('.loading-cover').fadeOut()
    , 500
    return

  dataLoader
    .getData()
    .awaitAll parseData

  return
