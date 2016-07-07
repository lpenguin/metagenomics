app.factory 'tools', ->
  tools =
    sortAlphabeticaly: (a, b) ->
      return -1 if a.toLowerCase() < b.toLowerCase()
      return 1 if a.toLowerCase() > b.toLowerCase()
      0

    getPermutations: (array) ->
      unless array.length
        []
      else if array.length is 1
        array[0].map (a) -> [a]
      else
        result = []
        allCasesOfRest = tools.getPermutations array.slice 1

        j = 0
        while j < array[0].length
          i = 0
          while i < allCasesOfRest.length
            result.push [array[0][j]].concat allCasesOfRest[i]
            i++
          j++

        result
