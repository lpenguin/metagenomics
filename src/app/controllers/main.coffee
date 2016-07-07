app.controller 'MainController', ($scope, $timeout, colors, calculators, dataLoader, tools) ->
  $scope.initializing = true
  $scope.colorScale = d3.scale.linear()
    .range colors.gradient

  parseData = (error, rawData) ->
    $scope.mapData = rawData[0]

    $scope.data = {}

    $scope.data.countries = rawData[1].map (d) ->
      code: parseInt d['iso_3166_code']
      continent: d.continent
      name: d.name

    $scope.data.samples = _.values rawData[2]

    $scope.data.samples.forEach (s) ->
      sampleAbundances = rawData[4].filter (a) -> a.sample is s.names

      _.forOwn _.groupBy(sampleAbundances, 'f_groups'), (value, key) ->
        s[key] = {}
        value.forEach (v) ->
          s[key][v['AB_category']] = parseFloat v['sum_abund']
          return
        return
      return

    $scope.studies = _.uniq _.map $scope.data.samples, 'f-studies'
      .sort tools.sortAlphabeticaly
      .join ', '

    substances = _.values rawData[3].categories

    $scope.data.resistances = {}

    _.uniq _.map substances, 'group'
      .sort tools.sortAlphabeticaly
      .forEach (resistance) ->
        resistanceSubstances = substances.filter (s) -> s.group is resistance
        $scope.data.resistances[resistance] = _.uniq _.map resistanceSubstances, 'category_name'
          .sort tools.sortAlphabeticaly
        return

    filteringFields = [
      'f-studies'
      'f-countries'
      'f-diagnosis'
      'f-genders'
      'f-ages'
    ]

    ageIntervals = [
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
