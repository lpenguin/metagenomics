app.factory 'topFiveGenerator', (abundanceCalculator, tools) ->
  substances = []

  getGenesAbundancesList = (samples, sName) ->
    substance = _.find substances, 'name': sName
    substance.genes.map (gene) ->
      name: gene
      value: abundanceCalculator.getGeneAbundanceValue samples, sName, gene

  topFiveGenerator =
    init: (data) ->
      substances = data
      return

    get: (samples, abundances, resistance, substance) ->
      if substance is 'overall'
        if resistance is 'ABX determinants'
          list = _.keys abundances['ABX determinants']
            .filter (key) -> key isnt 'overall'
            .map (key) ->
              name: key
              value: abundances['ABX determinants'][key]
        else if resistance is 'ABX mutations'
          list = []
        else
          list = getGenesAbundancesList samples, resistance
      else
        list = getGenesAbundancesList samples, substance

      _.remove list, (l) -> not l.value
      list.sort (a, b) ->
        d = b.value - a.value
        return d if d
        tools.sortAlphabeticaly a.name, b.name

      _.take list, 5
