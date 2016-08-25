app.directive 'mapChart', ($document, $rootScope, $timeout, abundanceCalculator, colorScale, samplesFilter) ->
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

    projection = d3.geo.mercator()
      .center [0, 44]
      .rotate [-11, 0]

    pathGenerator = d3.geo.path()
      .projection projection

    redrawMap = (mapTranslate, mapScale, withAnimation) ->
      projection
        .translate mapTranslate
        .scale mapScale

      unless withAnimation
        d3element.selectAll '.country'
          .attr 'd', pathGenerator
      else
        d3element.selectAll '.country'
          .transition()
          .duration 500
          .attr 'd', pathGenerator
      return

    zoom = d3.behavior.zoom()
      .on 'zoomstart', ->
        if d3.event.sourceEvent?.type is 'mousedown'
          $('body').css 'cursor': 'all-scroll'
        return
      .on 'zoom', ->
        redrawMap zoom.translate(), zoom.scale(), false
        return
      .on 'zoomend', ->
        if d3.event.sourceEvent?.type is 'mouseup'
          $('body').css 'cursor': 'default'
        return

    reattach = (element) ->
      parent = element.parentNode

      parent.removeChild element
      parent.appendChild element
      return

    svg = d3element.append 'svg'
      .classed 'map-chart__svg', true
      .attr 'height', height
      .call zoom

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

    # Prepare countries and assign Events →
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

        eventData =
          countryName: _.find($scope.data.countries, 'code': d.id)['name']
          flag: d.id
          abundanceValue: countryAbundances[d.id][resistance][substance]
          nOfSamples: nOfcountrySamples[d.id]

        $rootScope.$broadcast 'mapChart.countryInOut', eventData
        $scope.$apply()
        return
      .on 'mouseout', ->
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
    nOfcountrySamples = {}

    samplesCountries.forEach (countryName) ->
      country = _.find $scope.data.countries, 'name': countryName
      countryAbundances[country.code] = {}
      nOfcountrySamples[country.code] = undefined

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
        countrySamples = samplesFilter.getFilteredSamples filteredSamples, 'f-countries': countryName
        nOfcountrySamples[country.code] = countrySamples.length

        _.keys $scope.data.resistances
          .forEach (key) ->
            countryAbundances[country.code][key].overall = abundanceCalculator.getAbundanceValue countrySamples, key, 'overall'

            $scope.data.resistances[key].forEach (substance) ->
              countryAbundances[country.code][key][substance] = abundanceCalculator.getAbundanceValue countrySamples, key, substance
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

    # Zoom in countries
    zoomInCountries = (filteredSamples) ->
      return unless width

      returnToDefault = filteredSamples.length is $scope.data.samples.length or
      not filteredSamples.length
      newScale = undefined
      newTranslate = []

      if returnToDefault
        newScale = goodZoom
        newTranslate = [
          width / 2
          height / 2
        ]
      else
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
        oldScale = zoom.scale()
        newScale = Math.max minZoom, Math.min(maxZoom, .9 / Math.max(dx / width / oldScale, dy / height / oldScale))
        oldTranslate = zoom.translate()
        newTranslate = [
          (oldTranslate[0] - x) * newScale / oldScale + width / 2
          (oldTranslate[1] - y) * newScale / oldScale + height / 2
        ]

      zoom
        .translate newTranslate
        .scale newScale

      redrawMap zoom.translate(), zoom.scale(), true
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
      return

    $scope.$on 'zoomButtons.zoomOut', (event, eventData) ->
      return

    # Keyboard events
    $document.bind 'keydown', (event) ->
      return unless event.which is 27

      zoom
        .translate [width / 2, height /2]
        .scale goodZoom

      redrawMap zoom.translate(), zoom.scale(), true
      return

    # Resize
    $(window).on 'resize', ->
      width = $element.width()
      minZoom = width / 12
      goodZoom = width / 6
      maxZoom = width

      underlay.attr 'width', width

      zoom
        .translate [width / 2, height /2]
        .scale goodZoom
        .scaleExtent [minZoom, maxZoom]

      svg
        .attr 'width', width
        .call zoom.event
      return

    $timeout -> $(window).resize()

    return
