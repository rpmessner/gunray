object = Gunray.object
isObject = Gunray.isObject

o = null

module "Gunray Object",
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
      # children: [
      #   { name: 'dorothy' }
      #   { name: 'marvin' }
      #   { name: 'friedrich' }
      #   { name: 'jens' }
      # ]
    )
  teardown: -> o = null

test 'creates object', 3, ->
  notEqual o, undefined
  notEqual o, null
  ok isObject(o)

test 'creates properties', 5, ->
  equal o.value('firstName'), 'first'
  equal o.val('firstName'), 'first'
  equal o.get('firstName'), 'first'
  equal o.property('firstName')(), 'first'
  equal o.prop('firstName')(), 'first'

test 'creates nested properties', 4, ->
  equal o.value('child.name'), 'gerald'
  equal o.property('child.name')(), 'gerald'
  equal o.value('child.location.zip'), '60640'
  equal o.property('child.location.zip')(), '60640'

test 'sets properties', 2, ->
  o.set 'firstName', 'newFirst'

  equal o.value('firstName'), 'newFirst'
  equal o.property('firstName')(), 'newFirst'

test 'sets nested properties', 2, ->
  o.set 'child.name', 'fitzgerald'

  equal o.value('child.name'), 'fitzgerald'
  equal o.property('child.name')(), 'fitzgerald'

test 'bind events for object', 2, ->
  o.bind (model) -> deepEqual o, model
  o.on (model) -> deepEqual o, model
  o.set 'firstName', 'Harold'

test 'bindings fire only when property changed', 1, ->
  counter = 0
  o.on (model) -> counter++
  o.set 'firstName', 'Dottie'
  o.set 'firstName', 'Dottie'
  o.set 'firstName', 'Louis'
  equal counter, 2

test 'bindings for specific events', 1, ->
  o.on update: -> ok true
  o.set 'lastName', 'Washington'

test 'bindings for specific properties and events', 1, ->
  o.on 'notAnEvent:firstName': -> ok false
  o.on 'update:lastName': -> ok true
  o.set 'lastName', 'Washington'

test 'bindings for nested properties', 1, ->
  o.on 'update:child.name': -> ok true
  o.set 'child.name', 'Gerald'

test 'bindings provide access to current, previous values and the object', 4, ->
  o.on 'update:firstName': (firstName, object, event, previous) ->
    equal previous, 'first'
    equal event, 'update'
    deepEqual object, o
    equal firstName, 'Fitzgerald'

  o.set 'firstName', 'Fitzgerald'

# test 'gets collection values', ->
#   equal o.value('children.at(0).name'), 'dorothy'
