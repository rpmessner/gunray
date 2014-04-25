_ = require 'lodash'
gunray = require 'gunray'
prop = gunray.property
isProperty = gunray.isProperty

updated = r1 = r2 = r3 = p = p2 = null

QUnit.module "Gunray Property",
  setup: ->
    updated = 0
    p = prop()
    p2 = prop()
    [r1, r2]  = _.times 2, Math.random
  teardown: ->

test 'is created', 2, ->
  equal isProperty(p), true
  ok _.isFunction(p)

test 'can be initialized with value', 2, ->
  initializedProp = prop("foo")
  equal isProperty(initializedProp), true
  equal initializedProp(), "foo"

test 'can be updated', 2, ->
  p(r1)
  p2(r2)
  equal p(), r1
  equal p2(), r2

test 'binds observers', 2, ->
  p (val) ->
    equal val, r1
    ok true

  p2 (val) -> ok false

  p(r1)

test 'supplies previous value to observers', 2, ->
  p(r1)

  p (val, old) ->
    equal val, r2
    equal old, r1

  p(r2)

test 'removes bindings', 2, ->
  p (val) ->
    equal val, r1
    ok true

  unbind = p2 (val) -> ok false

  unbind()

  p(r1)
  p2(r2)
