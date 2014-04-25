((g, m, u, p, c, _) ->

  path = p.property()

  baseRoute = null

  Route = ->
    _.extend @,
      handlers: []
      route: Route.create

  parseRouteCreateArgs = (args) ->
    [name, handler] = args
    last = _.last(args)
    [coll, nested] =
      switch
        when args.length is 3 and c.isCollection last
          [last, null]
        when args.length is 3 and _.isFunction last
          [null, last]
        when args.length is 4
          [args[2], last]
        else [null, null]
    [name, handler, coll, nested]

  Route.create = ->
    [name, handler, coll, nested] =
      parseRouteCreateArgs(arguments)
    @handlers.push
      name: name
      handler: handler
      collection: coll
      subroute: nested.apply new Route() unless u.isBlank nested
    @

  Router =
    map: (func) -> baseRoute = func.apply(new Route())
    path: -> path()
    reset: -> baseRoute = null

  History = ->
  History.create = (options) ->
    @location = options.location || window.location
    @pushState = options.pushState || window.history.pushState

    _.extend Router, history: @

    _.extend @,
      start: (options={}) ->
        @started = true
        @usePushState = !!options.pushState
        @root = "#{@location.protocol}#{@location.host}"
      navigate: (path) ->
        u.assert(path.match /^\//, "must be supply a relative path")
        return unless @started
        if @usePushState
          @pushState {}, document.title, path
        else
          @location.replace "#{@root}#{path}"
        @checkUrl()
      checkUrl: ->
        path @location.pathname.replace(/^\//,'')
        parts = path().split('/')
        _.reduce parts, ((current, part) ->
          return null if u.isBlank current
          ret = current
          _.each current.handlers, (handler) ->
            if matches = handler.name.match /^:([a-zA-Z0-9]+)$/
              field = _.last matches
              item = handler.collection.find (x) ->
                x.get(field) is parseInt(part) or
                x.get(field) is part
              return if u.isBlank(item)
              handler.handler(part, item)
            else
              return unless part is handler.name
              ret = handler.subroute
              handler.handler(part)
          ret
        ), baseRoute
    @

  history = u.creator(History)

  m.exports =
    router: Router
    route: Route.create
    history: history

)(@, \
  module, \
  require('./utils.coffee'), \
  require('./property.coffee'), \
  require('./collection.coffee'), \
  require('lodash'))
