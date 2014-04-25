gunray = require 'gunray'
object = gunray.object
isObject = gunray.isObject

o = null

QUnit.module "Gunray Object",
  setup: ->
    o = object(
      isAdmin:   false
      lastName:  'last'
      firstName: 'first'
      createdAt: new Date('Wed Oct 25, 2001')
      child:
        name: 'gerald'
        location:
          zip: '60640'
      children: [
        { name: 'dorothy' }
        { name: 'marvin' }
        { name: 'friedrich' }
        { name: 'jens' }
      ]
    )
  teardown: -> o = null

test 'creates object', 3, ->
  notEqual o, undefined
  notEqual o, null
  ok isObject(o)

test 'creates properties', 2, ->
  equal o.get('firstName'), 'first'
  equal o.prop('firstName')(), 'first'

test 'creates nested properties', 4, ->
  equal o.get('child.name'), 'gerald'
  equal o.prop('child.name')(), 'gerald'
  equal o.get('child.location.zip'), '60640'
  equal o.prop('child.location.zip')(), '60640'

test 'sets properties', 2, ->
  o.set 'firstName', 'newFirst'

  equal o.get('firstName'), 'newFirst'
  equal o.prop('firstName')(), 'newFirst'

test 'sets multiple properties', 2, ->
  o.set firstName: 'newFirst', lastName: 'newLast'

  equal o.get('firstName'), 'newFirst'
  equal o.get('lastName'), 'newLast'

test 'sets nested properties', 2, ->
  o.set 'child.name', 'fitzgerald'

  equal o.get('child.name'), 'fitzgerald'
  equal o.prop('child.name')(), 'fitzgerald'

test 'bind events for object', 2, ->
  o.bind (model) -> deepEqual o, model
  o.bind (model) -> deepEqual o, model
  o.set 'firstName', 'Harold'

test 'remove bindings for object', 1, ->
  unbind = o.bind (model) -> ok true
  o.set 'firstName', 'foo'
  unbind()
  o.set 'firstName', 'bar'

test 'bindings fire only when property changed', 1, ->
  counter = 0
  o.bind (model) -> counter++
  o.set 'firstName', 'Dottie'
  o.set 'firstName', 'Dottie'
  o.set 'firstName', 'Louis'
  equal counter, 2

test 'bindings for specific events', 1, ->
  o.bind update: -> ok true
  o.set 'lastName', 'Washington'

test 'bindings for specific properties and events', 1, ->
  o.bind 'notAnEvent:firstName': -> ok false
  o.bind 'update:lastName': -> ok true
  o.set 'lastName', 'Washington'

test 'bindings for nested properties', 1, ->
  o.bind 'update:child.name': -> ok true
  o.set 'child.name', 'Gerald'

test 'bindings provide access to current, previous values and the object', 4, ->
  o.bind 'update:firstName': (firstName, object, event, previous) ->
    equal previous, 'first'
    equal event, 'update'
    deepEqual object, o
    equal firstName, 'Fitzgerald'

  o.set 'firstName', 'Fitzgerald'

test 'gets collection values', ->
  equal o.get('children.at(0).name'), 'dorothy'

test 'sets collection values', ->
  o.set('children.at(0).name', 'toto')
  equal o.get("children.at(0).name"), 'toto'
