app.directive 'mapChart', ($document, $rootScope, abundanceCalculator, colors, colorScale, samplesFilter) ->
  restrict: 'E'
  replace: true
  template: '<div class="map-chart"></div>'
  scope:
    data: '='
    mapData: '='
  link: ($scope, $element, $attrs) ->
    # Prepare map
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

    reattach = (element) ->
      parent = element.parentNode

      parent.removeChild element
      parent.appendChild element
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

    # Draw countries and assign Events →
    g.selectAll 'path'
      .data topojson.feature($scope.mapData, $scope.mapData.objects.countries).features
      .enter()
      .append 'path'
      .classed 'country', true
      .style 'stroke', colors.countryBorder
      .on 'mouseover', (d) ->
        reattach @
        d3.select(@).style 'stroke', colors.activeCountryBorder

        country = _.find $scope.data.countries, 'code': d.id

        return unless countryAbundances[d.id]

        r = if resistance then resistance else substance
        s = if resistance then substance else 'overall'
        countryAbundanceValue = countryAbundances[d.id][r][s]

        eventData =
          countryName: country.name
          abundanceValue: countryAbundanceValue
          nOfSamples: nOfcountrySamples[d.id]

        $rootScope.$broadcast 'map.countryOver', eventData
        $scope.$apply()
        return
      .on 'mouseout', ->
        d3.select(@).style 'stroke', colors.countryBorder

        $rootScope.$broadcast 'map.countryOut'
        $scope.$apply()
        return

    svg
      .call zoom
      .call zoom.event

    # Paint map
    samplesCountries = _.uniq _.map $scope.data.samples, 'f-countries'
    resistance = undefined
    substance = undefined
    countryAbundances = {}
    nOfcountrySamples = {}

    samplesCountries.forEach (countryName) ->
      country = _.find $scope.data.countries, 'name': countryName
      countryAbundances[country.code] = {}

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
          r = if resistance then resistance else substance
          s = if resistance then substance else 'overall'
          countryAbundanceValue = countryAbundances[d.id]?[r][s]

          colorScale.getColorByValue countryAbundanceValue
      return

    # → Events
    $scope.$on 'filters.substanceChanged', (event, eventData) ->
      resistance = eventData.resistance
      substance = eventData.substance
      paintMap()
      return

    $scope.$on 'filters.filtersChanged', (event, eventData) ->
      recalcCountryAbundances samplesFilter.getFilteredSamples $scope.data.samples, eventData
      paintMap()
      return

    return
