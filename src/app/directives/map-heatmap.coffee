app.directive 'mapHeatmap', ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/map-heatmap.html'
  scope:
    data: '='
    mapData: '='
    substanceFilters: '='
    sampleFilters: '='
    rscFilterValues: '='
    sampleFilterValues: '='
    resistanceColorScale: '='
  link: ($scope, $element, $attrs) ->
    element = $element[0]
    mapContainer = $element.find '.map-heatmap__map'
    d3mapContainer = d3.select mapContainer[0]

    mapWidth = $element.parent().width()
    mapHeight = mapWidth / 1.5

    projection = d3.geo.mercator()
      .center [0, 45]
      .scale 75
      .rotate [-10, 0]
      .translate [mapWidth / 2, mapHeight / 2]

    path = d3.geo.path().projection projection

    svg = d3mapContainer.append 'svg'
      .attr 'width', mapWidth
      .attr 'height', mapHeight

    g = svg.append 'g'
      .classed 'main', true

    countryPaths = []

    prepareMap = ->
      countryPaths = g.selectAll 'path'
        .data topojson.feature($scope.mapData, $scope.mapData.objects.countries).features
        .enter()
        .append 'path'
        .classed 'country', true
        .attr 'd', path
        .attr 'id', (d) -> d.id
      return

    paintMap = ->
      countryPaths
        .filter (c) -> c.id is 156
        .attr 'fill', '#f00'
      return

    prepareMap()
    paintMap()

    return
