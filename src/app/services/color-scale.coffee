app.factory 'colorScale', (colors) ->
  domain = [0, 100]

  scale = d3.scale.linear()
    .range colors.gradient
    .domain domain

  colorScale =
    getColor: (value) ->
      unless value then colors.neutral else scale value
