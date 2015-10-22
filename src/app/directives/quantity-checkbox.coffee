app.directive 'quantityCheckbox', ->
  restrict: 'E'
  replace: true
  templateUrl: 'templates/directives/quantity-checkbox.html'
  scope:
    quantityCheckbox: '='
  link: ($scope, $element, $attrs) ->
    return
