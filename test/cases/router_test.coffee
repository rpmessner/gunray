# route = Gunray.Route
# router = Gunray.Router
# property = Gunray.Property
# observable = Gunray.Collection
# collection = Gunray.Collection

# module "Gunray Router",
#   setup:  ->
#     coll = collection([{id: 1, name: 'Betty', category: 'Foo'},
#                        {id: 2, name: 'Dan',   category: 'Foo'}])
#     ul = html ["#content",
#                 coll.html selected: (obj) ->
#                   ["h1", ],
#                 ["ul#list", coll.html (obj) ->
#                   ["li", class: obj.prop('category'),
#                     ["a", href: computed(obj.prop('id'), (id) ->
#                       "/#{id}"), obj.prop("name")]
#                 ]]]
#   teardown: ->

# test 'routes on id param', 2, ->
#   route "/:id", coll, (obj, id) ->
#     deepEqual obj, coll.first, 'first argument is matched object'
#     equal id, 1, 'second argument is url'

#   history.pushState null, null, "/1"

# # test 'router', ->
# #   router [route("/:slug/:id",
# #             slug: [coll, 'name'],
# #             id: [posts, 'id'], (dmodel
# #           route("/:id", ]
