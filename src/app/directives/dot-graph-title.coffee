app.directive 'dotGraphTitle', ->
  restrict: 'E'
  replace: true
  template: '<div>{{getGraphTitle()}}</div>'
  scope:
    rscFilterValues: '='
  link: ($scope, $element, $attrs) ->
    $scope.getGraphTitle = ->
      if $scope.rscFilterValues.substance.value
        'Allocation of ' + $scope.rscFilterValues.substance.title
      else
        'Allocation of genes with ' + $scope.rscFilterValues.resistance.title

    return
