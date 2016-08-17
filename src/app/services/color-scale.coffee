app.factory 'colorScale', (colors) ->
  scaleDomain = []
  scaleRange = []

  minPower = -12
  maxPower = -4

  scaleDomain = for num in [minPower..maxPower]
    Math.pow 10, num

  scaleRange = _.reverse colors.baseColors

  scale = d3.scale.log()
    .domain scaleDomain
    .range scaleRange

  colorScale =
    getColorByValue: (value) ->
      unless value then colors.neutral else scale value

    getDomain: ->
      scaleDomain

    getRange: ->
      scaleRange
