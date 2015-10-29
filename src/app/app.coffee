appDependencies = [
  'ngRoute'
  'ngScrollbar'
]

app = angular.module 'app', appDependencies
.config [
  '$routeProvider', '$locationProvider'
  ($routeProvider, $locationProvider) ->
    $routeProvider
    .when '/',
      templateUrl: 'templates/pages/main.html'
      controller: 'mainCtrl'
    .otherwise redirectTo: '/'

    $locationProvider.html5Mode true
    return
]
