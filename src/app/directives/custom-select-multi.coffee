app.directive 'customSelectMulti', ($document, $timeout) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/custom-select-multi.html'
  scope:
    key: '='
    dataset: '='
    plural: '='
    selected: '='
    flagsBefore: '='
  link: ($scope, $element, $attrs) ->
    clickHandler = (event) ->
      return if $element.find(event.target).length

      $scope.isListShown = false
      $scope.$apply()
      $document.unbind 'click', clickHandler
      return

    $scope.toggleList = ->
      $scope.isListShown = not $scope.isListShown

      if $scope.isListShown
        $document.bind 'click', clickHandler
      else
        $document.unbind 'click', clickHandler
      return

    $scope.isItemSelected = (item) ->
      index = _.indexOf _.map($scope.selected, 'title'), item.title
      index isnt -1

    $scope.selectItem = (item) ->
      index = _.indexOf _.map($scope.selected, 'title'), item.title

      if index isnt -1
        $scope.selected.splice index, 1
      else
        $scope.selected.push item
      return

    $timeout ->
      $toggle = $element.find '.custom-select-multi__toggle'
      $dropdown = $element.find '.custom-select-multi__dropdown'
      toggleWidth = $toggle[0].getBoundingClientRect().width
      dropdownWidth = $dropdown[0].getBoundingClientRect().width
      dropdownHasScroll = $dropdown[0].scrollHeight > $dropdown[0].offsetHeight

      dropdownWidth += 16 if dropdownHasScroll

      $toggle.innerWidth Math.max toggleWidth, dropdownWidth
      $dropdown.width Math.max toggleWidth, dropdownWidth
      $scope.isSelectPrepared = true
      return

    return
