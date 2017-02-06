app.directive 'mapChart', ($document, $rootScope, $timeout, abundanceCalculator, topFiveGenerator, colorScale, samplesFilter) ->
  restrict: 'E'
  replace: true
  template: '<div class="map-chart"></div>'
  scope:
    data: '='
    mapData: '='
  link: ($scope, $element, $attrs) ->
    # Prepare map
    d3element = d3.select $element[0]

    height = $element.height()
    width = undefined
    minZoom = undefined
    goodZoom = undefined
    maxZoom = undefined

    strokeWidth = .5

    reattach = (element) ->
      parent = element.parentNode

      parent.removeChild element
      parent.appendChild element
      return

    projection = d3.geo.mercator()
      .center [0, 44]
      .rotate [-11, 0]

    pathGenerator = d3.geo.path()
      .projection projection

    zoom = d3.behavior.zoom()
      .on 'zoom', ->
        redrawMap false
        return

    redrawMap = (withAnimation) ->
      $rootScope.$broadcast 'mapChart.canZoomIn', zoom.scale() isnt maxZoom
      $rootScope.$broadcast 'mapChart.canZoomOut', zoom.scale() isnt minZoom

      projection
        .translate zoom.translate()
        .scale zoom.scale()

      unless withAnimation
        d3element.selectAll '.country'
          .attr 'd', pathGenerator
      else
        d3element.selectAll '.country'
          .transition()
          .duration 500
          .attr 'd', pathGenerator
      return

    zoomInCountries = (filteredSamples) ->
      return unless width

      returnToDefault = filteredSamples.length is $scope.data.samples.length or
      not filteredSamples.length
      newScale = goodZoom
      newTranslate = [
        width / 2
        height / 2
      ]

      unless returnToDefault
        countryCodes = _.uniq _.map filteredSamples, 'f-countries'
          .map (name) ->
            country = _.find $scope.data.countries, 'name': name
            country.code
        xMin = Infinity
        xMax = -Infinity
        yMin = Infinity
        yMax = -Infinity

        d3element.selectAll '.country'
          .filter (d) -> countryCodes.indexOf(d.id) isnt -1
          .each (d) ->
            bounds = pathGenerator.bounds d
            xMin = Math.min xMin, bounds[0][0]
            xMax = Math.max xMax, bounds[1][0]
            yMin = Math.min yMin, bounds[0][1]
            yMax = Math.max yMax, bounds[1][1]
            return

        dx = xMax - xMin
        dy = yMax - yMin
        x = (xMin + xMax) / 2
        y = (yMin + yMax) / 2
        scale0 = zoom.scale()
        newScale = Math.max minZoom, Math.min(maxZoom, .9 / Math.max(dx / width / scale0, dy / height / scale0))
        translate0 = zoom.translate()
        newTranslate = [
          (translate0[0] - x) * newScale / scale0 + width / 2
          (translate0[1] - y) * newScale / scale0 + height / 2
        ]

      zoom
        .translate newTranslate
        .scale newScale

      redrawMap true
      return

    coordinates = (point) ->
      scale = zoom.scale()
      translate = zoom.translate()
      [(point[0] - translate[0]) / scale, (point[1] - translate[1]) / scale]

    point = (coordinates) ->
      scale = zoom.scale()
      translate = zoom.translate()
      [coordinates[0] * scale + translate[0], coordinates[1] * scale + translate[1]]

    zoomFromOutside = (direction) ->
      center0 = [width / 2, height / 2]
      translate0 = zoom.translate()
      coordinates0 = coordinates center0
      zoom.scale zoom.scale() * 2 ** (if direction is 'in' then 1 else -1)
      center1 = point coordinates0
      zoom.translate [translate0[0] + center0[0] - center1[0], translate0[1] + center0[1] - center1[1]]

      redrawMap true
      return

    svg = d3element.append 'svg'
      .classed 'map-chart__svg', true
      .attr 'height', height
      .call zoom
      .on 'wheel.zoom', null
      .on 'dblclick.zoom', null

    underlay = svg.append 'rect'
      .attr 'height', height
      .classed 'underlay', true

    g = svg.append 'g'
      .classed 'main', true

    g.append 'path'
      .datum type: 'Sphere'
      .classed 'sphere', true

    countriesG = g.append 'g'
      .classed 'countries', true

    # Prepare countries
    countriesG.selectAll 'path'
      .data topojson.feature($scope.mapData, $scope.mapData.objects['ru_world']).features
      .enter()
      .append 'path'
      .classed 'country', true
      .attr 'id', (d) -> d.id
      .style 'stroke-width', (d) -> if d.id is 'RU' then strokeWidth * 2 else strokeWidth
      .on 'mouseover', (d) ->
        reattach @

        if d.id is 'RU'
          reattach d3element.select('.country.without-borders#RU').node()

        return unless countryAbundances[d.id]

        d3.select(@).classed 'hovered', true

        eventData =
          countryName: _.find($scope.data.countries, 'code': d.id)['name']
          flag: d.id
          abundanceValue: countryAbundances[d.id][resistance][substance]
          nOfSamples: countrySamples[d.id].length
          topFiveList: topFiveGenerator.get countrySamples[d.id], countryAbundances[d.id], resistance, substance

        $rootScope.$broadcast 'mapChart.countryInOut', eventData
        $scope.$apply()
        return
      .on 'mouseout', ->
        d3.select(@).classed 'hovered', false

        $rootScope.$broadcast 'mapChart.countryInOut', {}
        $scope.$apply()
        return

    # Draw Russia again (180 meridian problem)
    countriesG.append 'path'
      .datum _.find topojson.feature($scope.mapData, $scope.mapData.objects['ru_world']).features, 'id': 'RU'
      .classed 'country without-borders', true
      .attr 'id', 'RU'
      .style 'stroke-width', strokeWidth * 2

    # Paint map
    samplesCountries = _.uniq _.map $scope.data.samples, 'f-countries'
    resistance = undefined
    substance = undefined
    countryAbundances = {}
    countrySamples = {}

    samplesCountries.forEach (countryName) ->
      country = _.find $scope.data.countries, 'name': countryName
      countryAbundances[country.code] = {}
      countrySamples[country.code] = []

      _.keys $scope.data.resistances
        .forEach (key) ->
          countryAbundances[country.code][key] = 'overall': undefined

          $scope.data.resistances[key].forEach (substance) ->
            countryAbundances[country.code][key][substance] = undefined
            return
          return
      return

    recalcCountryAbundances = (filteredSamples) ->
      samplesCountries.forEach (countryName) ->
        country = _.find $scope.data.countries, 'name': countryName
        cSamples = samplesFilter.getFilteredSamples filteredSamples, 'f-countries': countryName
        countrySamples[country.code] = cSamples

        _.keys $scope.data.resistances
          .forEach (key) ->
            countryAbundances[country.code][key].overall = abundanceCalculator.getAbundanceValue cSamples, key, 'overall'

            $scope.data.resistances[key].forEach (substance) ->
              countryAbundances[country.code][key][substance] = abundanceCalculator.getAbundanceValue cSamples, key, substance
              return
            return
        return
      return

    paintMap = ->
      d3element.selectAll '.country'
        .style 'fill', (d) ->
          value = undefined

          if resistance and
          substance and
          countryAbundances[d.id]
            value = countryAbundances[d.id][resistance][substance]

          colorScale.getColorByValue value
      return

    # → Events
    $scope.$on 'substanceFilter.substanceChanged', (event, eventData) ->
      resistance = if eventData.resistance then eventData.resistance else eventData.substance
      substance = if eventData.resistance then eventData.substance else 'overall'
      paintMap()
      return

    $scope.$on 'filters.filtersChanged', (event, eventData) ->
      filteredSamples = samplesFilter.getFilteredSamples $scope.data.samples, eventData
      recalcCountryAbundances filteredSamples
      paintMap()
      zoomInCountries filteredSamples
      return

    $scope.$on 'zoomButtons.zoomIn', (event, eventData) ->
      zoomFromOutside 'in'
      return

    $scope.$on 'zoomButtons.zoomOut', (event, eventData) ->
      zoomFromOutside 'out'
      return

    # Keyboard events
    $document.bind 'keydown', (event) ->
      return unless event.which is 27

      zoom
        .translate [width / 2, height /2]
        .scale goodZoom

      redrawMap true
      $scope.$apply()
      return

    # Window resize
    $(window).on 'resize', ->
      width = $element.width()
      minZoom = width / 12
      goodZoom = width / 6
      maxZoom = width

      underlay.attr 'width', width

      zoom
        .translate [width / 2, height /2]
        .center [width / 2, height / 2]
        .scale goodZoom
        .scaleExtent [minZoom, maxZoom]

      svg
        .attr 'width', width
        .call zoom.event
      return

    $timeout -> $(window).resize()

    return
