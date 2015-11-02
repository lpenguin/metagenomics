app.controller 'mainCtrl', ($scope, $timeout) ->
  json = d3.json
  tsv = d3.tsv

  colors = [
    '#3dac65'
    '#a54cae'
    '#e4447c'
    '#3b9685'
    '#f66768'
    '#d78a2e'
    '#da4043'
    '#5a7ddc'
    '#7867a0'
    '#67a127'
    '#a78045'
    '#ee6c19'
    '#3780fa'
    '#43b85d'
    '#e43c8f'
    '#2b7a9a'
    '#b2881a'
    '#e44f65'
    '#d07f84'
    '#0fad99'
    '#6e92ba'
    '#a794ca'
    '#4ba627'
    '#e57a5a'
    '#48a161'
    '#2570c0'
    '#12a9e3'
    '#809924'
    '#9f6a8b'
    '#c47c00'
    '#fa6043'
    '#23ae77'
    '#3b8a30'
    '#80943e'
    '#d38bbc'
    '#d7731e'
    '#639df0'
    '#5c8385'
    '#c74918'
    '#519773'
    '#c38cf1'
    '#b17a4d'
    '#ef3a22'
    '#d77139'
    '#907e9d'
    '#bb8f3c'
    '#4a9aa6'
    '#8878d3'
    '#4b7f43'
    '#ff559c'
  ]

  $scope.initializing = true

  $scope.data = {}

  $scope.colorScale = d3.scale.ordinal().range colors

  $scope.resistanceFilter = {}
  $scope.substanceFilters = []
  $scope.cohortFilter = {}
  $scope.rscFilterValues = {}

  $scope.sampleFilters = []
  $scope.sampleFilterValues = {}

  $scope.barChart =
    substance: undefined

  $scope.dotChart =
    sample: undefined
    cohort: undefined

  $scope.quantityCheckbox =
    on: true

  $scope.studies = ''

  parseData = (error, rawData) ->
    if error
      console.log error

    $scope.data.samples = _.values rawData[0]
    $scope.data.substances = _.values rawData[1]['categories']

    $scope.data.samples.forEach (s) ->
      sampleAbundances = rawData[2].filter (a) -> a['sample'] is s['names']

      _.forOwn _.groupBy(sampleAbundances, 'f_groups'), (value, key) ->
        s[key] = {}
        value.forEach (v) ->
          s[key][v['AB_category']] = parseFloat v['sum_abund']
          return
        return
      return

    prepareFilters()
    return

  prepareFilters = ->
    resistances = {}
    filteringFields = [
      'f-studies'
      'f-countries'
      'f-ages'
      'f-genders'
    ]
    ageIntervals = [
      [10, 16]
      [17, 25]
      [26, 35]
      [36, 50]
      [51, 70]
      [71, Infinity]
    ]

    _.uniq(_.pluck($scope.data.substances, 'group')).forEach (resistance) ->
      resistances[resistance] = _.uniq _.pluck ($scope.data.substances.filter (s) -> s['group'] is resistance), 'category_name'
      return

    filteringFields = filteringFields.concat _.keys($scope.data.samples[0]).filter (key) ->
      key.indexOf('f-') isnt -1 and filteringFields.indexOf(key) is -1

    # Resistance filter
    $scope.resistanceFilter =
      key: 'resistance'
      dataset: _.keys(resistances).map (key) -> { title: key, value: key }
      multi: false
      toggleFormat: -> $scope.rscFilterValues.resistance.title
      disabled: false

    $scope.rscFilterValues.resistance = $scope.resistanceFilter.dataset[0]

    # Substance filters
    _.forOwn resistances, (value, key) ->
      $scope.substanceFilters.push
        key: key
        dataset: [ { title: 'all substances', value: undefined } ].concat(value.map (v) -> { title: v, value: v })
        multi: false
        toggleFormat: -> $scope.rscFilterValues.substance.title
        disabled: false
      return

    $scope.rscFilterValues.substance = $scope.substanceFilters[0].dataset[0]

    # Cohort filter
    $scope.cohortFilter =
      key: 'cohort'
      dataset: filteringFields
      .filter (ff) -> ff isnt 'f-studies'
      .map (ff) -> { title: ff.split('-')[1], value: ff }
      multi: false
      toggleFormat: -> $scope.rscFilterValues.cohort.title
      disabled: false

    $scope.rscFilterValues.cohort = $scope.cohortFilter.dataset[0]

    # Sample filters
    filteringFields.forEach (ff) ->
      dataset = []

      if ff is 'f-ages'
        dataset = ageIntervals.map (aI) -> { title: aI[0] + (if aI[1] is Infinity then '+' else '–' + aI[1]), value: aI }
      else
        dataset = _.uniq(_.pluck($scope.data.samples, ff))
        .sort (a, b) ->
          return -1 if a.toLowerCase() < b.toLowerCase()
          return 1 if a.toLowerCase() > b.toLowerCase()
          0
        .map (u) -> { title: u, value: u }

      if ff is 'f-studies'
        $scope.studies = _.pluck(dataset, 'title').join(', ')

      filter =
        key: ff
        dataset: dataset
        multi: true
        toggleFormat: ->
          toggleTitle = ''

          unless $scope.sampleFilterValues[ff].length
            toggleTitle = ff.split('-')[1]
          else if $scope.sampleFilterValues[ff].length is 1
            toggleTitle = $scope.sampleFilterValues[ff][0].title
          else
            toggleTitle = $scope.sampleFilterValues[ff][0].title

            $scope.sampleFilterValues[ff].forEach (fV, i) ->
              toggleTitle += ', ' + fV.title if i
              return

          toggleTitle
        disabled: false

      $scope.sampleFilters.push filter

      $scope.sampleFilterValues[ff] = []
      return

    $scope.initializing = false

    $scope.$apply()

    $timeout -> $('.loading-cover').fadeOut()
    return

  queue()
  .defer json, '../data/samples_description.json'
  .defer json, '../data/group_description.json'
  .defer tsv, '../data/per_sample_groups_stat.tsv'
  .awaitAll parseData

  $scope.$watch 'rscFilterValues.resistance', ->
    return unless $scope.rscFilterValues.resistance

    $scope.rscFilterValues.substance = _.find($scope.substanceFilters, {'key': $scope.rscFilterValues.resistance.value}).dataset[0]
    return

  return
