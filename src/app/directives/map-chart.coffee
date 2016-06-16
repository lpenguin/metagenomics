app.directive 'mapChart', ->
  restrict: 'E'
  replace: true
  template: '<div class="map-chart"></div>'
  scope:
    data: '='
    mapData: '='
    sampleFilters: '='
    sampleFilterValues: '='
    mapChart: '='
    heatmapChart: '='
    colorScale: '='
  link: ($scope, $element, $attrs) ->
    element = $element[0]
    d3element = d3.select element

    width = $element.width()
    height = $element.height()

    projection = d3.geo.mercator()
      .center [0, 45]
      .scale 75
      .rotate [-10, 0]
      .translate [width / 2, height / 2]

    countryPathGenerator = d3.geo.path().projection projection

    svg = d3element.append 'svg'
      .classed 'map-chart__svg', true
      .attr 'width', width
      .attr 'height', height

    g = svg.append 'g'
      .classed 'main', true

    countryPaths = []

    prepareMap = ->
      countryPaths = g.selectAll 'path'
        .data topojson.feature($scope.mapData, $scope.mapData.objects.countries).features
        .enter()
        .append 'path'
        .classed 'country', true
        .attr 'd', countryPathGenerator
      return

    paintMap = ->
      countryPaths
        .attr 'fill', '#ccc'
      return

    prepareMap()
    paintMap()

    return
