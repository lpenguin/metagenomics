app.directive 'heatmapChart', ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/heatmap-chart.html'
  scope:
    data: '='
    substanceFilters: '='
    sampleFilters: '='
    rscFilterValues: '='
    sampleFilterValues: '='
    mapChart: '='
    heatmapChart: '='
    mapHeatmapColorScale: '='
  link: ($scope, $element, $attrs) ->
    element = $element[0]
    d3element = d3.select element

    outerWidth = $element.parent().width()
    outerHeight = 100

    padding =
      top: 20
      right: 30
      bottom: 30
      left: 30

    width = outerWidth - padding.left - padding.right
    height = outerHeight - padding.top - padding.bottom

    tooltip = d3element.select '.heatmap__tooltip'
    tooltipOffset = 20

    svg = d3element.append 'svg'
      .classed 'heatmap__svg', true
      .attr 'width', outerWidth
      .attr 'height', outerHeight

    g = svg.append 'g'
      .classed 'main', true
      .attr 'transform', 'translate(' + padding.left + ', ' + padding.top + ')'

    return
