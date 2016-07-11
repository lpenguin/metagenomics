app.filter 'prepareAbundanceValue', ->
  (value, power) ->
    return '0' unless value

    power = parseInt(value.toExponential().split('-')[1]) unless power
    multiplier = Math.pow 10, power
    value *= multiplier
    value = parseFloat value.toFixed 2

    (if value is 1 then '' else value + '×') + '10<sup>−' + power + '</sup>'
