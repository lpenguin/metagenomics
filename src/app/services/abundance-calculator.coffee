app.factory 'abundanceCalculator', ->
  resistances = {}

  abundanceCalculator =
    init: (data) ->
      resistances = data
      return

    getAbundanceValue: (samples, resistance, substance) ->
      unless substance is 'overall'
        values = samples.map (s) -> s[resistance][substance]

        d3.median values
      else
        values = resistances[resistance].map (s) -> abundanceCalculator.getAbundanceValue samples, resistance, s

        d3.mean values
