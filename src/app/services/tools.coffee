app.factory 'tools', ->
  preventNaN = (value) -> if isNaN(value) then 0 else value

  preventNaN: preventNaN
