app.controller 'MainController', ($scope, $timeout, abundanceCalculator, topFiveGenerator, dataLoader, tools) ->
  $scope.initializing = true

  parseData = (error, rawData) ->
    $scope.mapData = rawData[0]

    $scope.data = {}

    $scope.data.countries = rawData[1]

    $scope.data.substances = _.values rawData[3].categories
      .map (substance) ->
        name: substance['category_name']
        resistance: substance['group']
        genes: substance['genes'].map (g) -> g['gene_name']
        infoLink: substance['info_link']

    $scope.data.resistances = {}

    _.uniq _.map $scope.data.substances, 'resistance'
      .sort tools.sortAlphabeticaly
      .forEach (resistance) ->
        resistanceSubstances = $scope.data.substances.filter (s) -> s.resistance is resistance
        $scope.data.resistances[resistance] = _.uniq _.map resistanceSubstances, 'name'
          .sort tools.sortAlphabeticaly
        return

    abundanceCalculator.init $scope.data.resistances
    topFiveGenerator.init $scope.data.substances

    # Prepare samples
    $scope.data.samples = _.values rawData[2]

    samplesSubstanceAbundances = _.groupBy rawData[4], 'sample'
    samplesGeneAbundances = _.groupBy rawData[5], 'sample'

    $scope.data.samples.forEach (sample) ->
      sample.genes = {}

      # Prepare gender
      unless sample['f-genders'] is 'NA'
        sample['f-genders'] = _.capitalize _.head sample['f-genders']

      # Prepare abundances
      sName = sample['names']
      sampleSubstanceAbundances = _.groupBy samplesSubstanceAbundances[sName], 'category'
      sampleGeneAbundances = _.groupBy samplesGeneAbundances[sName], 'category'
      _.forIn sampleGeneAbundances, (value, key) ->
        sampleGeneAbundances[key] = _.groupBy value, 'gene id'
        return

      resistances = _.keys $scope.data.resistances

      resistances.forEach (r) ->
        resistanceSubstances = $scope.data.resistances[r]
        sample[r] = {}

        resistanceSubstances.forEach (s) ->
          rec = sampleSubstanceAbundances[s]?[0]
          sample[r][s] = unless rec then 0 else parseFloat rec['sum_abund']

          substanceGenes = _.find($scope.data.substances, 'name': s)['genes']
          sample.genes[s] = {}

          substanceGenes.forEach (g) ->
            rec = sampleGeneAbundances[s]?[g]?[0]
            sample.genes[s][g] = unless rec then 0 else parseFloat rec['abund']
            return
          return
        return
      return

    # Studies for footer
    $scope.studies = _.uniq _.map $scope.data.samples, 'f-studies'
      .sort tools.sortAlphabeticaly
      .map (s) ->
        name: s
        link: _.find($scope.data.samples, 'f-studies': s)['f-studies_link']

    # Prepare filters data
    filteringFields = [
      'f-studies'
      'f-countries'
      'f-diagnosis'
      'f-genders'
      'f-ages'
    ]

    ageIntervals = [
      '0...9'
      '10...16'
      '17...25'
      '26...35'
      '36...50'
      '51...70'
      '71...∞'
    ]

    $scope.data.filteringFieldsValues = {}
    $scope.data.flags = {}

    filteringFields.forEach (ff) ->
      if ff is 'f-ages'
        $scope.data.filteringFieldsValues[ff] = ageIntervals
      else
        $scope.data.filteringFieldsValues[ff] = _.uniq _.map $scope.data.samples, ff
          .sort tools.sortAlphabeticaly

      if ff is 'f-studies' or ff is 'f-countries'
        $scope.data.filteringFieldsValues[ff].forEach (v) ->
          if ff is 'f-countries'
            $scope.data.flags[v] = [_.find($scope.data.countries, 'name': v)['code']]
          else
            ffCountries = _.groupBy($scope.data.samples, ff)[v].map (s) -> s['f-countries']
            $scope.data.flags[v] = _.uniq ffCountries
              .map (c) -> _.find($scope.data.countries, 'name': c)['code']
          return
      return

    $scope.initializing = false
    $scope.$apply()
    likely.initiate()

    $timeout ->
      $('.loading-cover').fadeOut()
    , 500
    return

  dataLoader
    .getData()
    .awaitAll parseData

  return
