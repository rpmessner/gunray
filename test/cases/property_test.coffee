prop = Gunray.property
isProperty = Gunray.isProperty

updated = r1 = r2 = r3 = p = p2 = null

module "Gunray Property",
   setup: ->
     updated = 0
     p = prop()
     p2 = prop()
     [r1, r2, r3]  = _.times 3, Math.random
   teardown: ->

test 'is created', 2, ->
  equal isProperty(p), true
  ok _.isFunction(p)

test 'can be updated', 2, ->
  p(r1)
  p2(r2)
  equal p(), r1
  equal p2(), r2

test 'notifies observers', 13, ->
  listener = (val) ->
    updated++
    equal val, r1 if updated is 1
    equal val, r3 if updated is 2
    ok true

  listener2 = (val) ->
    ok false

  p2(listener2)

  remove = p(listener)

  equal 'function', typeof remove
  equal updated, 0

  p(r1)
  equal updated, 1

  remove()
  p(r2)
  equal p(), r2
  equal updated, 1

  equal updated, 1
  equal p(), r2

  p(listener)
  p(r3)

  equal updated, 2
  equal p(), r3
