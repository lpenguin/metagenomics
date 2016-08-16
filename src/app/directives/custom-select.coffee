app.directive 'customSelect', ($document, $timeout) ->
  restrict: 'E'
  replace: true
  templateUrl: 'directives/custom-select.html'
  scope:
    key: '='
    dataset: '='
    multi: '='
    toggleFormat: '='
    disabled: '='
    selected: '='
    adjustWidth: '='
  link: ($scope, $element, $attrs) ->
    $scope.isSelectPrepared = not $scope.adjustWidth
    $scope.isListShown = false

    clickHandler = (event) ->
      return if $element.find(event.target).length

      $scope.isListShown = false
      $scope.$apply()
      $document.unbind 'click', clickHandler
      return

    $scope.toggleList = ->
      return if $scope.disabled

      $scope.isListShown = not $scope.isListShown

      if $scope.isListShown
        $document.bind 'click', clickHandler
      else
        $document.unbind 'click', clickHandler
      return

    $scope.isItemSelected = (item) ->
      if $scope.multi
        index = _.indexOf _.map($scope.selected, 'title'), item.title
        index isnt -1
      else
        $scope.selected.title is item.title

    $scope.selectItem = (item) ->
      if $scope.multi
        index = _.indexOf _.map($scope.selected, 'title'), item.title

        if index isnt -1
          $scope.selected.splice index, 1
        else
          $scope.selected.push item
      else
        $scope.selected = item
        $scope.isListShown = false
      return

    if $scope.adjustWidth
      $timeout ->
        $toggle = $element.find '.custom-select__toggle'
        $dropdown = $element.find '.custom-select__dropdown'
        toggleWidth = $toggle[0].getBoundingClientRect().width
        dropdownWidth = $dropdown[0].getBoundingClientRect().width
        dropdownHasScroll = $dropdown[0].scrollHeight > $dropdown[0].offsetHeight

        dropdownWidth += 16 if dropdownHasScroll

        $toggle.innerWidth Math.max toggleWidth, dropdownWidth
        $dropdown.width Math.max toggleWidth, dropdownWidth
        $scope.isSelectPrepared = true
        return

    $scope.$watch 'disabled', ->
      if $scope.disabled
        $scope.selected = if $scope.multi then [] else $scope.dataset[0]
      return

    return
