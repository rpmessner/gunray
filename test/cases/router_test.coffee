route = Gunray.route
router = Gunray.router
property = Gunray.property
observable = Gunray.observable
collection = Gunray.collection
history = Gunray.history

hist = location = null

LocationDouble = (href) ->
  @replace(href)

_.extend LocationDouble.prototype,
  parser: document.createElement('a')
  toString: -> @href
  replace: (href) ->
    @parser.href = href
    _.extend @, _.pick @parser,
      'href', 'hash', 'host', 'search', 'fragment', 'pathname', 'protocol'
    @pathname = "/#{@pathname}" unless /^\//.test @pathname

module "Gunray Router",
  setup:  ->
    location = new LocationDouble('http://www.example.com')
    hist = history(location: location)

  teardown: ->
    lastRoute = lastArgs = null
    router.reset()

test "initialize", 1, ->
  equal router.history.location, location

test "routes", 2, ->
  page = (route) ->
    equal route, 'page'

  router.map ->
    @route 'page', page

  location.replace 'http://example.com/page'
  hist.checkUrl()

  equal router.path(), 'page'

test "nested routes", 3, ->
  page = (route) ->
    equal route, 'page'

  subpage = (route) ->
    equal route, 'subpage'

  notRun = -> ok false

  router.map ->
    @route 'page', page, ->
      @route 'subpage', subpage
    @route 'subpage', notRun

  location.replace 'http://example.com/page/subpage'

  hist.checkUrl()

  equal router.path(), 'page/subpage'

test "collection route", 8, ->
  person = (route) ->
    equal route, 'person'

  collIdRoute = (id, item) ->
    equal id, 1
    equal item, coll.first()

  collNameRoute = (name, item) ->
    equal name, 'Dan'
    equal item, coll.last()

  coll = collection([{id: 1, name: 'Betty', category: 'Foo'},
                     {id: 2, name: 'Dan',   category: 'Foo'}])
  router.map ->
    @route 'person', person, ->
      @route ':id', collIdRoute, coll
      @route ':name', collNameRoute, coll

  location.replace 'http://example.com/person/1'

  hist.checkUrl()

  equal router.path(), 'person/1'

  location.replace 'http://example.com/person/Dan'

  hist.checkUrl()

  equal router.path(), 'person/Dan'

test "history#navigate", 2, ->
  page = (route) -> equal route, 'page'

  router.map -> @route 'page', page

  hist.navigate 'http://example.com/page'

  equal router.path(), 'page'
