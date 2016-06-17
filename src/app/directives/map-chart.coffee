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

    reattach = (element) ->
      parent = element.parentNode

      parent.removeChild element
      parent.appendChild element
      return

    prepareMap = ->
      width = $element.width()
      height = $element.height()

      projection = d3.geo.mercator()
        .center [0, 44]
        .scale 79
        .rotate [-10, 0]
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
        .style 'fill', 'none'
        .style 'stroke', '#f00'
        .style 'stroke-width', .5

      g.selectAll 'path'
        .data topojson.feature($scope.mapData, $scope.mapData.objects.countries).features
        .enter()
        .append 'path'
        .classed 'country', true
        .attr 'd', countryPathGenerator
        .style 'fill', colors.mapNeutral
        .style 'stroke', colors.mapBorders
        .style 'opacity', 1
        .on 'mouseover', (d) ->
          d3.select(@).style 'opacity', .5

          $rootScope.$broadcast 'countryHovered', d.id
          $scope.$apply()
          return
        .on 'mouseout', ->
          d3.select(@).style 'opacity', 1

          $rootScope.$broadcast 'countryHovered', undefined
          $scope.$apply()
          return
      return

    paintMap = (eventData) ->
      unless eventData
        d3element.selectAll '.country'
          .transition()
          .duration duration
          .style 'fill', colors.mapNeutral
          .style 'stroke', colors.mapBorders
      else
        d3element.selectAll '.country'
          .transition()
          .duration duration
          .style 'fill', (d) ->
            country = _.find $scope.data.countries, 'code': d.id

            if country
              value = eventData.data[country.name][eventData.resistance][eventData.substance]
              unless value then colors.mapNeutral else $scope.colorScale value
            else
              colors.mapNeutral
          .style 'stroke', (d) ->
            country = _.find $scope.data.countries, 'code': d.id

            if country
              if country.name is eventData.countryName
                reattach @
                colors.mapActiveBorders
              else
                colors.mapBorders
            else
              colors.mapBorders
      return

    prepareMap()

    $scope.$on 'substanceCellHovered', (event, eventData) ->
      paintMap eventData
      return

    return
