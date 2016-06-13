app.factory 'dataLoader', ->
  json = d3.json
  tsv = d3.tsv
  
  getData = ->
    d3.queue()
      .defer json, '../data/samples_description.json'
      .defer json, '../data/group_description.json'
      .defer tsv, '../data/per_sample_groups_stat.tsv'

  getData: getData
