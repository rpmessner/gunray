gunray = require 'gunray'

computed   = gunray.computed
isComputed = gunray.isComputed
prop       = gunray.property
collection = gunray.collection
object     = gunray.object

comp = null

QUnit.module "Gunray Computed",
  setup: ->
  teardown: ->

test 'can be initialized with properties', 1, ->
  comp = computed prop(1), ->
  ok isComputed(comp), 'is an instance of computed'

test 'returns a value based on the return of function', 1, ->
  comp = computed prop(1), _.identity
  equal comp(), 1, 'equals the property value'

test 'can work based on multiple properties', 1, ->
  [p1, p2, p3] = _.times 3, (n) -> prop(n)
  comp = computed p1, p2, p3, (x, y, z) -> "" + x + y + z
  equal comp(), "012", 'equals the property values'

asyncTest 'can register bindings', 1, ->
  [p1, p2, p3] = _.times 3, (n) -> prop(n)
  comp = computed p1, p2, p3, (x, y, z) -> "" + x + y + z
  comp (final) ->
    equal final, '112', 'equals the updated value'
    start()
  p1(1)

asyncTest 'called only once on multiple bindings', 1, ->
  [p1, p2, p3] = _.times 3, (n) -> prop(n)
  comp = computed p1, p2, p3, (x, y, z) -> "" + x + y + z
  comp (final) ->
    equal final, '123', 'equals the updated value'
    start()
  p1(1)
  p2(2)
  p3(3)

test 'can compute based on collection', 1, ->
  coll = collection(['a','b','c','d'])
  comp = computed coll, (c) ->
    c.reduce "", (a, b) -> a + b()
  equal comp(), 'abcd'

asyncTest 'updates on collection change', 2, ->
  coll = collection(['a','b','c','d'])
  comp = computed coll, (c) ->
    c.reduce "", (a, b) -> a + b()

  coll.add 'e'
  waitForSync ->
    equal comp(), 'abcde'

    coll.removeAt(0)
    waitForSync ->
      equal comp(), 'bcde'
      start()

test 'can compute based on object', 2, ->
  obj = object(
    first: 'Steve',
    last: 'Earle'
  )
  comp = computed obj, (obj) ->
    obj.get('first') + ' ' + obj.get('last')

  equal comp(), "Steve Earle"

  obj.set("last", "Martin")

  equal comp(), "Steve Martin"
