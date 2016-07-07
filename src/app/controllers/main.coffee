app.controller 'MainController', ($scope, $timeout, dataLoader, tools) ->
  $scope.initializing = true

  initColorScales = ->
    $scope.colorScales = {}

    _.keys $scope.data.resistances
      .forEach (key) ->
        min = Infinity
        max = -Infinity

        $scope.data.samples.forEach (sample) ->
          $scope.data.resistances[key].forEach (s) ->
            min = Math.min min, sample[key][s]
            max = Math.max max, sample[key][s]
            return
          return

        domain = [min, max]
        range = ['#7fd2d1', '#7fd2d1']

        $scope.colorScales[key] = d3.scale.linear()
          .domain domain
          .range range
        return
    return

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

    $scope.data.samples = _.values rawData[2]

    $scope.data.samples.forEach (s) ->
      sampleAbundances = rawData[4].filter (d) -> d['sample'] is s.names

      _.keys $scope.data.resistances
        .forEach (key) ->
          s[key] = {}

          $scope.data.resistances[key].forEach (substance) ->
            s[key][substance] = parseFloat _.find(sampleAbundances, 'groups': key, 'category': substance)['sum_abund']
            return
          return
      return

    $scope.studies = _.uniq _.map $scope.data.samples, 'f-studies'
      .sort tools.sortAlphabeticaly
      .join ', '

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

    initColorScales()

    $scope.initializing = false
    $scope.$apply()
    $timeout -> $('.loading-cover').fadeOut()
    return

  dataLoader
    .getData()
    .awaitAll parseData

  return
