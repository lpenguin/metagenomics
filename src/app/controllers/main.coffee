app.controller 'mainCtrl', ($scope) ->
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

    console.log $scope.samples

    $scope.isDataPrepared = true

    $scope.$apply()

    $('.loading-cover').fadeOut()
    return

  queue()
  .defer d3.tsv, '../data/samples_description.tsv'
  .defer d3.tsv, '../data/per_sample_antibiotic_groups_stat.tsv'
  .awaitAll parseData

  return
