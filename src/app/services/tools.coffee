app.factory 'tools', ->
  last = (array) ->
    return unless array and array.length
    
    array[array.length - 1]

  getChunkedData = (array, size) ->
    result = []
    i = 0

    while i < array.length
      result.push array.slice i, i + size
      i += size

    result

  goodMinus = -> '−'

  preventNaN = (value) -> if isNaN(value) then 0 else value

  last: last
  getChunkedData: getChunkedData
  goodMinus: goodMinus
  preventNaN: preventNaN
