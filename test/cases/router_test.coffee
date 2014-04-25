gunray = require 'gunray'
h = require '../helpers.coffee'
route = gunray.route
router = gunray.router
property = gunray.property
observable = gunray.observable
collection = gunray.collection
history = gunray.history

hist = location = null

QUnit.module "Gunray Router",
  setup:  ->
    location = new h.Location('http://www.example.com')
    hist = history(location: location, pushState: ->)

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

  coll = collection([
    {id: 1, name: 'Betty', category: 'Foo'},
    {id: 2, name: 'Dan',   category: 'Foo'}
  ])

  router.map ->
    @route 'person', person, ->
      @route ':id', collIdRoute, coll
      @route ':name', collNameRoute, coll

  location.replace 'http://www.example.com/person/1'

  hist.checkUrl()

  equal router.path(), 'person/1'

  location.replace 'http://www.example.com/person/Dan'

  hist.checkUrl()

  equal router.path(), 'person/Dan'

test "history#navigate does nothing if not started", 1, ->
  location.replace 'http://www.example.com/foo'
  hist.navigate '/page'
  equal location.href, 'http://www.example.com/foo'

test "history#navigate without pushState", 3, ->
  page = (route) -> equal route, 'page'

  router.map -> @route 'page', page

  hist.start()
  hist.navigate '/page'

  equal location.href, 'http://www.example.com/page'
  equal router.path(), 'page'

test "history#navigate with pushState", 2, ->
  pushState = (state, title, path) ->
    equal title, document.title
    equal path, '/foobar'

  hist = history(location: location, pushState: pushState)

  hist.start(pushState: true)

  hist.navigate "/foobar"
