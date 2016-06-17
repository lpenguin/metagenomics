app.factory 'calculators', (tools) ->
  getAbundanceValue = (samples, resistance, substance) ->
    tools.preventNaN d3.median _.map(samples, resistance).map (r) ->
      if substance is 'overall'
        d3.median _.values r
      else
        r[substance['category_name']]

  getAbundanceValue: getAbundanceValue
