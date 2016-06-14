app.factory 'dataLoader', ->
  json = d3.json
  tsv = d3.tsv

  getSamplesGroupsData = ->
    d3.queue()
      .defer json, '../data/samples-groups/samples_description.json'
      .defer json, '../data/samples-groups/group_description.json'
      .defer tsv, '../data/samples-groups/per_sample_groups_stat.tsv'

  getMapData = ->
    d3.queue()
      .defer json, '../data/map/world-110m.json'
      .defer tsv, '../data/map/world-country-names.tsv'

  getSamplesGroupsData: getSamplesGroupsData
  getMapData: getMapData
