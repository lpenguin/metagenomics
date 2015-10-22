app.directive 'barChart', ->
  restrict: 'E'
  replace: true
  templateUrl: 'templates/directives/bar-chart.html'
  scope:
    data: '='
    filterValues: '='
    quantityCheckbox: '='
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
      left: 30

    width = outerWidth - padding.left - padding.right
    height = outerHeight - padding.top - padding.bottom

    tooltip = d3element.select '.bar-chart__tooltip'
    tooltipOffset = 20

    svg = d3element.append 'svg'
    .classed 'bar-chart__svg', true
    .attr 'width', outerWidth
    .attr 'height', outerHeight

    g = svg.append 'g'
    .classed 'main', true
    .attr 'transform', 'translate(' + padding.left + ', ' + padding.top + ')'

    g.append 'rect'
    .classed 'placeholder', true
    .attr 'width', width
    .attr 'height', height
    .attr 'fill', '#adcff5'

    return
