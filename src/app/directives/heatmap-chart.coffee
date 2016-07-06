app.directive 'heatmapChart', ($rootScope, calculators, colors) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/heatmap-chart.html'
  scope:
    data: '='
    colorScale: '='
  link: ($scope, $element, $attrs) ->
    createCohorts = (filtersValues, checkboxesValues) ->
      return

    $scope.getCellColor = ->
      '#fff'

    $scope.substanceCellMouseover = ->
      return

    $scope.substanceCellMouseout = ->
      return

    # Events →

    # → Events
    $scope.$on 'filters.groupingChanged', (event, eventData) ->
      createCohorts eventData.studyCountryFiltersValues, eventData.checkboxesValues
      return

    return
