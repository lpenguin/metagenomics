app.directive 'dotGraphTitle', ->
  restrict: 'E'
  replace: true
  templateUrl: 'templates/directives/dot-graph-title.html'
  scope:
    filters: '='
    filterValues: '='
  link: ($scope, $element, $attrs) ->
    $scope.getGraphTitle = ->
      resistance = $scope.filterValues['resistance'].value

      if resistance is 'antibiotic resistance'
        antibiotic = $scope.filterValues['antibiotic']

        if antibiotic.value
          'Allocation of ' + antibiotic.title.charAt(0).toLowerCase() + antibiotic.title.slice(1)
        else
          'General allocation of antibiotic-resistant genes'
      else
        ''

    return
