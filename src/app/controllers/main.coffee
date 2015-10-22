app.controller 'mainCtrl', ($scope, $timeout) ->
  $scope.isDataPrepared = false
  $scope.samples = []

  parseData = (error, rawData) ->
    if error
      console.log error

    samples = rawData[0]
    antibiotics = rawData[1]

    samples.forEach (s) ->
      sample = s
      sample['antibiotics'] = antibiotics
      .filter (a) ->
        a['sample'] is sample['names']
      .map (f) ->
        'AB_category': f['AB_category']
        'sum_abund': parseFloat f['sum_abund']

      $scope.samples.push sample
      return

    $scope.filters = [
      {
        key: 'resistance'
        dataset: [
          {
            title: 'antibiotic resistance'
            value: 'antibiotics'
          }
        ]
        multi: false
        toggleFormat: -> $scope.filterValues['resistance'].title
        disabled: true
        floor: 3
      }
      {
        key: 'antibiotics'
        dataset: [ {title: 'all antibiotics', value: undefined} ].concat((_.uniq(_.pluck(antibiotics, 'AB_category'))).map (a) -> {title: a, value: a})
        multi: false
        toggleFormat: -> $scope.filterValues['antibiotics'].title
        disabled: false
        floor: 3
      }
      {
        key: 'bacteria'
        dataset: [
          {
            title: 'all bacteria'
            value: 'all bacteria'
          }
        ]
        multi: false
        toggleFormat: -> $scope.filterValues['bacteria'].title
        disabled: true
        floor: 3
      }
      {
        key: 'gender'
        dataset: [
          {
            title: 'all genders'
            value: undefined
          }
          {
            title: 'male'
            value: 'male'
          }
          {
            title: 'female'
            value: 'female'
          }
        ]
        multi: false
        toggleFormat: -> $scope.filterValues['gender'].title
        disabled: false
        floor: 2
      }
      {
        key: 'age'
        dataset: [
          {
            title: 'all ages'
            value: undefined
          }
          {
            title: '10–16'
            value: [10, 16]
          }
          {
            title: '16–25'
            value: [16, 25]
          }
          {
            title: '25–35'
            value: [25, 35]
          }
          {
            title: '35–50'
            value: [35, 50]
          }
          {
            title: '50–70'
            value: [50, 70]
          }
          {
            title: '70+'
            value: [70, Infinity]
          }
        ]
        multi: false
        toggleFormat: -> $scope.filterValues['age'].title
        disabled: false
        floor: 2
      }
      {
        key: 'diagnosis'
        dataset: [ {title: 'all diagnosis', value: undefined} ].concat(_.uniq(_.pluck($scope.samples, 'diagnosis')).map (d) -> {title: d, value: d})
        multi: false
        toggleFormat: -> $scope.filterValues['diagnosis'].title
        disabled: false
        floor: 2
      }
      {
        key: 'country'
        dataset: [
          {
            title: 'all regions'
            value: undefined
          }
          {
            title: 'Russia'
            value: 'RUS'
          }
          {
            title: 'Europe'
            value: 'EUR'
          }
          {
            title: 'China'
            value: 'CHN'
          }
          {
            title: 'United States'
            value: 'USA'
          }
        ]
        multi: false
        toggleFormat: -> $scope.filterValues['country'].title
        disabled: true
        floor: 2
      }
      {
        key: 'cohort'
        dataset: [
          {
            title: 'by region'
            value: 'region'
          }
          {
            title: 'by diagnosis'
            value: 'diagnosis'
          }
          {
            title: 'by age'
            value: 'age'
          }
          {
            title: 'by gender'
            value: 'gender'
          }
        ]
        multi: false
        toggleFormat: -> $scope.filterValues['cohort'].title
        disabled: true
        floor: 1
      }
    ]

    $scope.filterValues =
      'resistance': _.find($scope.filters, {'key': 'resistance'}).dataset[0]
      'antibiotics': _.find($scope.filters, {'key': 'antibiotics'}).dataset[0]
      'bacteria': _.find($scope.filters, {'key': 'bacteria'}).dataset[0]
      'gender': _.find($scope.filters, {'key': 'gender'}).dataset[0]
      'age': _.find($scope.filters, {'key': 'age'}).dataset[0]
      'diagnosis': _.find($scope.filters, {'key': 'diagnosis'}).dataset[0]
      'country': _.find($scope.filters, {'key': 'country'}).dataset[0]
      'cohort': _.find($scope.filters, {'key': 'cohort'}).dataset[0]

    $scope.isDataPrepared = true

    $scope.$apply()

    $timeout -> $('.loading-cover').fadeOut()
    return

  queue()
  .defer d3.tsv, '../data/samples_description.tsv'
  .defer d3.tsv, '../data/per_sample_antibiotic_groups_stat.tsv'
  .awaitAll parseData

  return
