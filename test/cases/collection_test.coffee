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

test 'provides length', 1, ->
  equal coll.length(), 1

test 'add items', ->
  addItem()
  equal coll.length(), 2

test 'first and rest', 2, ->
  equal coll.first().get('firstName'), 'first'
  deepEqual coll.rest(), []

test 'last', 1, ->
  deepEqual coll.first(), coll.last()

test 'add items updates index', 2, ->
  addItem()
  equal coll.first().index(), 0
  equal coll.last().index(), 1

test 'observes collection', 3, ->
  coll.bind (obj, event) ->
    equal obj.get('firstName'), 'Charley'
    equal event, 'add'

  addItem()

  equal coll.length(), 2

test 'observes collection event', 2, ->
  coll.bind(add: (obj) ->
    equal obj.get('firstName'), 'Charley'
  )
  coll.bind(remove: -> ok false)
  addItem()

  equal coll.length(), 2

test 'removes collection binding', 1, ->
  unbind = coll.bind -> ok true
  coll.add firstName: 'foo', lastName: 'bar'
  unbind()
  coll.add firstName: 'fizz', lastName: 'buzz'

test 'observes collection property event', 3, ->
  coll.bind 'add:firstName': (name, obj) ->
    equal name, 'Charley'
    equal obj.get('lastName'), 'Patton'

  coll.bind 'add:notAProperty': -> ok false

  addItem()

  equal coll.length(), 2

test 'allows index access', 1, ->
  first = coll.at(0)
  equal first.get("firstName"), 'first'

test 'provides item indices', 2, ->
  addItem()
  equal coll.at(0).index(), 0
  equal coll.at(1).index(), 1

test 'observes collection change', 4, ->
  coll.bind('update:firstName': (name, obj, event, previous) ->
    equal name, 'George'
    equal event, 'update'
    equal obj.get('firstName'), 'George'
    equal previous, 'first', 'Charley')
  coll.at(0).set('firstName', 'George')

test 'provides forEach function', 4, ->
  addItem()
  index = 0
  coll.each (obj, i) ->
    equal i, index
    equal coll.at(i).get('firstName'), obj.get('firstName')
    index++

test 'provides map function', 6, ->
  addItem()
  index = 0
  result = coll.map (obj, i) ->
    equal i, index
    equal coll.at(i).get('firstName'), obj.get('firstName')
    index++
  equal result.at(0)(), 0
  equal result.at(1)(), 1

test 'provides reduce function', 2, ->
  addItem()
  result = coll.reduce [], (coll, val) ->
    coll.push val.get('firstName')
    coll
  equal result[0], 'first'
  equal result[1], 'Charley'

test 'allows integer access', 1, ->
  equal coll.at(0).get('firstName'), 'first'

test 'removes by index', 3, ->
  addItem()
  equal coll.length(), 2
  coll.removeAt(0)
  equal coll.length(), 1
  equal coll.at(0).index(), 0

test 'removes by identity', 1, ->
  coll.remove(coll.at(0))
  equal coll.length(), 0

test 'observes collection remove', 3, ->
  coll.bind((obj, event) ->
    equal obj.get('firstName'), 'first'
    equal event, 'remove'
  )
  coll.bind(remove: (obj) ->
    equal obj.get('firstName'), 'first'
  )
  coll.removeAt(0)

test 'can selected element by index', 2, ->
  addItem()
  coll.selectAt(0)
  equal coll.selectedIndex(), 0
  deepEqual coll.selected(), coll.at(0)

test 'can selected element by identity', 2, ->
  addItem()
  coll.selected(coll.at(1))
  equal coll.selectedIndex(), 1
  deepEqual coll.selected(), coll.at(1)

test 'can be notified when selected element changes', 2, ->
  coll.selected (object, index) ->
    deepEqual object, coll.at(0)
    equal index, 0
  coll.selectAt(0)

test 'can bind selected', 3, ->
  addItem()
  coll.selectAt(0)
  coll.bind select: (object, event, previous) ->
    deepEqual previous, coll.at(0)
    deepEqual object, coll.at(1)
    equal event, 'select'
  coll.selectAt(1)
