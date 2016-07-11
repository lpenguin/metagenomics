app.factory 'colorScale', (colors) ->
  scaleDomain = []
  scaleRange = []

  minPower = -12
  maxPower = -4

  scaleDomain = for num in [minPower..maxPower]
    Math.pow 10, num

  chromaScale = chroma
    .scale chroma.bezier colors.baseColors
    .mode 'lab'
    .correctLightness true

  for i in [0..scaleDomain.length - 1]
    scaleRange.push chromaScale(i / (scaleDomain.length - 1)).hex()

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
