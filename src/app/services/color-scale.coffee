app.factory 'colorScale', (colors) ->
  scale = d3.scale.linear()

  colorScale =
    init: (data) ->
      scale.domain data
      scale.range colors.gradient
      return

    getColorByValue: (value) ->
      unless value then colors.neutral else scale value

    getDomain: ->
      scale.domain()
