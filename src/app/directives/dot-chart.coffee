app.directive 'dotChart', ->
  restrict: 'E'
  replace: true
  templateUrl: 'templates/directives/dot-chart.html'
  scope:
    data: '='
    filterValues: '='
    barChart: '='
    dotChart: '='
    colorScale: '='
  link: ($scope, $element, $attrs) ->
    element = $element[0]
    d3element = d3.select element

    outerWidth = $element.parent().width()
    outerHeight = outerWidth * .9
    padding =
      top: 20
      right: 30
      bottom: 30
      left: 50

    width = outerWidth - padding.left - padding.right
    height = outerHeight - padding.top - padding.bottom

    tooltip = d3element.select '.dot-chart__tooltip'
    tooltipOffset = 20

    svg = d3element.append 'svg'
    .classed 'dot-chart__svg', true
    .attr 'width', outerWidth
    .attr 'height', outerHeight

    g = svg.append 'g'
    .classed 'main', true
    .attr 'transform', 'translate(' + padding.left + ', ' + padding.top + ')'

    g.append 'rect'
    .classed 'placeholder', true
    .attr 'width', width
    .attr 'height', height
    .attr 'fill', '#e6e6e6'

    return
