computed = Gunray.computed
isComputed = Gunray.isComputed
prop = Gunray.property

comp = null

module "Gunray Computed",
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
