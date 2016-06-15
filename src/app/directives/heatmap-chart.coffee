app.directive 'heatmapChart', ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/heatmap-chart.html'
  scope:
    data: '='
    countries: '='
    sampleFilters: '='
    sampleFilterValues: '='
    mapChart: '='
    heatmapChart: '='
    mapHeatmapColorScale: '='
  link: ($scope, $element, $attrs) ->
    return
