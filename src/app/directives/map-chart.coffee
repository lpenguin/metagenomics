app.directive 'mapChart', ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/map-chart.html'
  scope:
    data: '='
    mapData: '='
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

    width = $element.parent().width()
    height = width / 1.5

    tooltip = d3element.select '.map-chart__tooltip'
    tooltipOffset = 20

    projection = d3.geo.mercator()
      .center [0, 45]
      .scale 75
      .rotate [-10, 0]
      .translate [width / 2, height / 2]

    path = d3.geo.path().projection projection

    svg = d3element.append 'svg'
      .classed 'map-chart__svg', true
      .attr 'width', width
      .attr 'height', height

    g = svg.append 'g'
      .classed 'main', true

    prepareMap = ->
      g.selectAll 'path'
        .data topojson.feature($scope.mapData.world, $scope.mapData.world.objects.countries).features
        .enter()
        .append 'path'
        .classed 'country', true
        .attr 'd', path
        .attr 'id', (d) -> d.id
      return

    prepareMap()

    return
