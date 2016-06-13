app.directive 'infoBlock', (tools) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/info-block.html'
  scope:
    data: '='
    substanceFilters: '='
    rscFilterValues: '='
    barChart: '='
    dotChart: '='
    colorScale: '='
  link: ($scope, $element, $attrs) ->
    $scope.genesData = []

    $scope.areSubstancesShown = ->
      !$scope.rscFilterValues.substance.value

    $scope.getSubstances = ->
      sFilter = _.find $scope.substanceFilters, 'key': $scope.rscFilterValues.resistance.value
      _.map sFilter.dataset.slice(1), 'title'

    $scope.getSubstanceStyle = (substance) ->
      color: $scope.colorScale substance

    $scope.selectSubstance = (substance) ->
      sFilter = _.find $scope.substanceFilters, 'key': $scope.rscFilterValues.resistance.value
      $scope.rscFilterValues.substance = _.find sFilter.dataset, 'value': substance
      return

    $scope.getSubstanceInfo = ->
      _.find $scope.data.substances, 'category_name': $scope.rscFilterValues.substance.value

    $scope.$watch 'rscFilterValues.substance', (newValue, oldValue) ->
      unless newValue is oldValue
        if $scope.rscFilterValues.substance.value
          s = _.find $scope.data.substances, 'category_name': $scope.rscFilterValues.substance.value
          $scope.genesData = tools.getChunkedData s['genes'], 2
        else
          $scope.genesData = []
      return

    return
