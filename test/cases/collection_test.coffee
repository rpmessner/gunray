collection = Gunray.collection
isCollection = Gunray.isCollection
coll = null

module "Gunray Collection",
  setup: ->
    coll = collection([
      firstName: 'first'
      lastName:  'last'
    ])
  teardown: ->

addItem = (item=firstName: 'Charley', lastName: 'Patton') ->
  coll.add(item)

test 'creates collection', 3, ->
  notEqual coll, undefined
  notEqual coll, null
  ok isCollection(coll)

test 'provides length', 3, ->
  equal coll.size(), 1
  equal coll.count(), 1
  equal coll.length(), 1

test 'first and rest', 2, ->
  equal coll.first().get('firstName'), 'first'
  deepEqual coll.rest(), []

test 'observes collection', 3, ->
  coll.bind (obj, event) ->
    equal obj.val('firstName'), 'Charley'
    equal event, 'add'

  addItem()

  equal coll.size(), 2

test 'observes collection event', 2, ->
  coll.bind add: (obj) ->
    equal obj.val('firstName'), 'Charley'

  coll.bind remove: -> ok false

  addItem()

  equal coll.size(), 2

test 'observes collection property event', 3, ->
  coll.bind 'add:firstName': (name, obj) ->
    equal name, 'Charley'
    equal obj.val('lastName'), 'Patton'

  coll.bind 'add:notAProperty': -> ok false

  addItem()

  equal coll.size(), 2

test 'allows index access', 1, ->
  first = coll.at(0)
  equal first.get("firstName"), 'first'

test 'observes collection change', 4, ->
  coll.bind('update:firstName': (name, obj, event, previous) ->
    equal name, 'George'
    equal event, 'update'
    equal obj.val('firstName'), 'George'
    equal previous, 'first', 'Charley')
  coll.at(0).set('firstName', 'George')

test 'provides forEach function', 4, ->
  addItem()
  index = 0
  coll.each (obj, i) ->
    equal i, index
    equal coll.at(i).val('firstName'), obj.val('firstName')
    index++

test 'provides map function', 6, ->
  addItem()
  index = 0
  result = coll.map (obj, i) ->
    equal i, index
    equal coll.at(i).val('firstName'), obj.val('firstName')
    index++
  equal result.at(0)(), 0
  equal result.at(1)(), 1

test 'provides reduce function', 2, ->
  addItem()
  result = coll.reduce [], (coll, val) ->
    coll.push val.get('firstName')
    coll
  equal result.at(0)(), 'first'
  equal result.at(1)(), 'Charley'

test 'allows integer access', 1, ->
  equal coll.at(0).val('firstName'), 'first'

test 'observes collection remove', 4, ->
  coll.on((obj, event) ->
    equal obj.val('firstName'), 'first'
    equal event, 'remove'
  )
  coll.on(remove: (obj) ->
    equal obj.val('firstName'), 'first'
  )
  coll.removeAt(0)
  equal coll.length(), 0
