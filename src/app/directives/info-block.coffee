app.directive 'infoBlock', ($timeout) ->
  restrict: 'E'
  replace: true
  templateUrl: 'templates/directives/info-block.html'
  scope:
    data: '='
    substanceFilters: '='
    rscFilterValues: '='
    barChart: '='
    dotChart: '='
    colorScale: '='
  link: ($scope, $element, $attrs) ->
    $scope.genesData = []

    $scope.areSubstancesShown = ->
      !$scope.rscFilterValues.substance.value

    $scope.getSubstances = ->
      _.pluck _.find($scope.substanceFilters, {'key': $scope.rscFilterValues.resistance.value}).dataset.slice(1), 'title'

    $scope.getSubstanceStyle = (substance) ->
      color: $scope.colorScale substance

    $scope.selectSubstance = (substance) ->
      $scope.rscFilterValues.substance = _.find _.find($scope.substanceFilters, {'key': $scope.rscFilterValues.resistance.value}).dataset, {'value': substance}
      return

    $scope.getSubstanceInfo = ->
      _.find $scope.data.substances, {'category_name': $scope.rscFilterValues.substance.value}

    getChunkedData = (arr, size) ->
      newArr = []
      i = 0

      while i < arr.length
        newArr.push arr.slice(i, i + size)
        i += size

      newArr

    $scope.$watch 'rscFilterValues.substance', (newValue, oldValue) ->
      unless newValue is oldValue
        if $scope.rscFilterValues.substance.value
          $scope.genesData = getChunkedData _.find($scope.data.substances, {'category_name': $scope.rscFilterValues.substance.value})['genes'], 2
        else
          $scope.genesData = []
      return

    return
