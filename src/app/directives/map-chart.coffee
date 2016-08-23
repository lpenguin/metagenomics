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

    projection = d3.geo.mercator()
      .center [0, 44]
      .rotate [0, 0]

    pathGenerator = d3.geo.path()
      .projection projection

    redrawMap = (mapTranslate, mapScale, withAnimation, delay, duration) ->
      projection
        .translate mapTranslate
        .scale mapScale

      unless withAnimation
        d3element.selectAll '.country'
          .attr 'd', pathGenerator
      else
        d3element.selectAll '.country'
          .transition()
          .delay delay
          .duration duration
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
      .on 'mouseover', (d) ->
        reattach @

        return unless countryAbundances[d.id]

        eventData =
          countryName: _.find($scope.data.countries, 'code': d.id).name
          flag: d.id
          abundanceValue: countryAbundances[d.id][resistance][substance]
          nOfSamples: nOfcountrySamples[d.id]

        $rootScope.$broadcast 'map.countryInOut', eventData
        $scope.$apply()
        return
      .on 'mouseout', ->
        $rootScope.$broadcast 'map.countryInOut', {}
        $scope.$apply()
        return

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

    paintMap = (delay, duration) ->
      d3element.selectAll '.country'
        .transition()
        .delay delay
        .duration duration
        .style 'fill', (d) ->
          value = undefined

          if resistance and
          substance and
          countryAbundances[d.id]
            value = countryAbundances[d.id][resistance][substance]

          colorScale.getColorByValue value
      return

    # Zoom in countries
    zoomInCountries = (filteredSamples, delay, duration) ->
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
          .sort()
        countryCode = countryCodes[0]
        scaleCoeff = if countryCodes.length > 1 then .5 else .9
        countryPath = d3element.select '#' + countryCode
        bounds = pathGenerator.bounds countryPath.datum()
        dx = bounds[1][0] - bounds[0][0]
        dy = bounds[1][1] - bounds[0][1]
        x = (bounds[0][0] + bounds[1][0]) / 2
        y = (bounds[0][1] + bounds[1][1]) / 2
        oldScale = zoom.scale()
        newScale = Math.max minZoom, Math.min(maxZoom, scaleCoeff / Math.max(dx / width / oldScale, dy / height / oldScale))
        oldTranslate = zoom.translate()
        newTranslate = [
          (oldTranslate[0] - x) * newScale / oldScale + width / 2
          (oldTranslate[1] - y) * newScale / oldScale + height / 2
        ]

      zoom
        .translate newTranslate
        .scale newScale

      redrawMap zoom.translate(), zoom.scale(), true, delay, duration
      return

    # → Events
    $scope.$on 'filters.substanceChanged', (event, eventData) ->
      resistance = if eventData.resistance then eventData.resistance else eventData.substance
      substance = if eventData.resistance then eventData.substance else 'overall'
      paintMap 0, 250
      return

    $scope.$on 'filters.filtersChanged', (event, eventData) ->
      filteredSamples = samplesFilter.getFilteredSamples $scope.data.samples, eventData
      recalcCountryAbundances filteredSamples
      paintMap 0, 250
      zoomInCountries filteredSamples, 300, 500
      return

    # Keyboard events
    $document.bind 'keydown', (event) ->
      return unless event.which is 27

      zoom
        .translate [width / 2, height /2]
        .scale goodZoom

      redrawMap zoom.translate(), zoom.scale(), true, 0, 500
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
