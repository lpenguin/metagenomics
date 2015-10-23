app.directive 'infoBlock', ->
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
    $scope.areSubstancesShown = ->
      if $scope.filterValues['resistance'].value is 'antibiotic resistance'
        !$scope.filterValues['antibiotic resistance'].value

    $scope.getSubstances = ->
      if $scope.filterValues['resistance'].value is 'antibiotic resistance'
        $scope.data.antibiotics.map (a) -> a

    $scope.getSubstanceStyle = (substance) ->
      color: $scope.colorScale substance

    $scope.selectSubstance = (substance) ->
      if $scope.filterValues['resistance'].value is 'antibiotic resistance'
        $scope.filterValues['antibiotic resistance'] = _.find(_.find($scope.filters, {'key': 'antibiotic resistance'}).dataset, {'value': substance})
      return

    return
