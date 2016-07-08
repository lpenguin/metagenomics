app.factory 'colorScale', (colors) ->
  min = 1e-12
  max = 1e-4
  values = d3.range min, max, (max - min) / (colors.gradient.length - 1)
  values.push max

  scale = d3.scale.log()
    .domain [1e-12, 1e-11, 1e-10, 1e-9, 1e-8, 1e-7, 1e-6, 1e-5, 1e-4]
    .range colors.gradient

  colorScale =
    getColorByValue: (value) ->
      unless value then colors.neutral else scale value

    getDomain: ->
      scale.domain()
