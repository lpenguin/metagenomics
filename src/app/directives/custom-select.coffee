app.directive 'customSelect', ($document) ->
  restrict: 'E'
  replace: true
  templateUrl: 'templates/directives/custom-select.html'
  scope:
    key: '='
    dataset: '='
    multi: '='
    toggleFormat: '='
    valuesOfSelects: '='
  link: ($scope, $element, $attrs) ->
    $scope.isListShown = false

    $scope.toggleList = ->
      $scope.isListShown = !$scope.isListShown

      if $scope.isListShown
        $document.bind 'click', clickHandler
      else
        $document.unbind 'click', clickHandler
      return

    $scope.isItemSelected = (item) ->
      if $scope.multi
        index = _.indexOf _.pluck($scope.valuesOfSelects[$scope.key], 'title'), item.title
        index isnt -1
      else
        $scope.valuesOfSelects[$scope.key].title is item.title

    $scope.selectItem = (item) ->
      if $scope.multi
        index = _.indexOf _.pluck($scope.valuesOfSelects[$scope.key], 'title'), item.title

        if index isnt -1
          $scope.valuesOfSelects[$scope.key].splice index, 1
        else
          $scope.valuesOfSelects[$scope.key].push item
      else
        $scope.valuesOfSelects[$scope.key] = item
        $scope.isListShown = false
      return

    clickHandler = (event) ->
      return if $element.find(event.target).length
      $scope.isListShown = false
      $scope.$apply()
      $document.unbind 'click', clickHandler
      return

    return
