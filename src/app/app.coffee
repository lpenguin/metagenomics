appDependencies = [
  'ngRoute'
]

app = angular
  .module 'app', appDependencies
  .config [
    '$routeProvider', '$locationProvider'
    ($routeProvider, $locationProvider) ->
      $routeProvider
        .when '/',
          controller: 'MainController as main'
          templateUrl: 'pages/main.html'
        .otherwise redirectTo: '/'

      $locationProvider.html5Mode true
      return
  ]
