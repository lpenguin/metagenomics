app.directive 'infoBlock', ($timeout) ->
  restrict: 'E'
  replace: true
  templateUrl: 'templates/directives/info-block.html'
  scope:
    substanceFilters: '='
    rscFilterValues: '='
    barChart: '='
    dotChart: '='
    colorScale: '='
  link: ($scope, $element, $attrs) ->
    $scope.areSubstancesShown = ->
      !$scope.rscFilterValues.substance.value

    $scope.getSubstances = ->
      _.pluck _.find($scope.substanceFilters, {'key': $scope.rscFilterValues.resistance.value}).dataset.slice(1), 'title'

    $scope.getSubstanceStyle = (substance) ->
      color: $scope.colorScale substance

    $scope.selectSubstance = (substance) ->
      $scope.rscFilterValues.substance = _.find _.find($scope.substanceFilters, {'key': $scope.rscFilterValues.resistance.value}).dataset, {'value': substance}
      return

    return
