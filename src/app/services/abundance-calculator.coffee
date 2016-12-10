app.factory 'abundanceCalculator', ->
  resistances = {}

  abundanceCalculator =
    init: (data) ->
      resistances = data
      return

    getAbundanceValue: (samples, resistance, substance) ->
      unless substance is 'overall'
        d3.median _.map samples, (s) -> s[resistance][substance]
      else
        d3.mean _.map resistances[resistance], (s) -> abundanceCalculator.getAbundanceValue samples, resistance, s

    getGeneAbundanceValue: (samples, substance, gene) ->
      d3.median _.map samples, (s) -> s.genes[substance][gene]
