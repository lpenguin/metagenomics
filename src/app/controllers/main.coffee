app.controller 'mainCtrl', ($scope, $timeout) ->
  tsv = d3.tsv

  $scope.isDataPrepared = false

  $scope.data =
    samples: []
    resisatnces: []
    antibiotics: []
    genders: []
    ages: []
    regions: []
    diagnosis: []

  $scope.filters = []
  $scope.filterValues = {}

  $scope.barChart = {}

  $scope.dotChart = {}

  $scope.quantityCheckbox =
    on: true

  $scope.colorScale = d3.scale.category10()

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
        'AB_category': f['AB_category']
        'sum_abund': parseFloat f['sum_abund']

      $scope.data.samples.push sample
      return

    $scope.data.resistances = ['antibiotic resistance']
    $scope.data.antibiotics = _.uniq(_.pluck(samplesAntibioticsData, 'AB_category')).sort()
    $scope.data.bacteria = []

    $scope.data.genders = _.uniq(_.pluck($scope.data.samples, 'gender')).sort()
    $scope.data.ages = [ [10, 16], [16, 25], [25, 35], [35, 50], [50, 70], [70, Infinity] ]
    $scope.data.regions = _.uniq(_.pluck($scope.data.samples, 'country')).sort()
    $scope.data.diagnosis = _.uniq(_.pluck($scope.data.samples, 'diagnosis')).sort()

    cohorts = ['gender', 'age', 'region', 'diagnosis']

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
        disabled: false
        floor: 2
      }
      {
        key: 'age'
        dataset: [ {title: 'all ages', value: undefined} ].concat($scope.data.ages.map (a) -> {title: a[0] + (if a[1] is Infinity then '+' else '–' + a[1]), value: a})
        multi: false
        toggleFormat: -> $scope.filterValues['age'].title
        disabled: false
        floor: 2
      }
      {
        key: 'region'
        dataset: [ {title: 'all regions', value: undefined} ].concat($scope.data.regions.map (d) -> {title: d, value: d})
        multi: false
        toggleFormat: -> $scope.filterValues['region'].title
        disabled: true
        floor: 2
      }
      {
        key: 'diagnosis'
        dataset: [ {title: 'all diagnosis', value: undefined} ].concat($scope.data.diagnosis.map (d) -> {title: d, value: d})
        multi: false
        toggleFormat: -> $scope.filterValues['diagnosis'].title
        disabled: false
        floor: 2
      }
      {
        key: 'cohort'
        dataset: cohorts.map (c) -> {title: 'by ' + c, value: c}
        multi: false
        toggleFormat: -> $scope.filterValues['cohort'].title
        disabled: true
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
      'region': _.find($scope.filters, {'key': 'region'}).dataset[0]
      'cohort': _.find($scope.filters, {'key': 'cohort'}).dataset[2]

    $scope.isDataPrepared = true

    $scope.$apply()

    $timeout -> $('.loading-cover').fadeOut()
    return

  queue()
  .defer tsv, '../data/samples_description.tsv'
  .defer tsv, '../data/per_sample_antibiotic_groups_stat.tsv'
  .awaitAll parseData

  return
