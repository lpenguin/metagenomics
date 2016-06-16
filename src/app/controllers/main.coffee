app.controller 'MainController', ($scope, $timeout, colors, calculators, dataLoader) ->
  $scope.initializing = true

  prepareColorScale = ->
    max = -Infinity

    $scope.colorScale = d3.scale.linear()
      .range colors.gradient

    $scope.data.countries.forEach (c) ->
      _.keys($scope.data.resistances).forEach (r) ->
        $scope.data.substances.forEach (s) ->
          cSamples = $scope.data.samples.filter (s) -> s['f-countries'] is c['name']
          abundanceValue = calculators.getAbundanceValue cSamples, r, s
          max = Math.max max, abundanceValue
          return
        return
      return

    $scope.colorScale = d3.scale.linear()
      .domain [0, max]
      .range colors.gradient
    return

  parseData = (error, rawData) ->
    $scope.mapData = rawData[0]

    $scope.data = {}

    $scope.data.countries = rawData[1].map (d) ->
      code: parseInt d['iso_3166_code']
      continent: d['continent']
      name: d['name']

    $scope.data.samples = _.values rawData[2]
    $scope.data.substances = _.values rawData[3]['categories']

    $scope.studies = _.uniq(_.map($scope.data.samples, 'f-studies')).sort().join ', '

    $scope.data.samples.forEach (s) ->
      sampleAbundances = rawData[4].filter (a) -> a['sample'] is s['names']

      _.forOwn _.groupBy(sampleAbundances, 'f_groups'), (value, key) ->
        s[key] = {}
        value.forEach (v) ->
          s[key][v['AB_category']] = parseFloat v['sum_abund']
          return
        return
      return

    $scope.data.resistances = {}

    _.uniq _.map $scope.data.substances, 'group'
      .forEach (resistance) ->
        substances = $scope.data.substances.filter (s) -> s['group'] is resistance
        $scope.data.resistances[resistance] = _.uniq _.map substances, 'category_name'
        return

    prepareColorScale()

    $scope.initializing = false
    $scope.$apply()
    $timeout -> $('.loading-cover').fadeOut()
    return

  dataLoader
    .getData()
    .awaitAll parseData

  return
