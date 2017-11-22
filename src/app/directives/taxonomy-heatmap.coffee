app.directive 'taxonomyHeatmap', ()->
    restrict: 'E'
    templateUrl: 'directives/taxonomy-heatmap.html'
    link: ($scope, $rootScope)->
        $scope.colNameSelect =
            key: 'col-name-sel'
            dataset: [
                {title: 'Genus', value: 'genus'}
                {title: 'Family', value: 'family'}
                {title: 'Order', value: 'order'}
                {title: 'Class', value: 'class'}
            ]

        groupBy = (data, field1, field2, applyFunc)->
            nested = d3.nest()
                    .key((d) -> d[field1])
                    .key((d) -> d[field2])
                    .rollup(applyFunc)
                    .map(data)


            result = []

            _.forEach nested, (row, rowId)->
                _.forEach row, (value, colId)->
                    result.push(_.fromPairs([
                        [field1,  rowId],
                        [field2, colId],
                        ['value', value],
                    ]))
            return result

        getTableForSubstance = (samples, substance)->
            notNull = (x) -> x isnt null

            res = samples.map (sample) ->
                data = sample.genes[substance]
                if !data
                    return null
                data['id'] = sample.names
                return data
            return res.filter notNull

        filterSamples = (all_samples, sample_ids, genes)->
            sample_id_set = d3.set(sample_ids)
            genes_set = d3.set(genes)

            return all_samples.filter (s)-> 
                return sample_id_set.has(s.sampleLower) && genes_set.has(s.gene_idLower)

        changeCellInfo = (eventData) ->
            $scope.countryName = eventData.countryName
            $scope.flag = eventData.flag
            $scope.abundanceValue = eventData.abundanceValue
            $scope.abundanceValueType = eventData.abundanceValueType
            $scope.nOfSamples = eventData.nOfSamples
            $scope.topFiveList = eventData.topFiveList
            $scope.samples = (eventData.samples || []).length
            if eventData.samples
                sampleNames = eventData.samples.map (s)->s.names.toLowerCase()
                genes = eventData.topFiveList.map (g)-> g.name.toLowerCase()
                filteredSamples = filterSamples $scope.$parent.sampleGeneTaxa, sampleNames, genes
                $scope.table = groupBy(filteredSamples, $scope.rowName, $scope.colName.value, (d)-> d.length)
            else
                $scope.table = []
            return

        $scope.$on 'heatmapChart.cellChanged', (event, eventData, ignoreFrozen) ->
            changeCellInfo eventData


        $scope.colName = $scope.colNameSelect.dataset[0]
        $scope.rowName = 'gene_id'
