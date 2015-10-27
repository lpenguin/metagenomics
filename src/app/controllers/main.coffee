app.controller 'mainCtrl', ($scope, $timeout) ->
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
  ]

  $scope.initializing = true

  $scope.data =
    samples: []
    resistances: []
    antibiotics: []
    genders: []
    ages: []
    countries: []
    diagnosis: []

  $scope.filters = []
  $scope.filterValues = {}

  $scope.barChart = {}

  $scope.dotChart = {}

  $scope.quantityCheckbox =
    on: true

  $scope.colorScale = d3.scale.ordinal().range colors

  $scope.filteredSamples = []

  parseData = (error, rawData) ->
    if error
      console.log error

    samplesData = rawData[0]
    samplesAntibioticsData = rawData[1]

    samplesData.forEach (sD) ->
      sample = sD
      sample['antibiotic resistance'] = samplesAntibioticsData
      .filter (sAd) ->
        sAd['sample'] is sample['names']
      .map (f) ->
        'category': f['AB_category']
        'sum_abund': parseFloat f['sum_abund']

      $scope.data.samples.push sample
      return

    $scope.data.resistances = ['antibiotic resistance']
    $scope.data.antibiotics = _.uniq(_.pluck(samplesAntibioticsData, 'AB_category')).sort()
    $scope.data.bacteria = []

    $scope.data.genders = _.uniq(_.pluck($scope.data.samples, 'gender')).sort()
    $scope.data.ages = [ [10, 16], [17, 25], [26, 35], [36, 50], [51, 70], [71, Infinity] ]
    $scope.data.countries = _.uniq(_.pluck($scope.data.samples, 'country')).sort()
    $scope.data.diagnosis = _.uniq(_.pluck($scope.data.samples, 'diagnosis')).sort()

    cohorts = ['gender', 'age', 'country', 'diagnosis']

    $scope.filters = [
      {
        key: 'resistance'
        dataset: $scope.data.resistances.map (r) -> {title: r, value: r}
        multi: false
        toggleFormat: -> $scope.filterValues['resistance'].title
        disabled: true
        floor: 3
      }
      {
        key: 'antibiotic resistance'
        dataset: [ {title: 'all antibiotics', value: undefined} ].concat($scope.data.antibiotics.map (a) -> {title: a.charAt(0).toUpperCase() + a.slice(1), value: a})
        multi: false
        toggleFormat: -> $scope.filterValues['antibiotic resistance'].title
        disabled: false
        floor: 3
      }
      {
        key: 'bacteria'
        dataset: [ {title: 'all bacteria', value: undefined} ].concat($scope.data.bacteria.map (b) -> {title: b, value: b})
        multi: false
        toggleFormat: -> $scope.filterValues['bacteria'].title
        disabled: true
        floor: 3
      }
      {
        key: 'gender'
        dataset: [ {title: 'all genders', value: undefined} ].concat($scope.data.genders.map (g) -> {title: g.charAt(0).toLowerCase() + g.slice(1), value: g})
        multi: false
        toggleFormat: -> $scope.filterValues['gender'].title
        floor: 2
      }
      {
        key: 'age'
        dataset: [ {title: 'all ages', value: undefined} ].concat($scope.data.ages.map (a) -> {title: a[0] + (if a[1] is Infinity then '+' else '–' + a[1]), value: a})
        multi: false
        toggleFormat: -> $scope.filterValues['age'].title
        floor: 2
      }
      {
        key: 'country'
        dataset: [ {title: 'all countries', value: undefined} ].concat($scope.data.countries.map (d) -> {title: d, value: d})
        multi: false
        toggleFormat: -> $scope.filterValues['country'].title
        floor: 2
      }
      {
        key: 'diagnosis'
        dataset: [ {title: 'all diagnosis', value: undefined} ].concat($scope.data.diagnosis.map (d) -> {title: d, value: d})
        multi: false
        toggleFormat: -> $scope.filterValues['diagnosis'].title
        floor: 2
      }
      {
        key: 'cohorts'
        dataset: cohorts.map (c) -> {title: c, value: c}
        multi: false
        toggleFormat: -> $scope.filterValues['cohorts'].title
        floor: 1
      }
    ]

    $scope.filterValues =
      'resistance': _.find($scope.filters, {'key': 'resistance'}).dataset[0]
      'antibiotic resistance': _.find($scope.filters, {'key': 'antibiotic resistance'}).dataset[0]
      'bacteria': _.find($scope.filters, {'key': 'bacteria'}).dataset[0]
      'gender': _.find($scope.filters, {'key': 'gender'}).dataset[0]
      'age': _.find($scope.filters, {'key': 'age'}).dataset[0]
      'diagnosis': _.find($scope.filters, {'key': 'diagnosis'}).dataset[0]
      'country': _.find($scope.filters, {'key': 'country'}).dataset[0]
      'cohorts': _.find($scope.filters, {'key': 'cohorts'}).dataset[0]

    $scope.initializing = false

    $scope.$apply()

    $timeout -> $('.loading-cover').fadeOut()
    return

  queue()
  .defer tsv, '../data/samples_description.tsv'
  .defer tsv, '../data/per_sample_antibiotic_groups_stat.tsv'
  .awaitAll parseData

  $scope.$watch 'filterValues["resistance"]', ->
    substances = []

    if $scope.filterValues["resistance"] is 'antibiotic resistance'
      substances = $scope.data.antibiotics

    $scope.colorScale.domain substances
    return

  $scope.$watch '[filterValues["gender"], filterValues["age"], filterValues["country"], filterValues["diagnosis"]]', ->
    $scope.filteredSamples = $scope.data.samples.filter (s) ->
      (if $scope.filterValues['gender'].value then s['gender'] is $scope.filterValues['gender'].value else true) and
      (if $scope.filterValues['age'].value then $scope.filterValues['age'].value[0] <= parseInt(s['age']) <= $scope.filterValues['age'].value[1] else true) and
      (if $scope.filterValues['country'].value then s['country'] is $scope.filterValues['country'].value else true) and
      (if $scope.filterValues['diagnosis'].value then s['diagnosis'] is $scope.filterValues['diagnosis'].value else true)
    return
  , true

  return
