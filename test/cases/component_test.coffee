gunray = require 'gunray'

h = require '../helpers.coffee'

component = gunray.component
isComponent = gunray.isComponent

collection = gunray.collection
object = gunray.object
html = gunray.html

cmp = null

QUnit.module "Gunray.Component",
  setup: ->
  teardown: ->

test 'can be created', ->
  cmp = component()
  ok isComponent cmp

test 'can be assigned state', ->
  state = object(nums: [1,2,3])
  cmp = component(state: state)
  deepEqual cmp.state(), state

test 'can be assigned a dom/html element', ->
  view = html(["h1", "some content"])
  cmp = component(html: view)
  h.equalHtml cmp.html(), '<h1>some content</h1>'

test 'can be assigned a dom/html deferred element', ->
  cmp = component(
    state: object(name: 'myComponent')
    html: (state) ->
      ["h1", "some content #{state.get('name')}"]
  )
  h.equalHtml cmp.html(), '<h1>some content myComponent</h1>'

# test 'can be nested', ->
#   innerCmp = (state) ->
#     component(
#       state: object(state)
#       html: (state) ->
#         ["li", state.get('name')]
#     )

#   outerCmp = component(
#     state: object(items: [{name: 'foo'}, {name: 'bar'}])
#     html: (state) ->
#       ['ul', state.get('items').map((item) -> innerCmp(item))]
#   )

#   h.equalHtml outerCmp.html(), '<ul><li>foo</li><li>bar</li></ul>'

# test 'can handle dom events', 1, ->
#   view = html(["h1", "some content"])
#   cmp = component(html: view)
#   cmp.click (event, cmp) ->
#     deepEqual event.target, cmp.html().dom
#   sim.click cmp.html().dom

# test 'can interact with the router', 1, ->
#   location = new Location('http://www.example.com')
#   hist = history(location: location, pushState: ->)

#   parent = document.createElement('div')
#   parent.id = 'foo'
#   document.appendChild parent

#   pagesCmp = component(
#     container: parent
#     collection: collection({name: 'foo'}, {name: 'bar'})
#     html: (cmp) ->
#       [
#         ["ul", (cmp.collection().html selected: (item) ->
#             ["li", item.prop('name')]
#           ), ["li#items"]
#         ]
#       ]

#   itemsCmp = component(
#     parent: pagesCmp
#     container: "li#items"
#     collection: collection({name: 'fizz'}, {name: 'buzz'})
#     html: (cmp) ->
#       ["ul", cmp.collection().html selected: (item) ->
#         ["li", item.prop('name')]
#       ]

#   router.map ->
#     @route 'pages/:name', pagesCmp, ->
#       @route 'items/:name', itemsCmp

#   hist.start()

#   hist.navigate("page/foo")

#   equalHtml dom: parent,
#     '<ul><li>foo</li><li id="items"></li></ul>'

#   hist.navigate("page/foo/items/fizz")

#   equalHtml dom: parent,
#     '<ul><li>foo</li><li id="items">' +
#     '<ul><li>fizz</li></ul></li></ul>'

#   hist.navigate("page/bar/items/fizz")

#   equalHtml dom: parent,
#     '<ul><li>bar</li><li id="items">' +
#     '<ul><li>fizz</li></ul></li></ul>'

#   document.removeChild parent
