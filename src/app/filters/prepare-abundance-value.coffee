app.filter 'prepareAbundanceValue', ->
  (value, power) ->
    return '0' unless value

    multiplier = Math.pow 10, power
    value = (value * multiplier).toFixed(2)
    value + ' × 10<sup>−' + power + '</sup>'
