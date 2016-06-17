app.factory 'dataLoader', ->
  json = d3.json
  tsv = d3.tsv

  getData = ->
    d3.queue()
      .defer json, '../data/map/world-110m.json'
      .defer tsv, '../data/map/countries.tsv'
      .defer json, '../data/samples-groups/sample_description.json'
      .defer json, '../data/samples-groups/group_description.json'
      .defer tsv, '../data/samples-groups/per_sample_groups_stat.tsv'

  getData: getData
