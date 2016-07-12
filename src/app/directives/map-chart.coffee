app.directive 'mapChart', ($document, $rootScope, abundanceCalculator, colorScale) ->
  restrict: 'E'
  replace: true
  template: '<div class="map-chart"></div>'
  scope:
    data: '='
    mapData: '='
  link: ($scope, $element, $attrs) ->
    d3element = d3.select $element[0]

    width = $element.width()
    height = $element.height()

    mapCenter = [0, 44]
    mapRotate = [0, 0]
    minZoom = 250
    maxZoom = minZoom * 5

    projection = d3.geo.mercator()
      .center mapCenter
      .rotate mapRotate

    countryPathGenerator = d3.geo.path()
      .projection projection

    redrawMap = (mapTranslate, mapScale) ->
      projection
        .translate mapTranslate
        .scale mapScale

      g.selectAll '.country'
        .attr 'd', countryPathGenerator
      return

    zoom = d3.behavior.zoom()
      .translate [width / 2, height /2]
      .scale minZoom
      .scaleExtent [minZoom, maxZoom]
      .on 'zoom', ->
        redrawMap zoom.translate(), zoom.scale()
        return

    $document.bind 'keydown', (event) ->
      return unless event.which is 27

      zoom
        .translate [width / 2, height /2]
        .scale minZoom

      redrawMap zoom.translate(), zoom.scale()
      return

    svg = d3element.append 'svg'
      .classed 'map-chart__svg', true
      .attr 'width', width
      .attr 'height', height

    svg.append 'rect'
      .attr 'width', width
      .attr 'height', height
      .classed 'underlay', true

    g = svg.append 'g'
      .classed 'main', true

    g.selectAll 'path'
      .data topojson.feature($scope.mapData, $scope.mapData.objects.countries).features
      .enter()
      .append 'path'
      .classed 'country', true
      .style 'fill', '#fff'
      .style 'stroke', '#ccc'
      .on 'mouseover', (d) ->
        $rootScope.$broadcast 'map.countryHovered', d.id
        $scope.$apply()
        return
      .on 'mouseout', ->
        $rootScope.$broadcast 'map.countryHovered', undefined
        $scope.$apply()
        return

    svg
      .call zoom
      .call zoom.event

    return
