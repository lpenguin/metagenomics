app.directive 'quantityCheckbox', ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/quantity-checkbox.html'
  scope:
    quantityCheckbox: '='
