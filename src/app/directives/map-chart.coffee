app.directive 'mapChart', ($rootScope, colors) ->
  restrict: 'E'
  replace: true
  template: '<div class="map-chart"></div>'
  scope:
    data: '='
    mapData: '='
    colorScale: '='
  link: ($scope, $element, $attrs) ->
    d3element = d3.select $element[0]
    duration = 250

    prepareMap = ->
      width = $element.width()
      height = $element.height()

      projection = d3.geo.mercator()
        .center [0, 0]
        .scale 50
        .rotate [0, 0]
        .translate [width / 2, height / 2]

      countryPathGenerator = d3.geo.path().projection projection

      svg = d3element.append 'svg'
        .classed 'map-chart__svg', true
        .attr 'width', width
        .attr 'height', height

      g = svg.append 'g'
        .classed 'main', true

      g.append 'rect'
        .attr 'width', width
        .attr 'height', height
        .attr 'stroke', '#37c8ba'
        .attr 'stroke-width', 1
        .attr 'fill', 'none'

      g.selectAll 'path'
        .data topojson.feature($scope.mapData, $scope.mapData.objects.countries).features
        .enter()
        .append 'path'
        .classed 'country', true
        .attr 'd', countryPathGenerator
        .attr 'fill', colors.neutral
        .attr 'opacity', 1
        .on 'mouseover', (d) ->
          d3.select(@).attr 'opacity', .5

          $rootScope.$broadcast 'countryHovered', d.id
          $scope.$apply()
          return
        .on 'mouseout', ->
          d3.select(@).attr 'opacity', 1

          $rootScope.$broadcast 'countryHovered', undefined
          $scope.$apply()
          return

      g.append 'line'
        .attr 'x1', width / 2
        .attr 'y1', 0
        .attr 'x2', width / 2
        .attr 'y2', height
        .attr 'stroke', '#37c8ba'
        .attr 'stroke-width', 1

      g.append 'line'
        .attr 'x1', 0
        .attr 'y1', height / 2
        .attr 'x2', width
        .attr 'y2', height / 2
        .attr 'stroke', '#37c8ba'
        .attr 'stroke-width', 1

      center = [[0, 0]]
      
      g.selectAll 'circle'
        .data center
        .enter()
        .append 'circle'
        .attr 'cx', (d) -> projection(d)[0]
        .attr 'cy', (d) -> projection(d)[1]
        .attr 'r', 2
        .attr 'fill', '#f00'
      return

    paintMap = (eventData) ->
      unless eventData
        d3element.selectAll '.country'
          .transition()
          .duration duration
          .attr 'fill', colors.neutral
      else
        d3element.selectAll '.country'
          .transition()
          .duration duration
          .attr 'fill', (d) ->
            country = _.find $scope.data.countries, 'code': d.id

            if country
              value = eventData['data'][country['name']][eventData['resistance']][eventData['substance']]
              unless value then colors.neutral else $scope.colorScale value
            else
              colors.neutral
      return

    prepareMap()

    $scope.$on 'substanceCellHovered', (event, eventData) ->
      paintMap eventData
      return

    return
