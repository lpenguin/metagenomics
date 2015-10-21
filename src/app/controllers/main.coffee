app.controller 'mainCtrl', ($scope) ->
  $scope.isDataPrepared = false

  parseData = (error, rawData) ->
    if error
      console.log error

    $scope.isDataPrepared = true

    $scope.$apply()

    $('.loading-cover').fadeOut()
    return

  queue()
  .defer d3.tsv, '../data/per_country_antibiotic_groups_stat.tsv'
  .defer d3.tsv, '../data/per_sample_antibiotic_groups_stat.tsv'
  .defer d3.tsv, '../data/samples_description.tsv'
  .awaitAll parseData

  return
