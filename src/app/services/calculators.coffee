app.factory 'calculators', (tools) ->
  calculators =
    getAbundanceValue: (samples, resistance, substance) ->
      tools.preventNaN d3.median _.map(samples, resistance).map (r) ->
        if substance is 'overall'
          d3.median _.values r
        else
          r[substance]
