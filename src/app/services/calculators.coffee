app.factory 'calculators', (tools) ->
  getAbundanceValue = (samples, resistance, substance) ->
    tools.preventNaN d3.median _.map(samples, resistance).map (r) -> r[substance['category_name']]

  getAbundanceValue: getAbundanceValue
