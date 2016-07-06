app.directive 'heatmapChart', ($rootScope, calculators, colors) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/heatmap-chart.html'
  scope:
    data: '='
    colorScale: '='
  link: ($scope, $element, $attrs) ->
    $scope.getCellColor = ->
      value = 0
      unless value then colors.heatmapNeutral else $scope.colorScale value

    $scope.substanceCellMouseover = ->
      return

    $scope.substanceCellMouseout = ->
      return

    return
