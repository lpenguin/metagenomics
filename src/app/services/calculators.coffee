app.factory 'calculators', ->
  calculators =
    getAbundanceValue: (samples, resistance, substance) ->
      unless substance is 'overall'
        values = samples.map (s) -> s[resistance][substance]

        d3.median values
      else
        substances = _.keys samples[0][resistance]
        values = substances.map (s) -> calculators.getAbundanceValue samples, resistance, s

        d3.mean values
