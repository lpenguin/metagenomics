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

    projection = d3.geo.mercator()
      .center [0, 44]
      .rotate [0, 0]

    pathGenerator = d3.geo.path()
      .projection projection

    redrawMap = (mapTranslate, mapScale) ->
      projection
        .translate mapTranslate
        .scale mapScale

      d3element.selectAll 'path'
        .attr 'd', pathGenerator
      return

    zoom = d3.behavior.zoom()
      .on 'zoomstart', ->
        if d3.event.sourceEvent?.type is 'mousedown'
          $('body').css 'cursor': 'all-scroll'
        return
      .on 'zoom', ->
        redrawMap zoom.translate(), zoom.scale()
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
      .data topojson.feature($scope.mapData, $scope.mapData.objects.countries).features
      .enter()
      .append 'path'
      .classed 'country', true
      .on 'mouseover', (d) ->
        reattach @

        return unless countryAbundances[d.id]

        eventData =
          countryName: _.find($scope.data.countries, 'code': d.id).name
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

    paintMap = ->
      d3element.selectAll '.country'
        .transition()
        .duration 250
        .style 'fill', (d) ->
          value = undefined

          if resistance and
          substance and
          countryAbundances[d.id]
            value = countryAbundances[d.id][resistance][substance]

          colorScale.getColorByValue value
      return

    # → Events
    $scope.$on 'filters.substanceChanged', (event, eventData) ->
      resistance = if eventData.resistance then eventData.resistance else eventData.substance
      substance = if eventData.resistance then eventData.substance else 'overall'
      paintMap()
      return

    $scope.$on 'filters.filtersChanged', (event, eventData) ->
      recalcCountryAbundances samplesFilter.getFilteredSamples $scope.data.samples, eventData
      paintMap()
      return

    # Keyboard events
    $document.bind 'keydown', (event) ->
      return unless event.which is 27

      zoom
        .translate [width / 2, height /2]
        .scale minZoom

      redrawMap zoom.translate(), zoom.scale()
      return

    # Resize
    $(window).on 'resize', ->
      width = $element.width()
      minZoom = width / 5
      maxZoom = minZoom * 5

      underlay.attr 'width', width

      zoom
        .translate [width / 2, height /2]
        .scale minZoom
        .scaleExtent [minZoom, maxZoom]

      svg
        .attr 'width', width
        .call zoom.event
      return

    $timeout -> $(window).resize()

    return
