app.directive 'dotGraphTitle', ->
  restrict: 'E'
  replace: true
  templateUrl: 'templates/directives/dot-graph-title.html'
  scope:
    filters: '='
    filterValues: '='
  link: ($scope, $element, $attrs) ->
    $scope.getGraphTitle = ->
      if $scope.filterValues['resistance'].value is 'antibiotic resistance'
        antibiotic = $scope.filterValues['antibiotic resistance']

        if antibiotic.value
          'Allocation of ' + antibiotic.value
        else
          'General allocation of antibiotic-resistant genes'

    return
