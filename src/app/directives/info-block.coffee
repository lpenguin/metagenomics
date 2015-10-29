app.directive 'infoBlock', ($timeout) ->
  restrict: 'E'
  replace: true
  templateUrl: 'templates/directives/info-block.html'
  scope:
    data: '='
    filters: '='
    filterValues: '='
    barChart: '='
    dotChart: '='
    colorScale: '='
  link: ($scope, $element, $attrs) ->
    $scope.areSubstancesShown = -> !$scope.filterValues[$scope.filterValues['resistance'].value].value

    $scope.getSubstances = ->
      if $scope.filterValues['resistance'].value is 'antibiotic resistance'
        $scope.data.antibiotics.map (a) -> a

    $scope.getSubstanceStyle = (substance) ->
      color: $scope.colorScale substance

    $scope.selectSubstance = (substance) ->
      $scope.filterValues[$scope.filterValues['resistance'].value] = _.find _.find($scope.filters, {'key': $scope.filterValues['resistance'].value}).dataset, {'value': substance}
      return

    $timeout -> $scope.$broadcast 'rebuild:scrollbar'

    return
