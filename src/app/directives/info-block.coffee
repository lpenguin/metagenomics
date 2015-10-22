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
  link: ($scope, $element, $attrs) ->
    colorScale = d3.scale.category10()

    $scope.areSubstancesShown = ->
      if $scope.filterValues['resistance'].value is 'antibiotic resistance'
        !$scope.filterValues['antibiotic resistance'].value

    $scope.getSubstances = ->
      if $scope.filterValues['resistance'].value is 'antibiotic resistance'
        $scope.data.antibiotics.map (a) -> a.charAt(0).toUpperCase() + a.slice(1)

    $scope.getSubstanceStyle = (substance) ->
      color: colorScale substance

    $scope.selectSubstance = (substance) ->
      if $scope.filterValues['resistance'].value is 'antibiotic resistance'
        $scope.filterValues['antibiotic resistance'] = _.find(_.find($scope.filters, {'key': 'antibiotic resistance'}).dataset, {'title': substance})
      return

    return
