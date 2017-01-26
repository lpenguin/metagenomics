app.factory 'dataLoader', ->
  json = d3.json
  tsv = d3.tsv
  csv = d3.csv

  dataLoader =
    getData: ->
      d3.queue()
        .defer json, '../data/map/ru_world.json'
        .defer tsv, '../data/map/countries.tsv'
        .defer json, '../data/samples-groups/sample_description.json'
        .defer json, '../data/samples-groups/group_description_with_genes.json'
        .defer tsv, '../data/samples-groups/ab_table_total.tsv'
        .defer tsv, '../data/samples-groups/gene_table_total.tsv'
        .defer csv, '../data/links.csv'
