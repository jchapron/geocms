contexts = angular.module "geocms.contexts", [
  'ui.router'
  'restangular'
  'geocms.map'
  'geocms.cart'
]

contexts.config [
  "$stateProvider",
  ($stateProvider) ->
    $stateProvider
      .state 'contexts',
        url: "/maps"
        views:
          "":
            templateUrl: "/templates/contexts/root.html"
          "header":
            templateUrl: "/templates/shared/header.html"
        abstract: true
        resolve:
          folders: ["Restangular", (Restangular) ->
            Restangular.all('folders').customGETLIST("writable")
          ]
      .state 'contexts.root',
        url: ""
        parent: "contexts"
        views:
          "sidebar@contexts":
            templateUrl: "/templates/contexts/sidebar.html"
            controller: "ContextsController"
          "map@contexts":
            templateUrl: "/templates/contexts/map.html"
            controller: ["mapService", "data", "$rootScope", "$state", "$scope", (mapService, data, $root, $state, $scope) ->
              if data != null && data != undefined && data != "null"
                $state.transitionTo('contexts.show', {slug: data.slug})
              else
                context = { center_lat: 48.331638, center_lng: -4.34526, zoom: 6 }
                mapService.createMap("map", context.center_lat, context.center_lng, context.zoom)
                $root.cart.context = context
                mapService.addBaseLayer()
              $scope.mapService = mapService
            ]
        resolve:
          data: ["Restangular", (Restangular) ->
            Restangular.all('contexts').customGET("default")
          ]

      .state 'contexts.show',
        url: '/{slug}'
        parent: 'contexts.root'
        views:
          "sidebar@contexts":
            templateUrl: "/templates/contexts/sidebar.html"
            controller: "ContextsController"
          "map@contexts":
            templateUrl: "/templates/contexts/map.html"
            controller: ["mapService", "data", "folders", "$rootScope", "$scope", (mapService, data, folders, $root, $scope) ->
              mapService.createMap("map", data.center_lat, data.center_lng, data.zoom)
              mapService.addBaseLayer()
              $root.cart.context = data
              $root.cart.addSeveral()
              $root.cart.folders = folders
              $scope.mapService = mapService
            ]
        resolve:
          data: ["Restangular", "$stateParams", (Restangular, $stateParams) ->
            Restangular.one('contexts', $stateParams.slug).get()
          ]
      .state 'contexts.show.share',
        url: '/share'
        parent: 'contexts.show'
        views:
          "header@":
            templateUrl: ""
            controller: ["$rootScope", "mapService", ($root, ms) ->
              $root.fullscreen = true
              setTimeout (->
                ms.invalidateMap()
                return
              ), 2000
            ]
          "sidebar@contexts":
            templateUrl: ""
            controller: "ContextsController"
]

contexts.controller "ContextsController", [
  "$scope"
  "$rootScope"
  "$state"
  "mapService"
  "cartService"
  "mapOptionService"

  ($scope, $root, $state, mapService, Cart, optionService) ->

    $root.cart = new Cart() # unless $root.cart?

    $scope.openCatalog = () ->
      if ($state.current.name.indexOf('catalog') > -1) then $state.go "^" else $state.go ".catalog"

    $scope.treeOptions = {
      dropped: (event) ->
        console.log event.dest
    }

    $scope.mapOptions = optionService
    $scope.mapService = mapService
    $root.fullscreen = false unless $state.is("contexts.show.share")
]