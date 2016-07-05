app.factory 'tools', ->
  preventNaN = (value) -> if isNaN(value) then 0 else value

  sortAlphabeticaly = (a, b) ->
    return -1 if a.toLowerCase() < b.toLowerCase()
    return 1 if a.toLowerCase() > b.toLowerCase()
    0

  preventNaN: preventNaN
  sortAlphabeticaly: sortAlphabeticaly
