((g, m, _) ->

  prop      = require('./property.coffee')
  obj       = require('./object.coffee')
  coll      = require('./collection.coffee')
  computed  = require('./computed.coffee')
  template  = require('./template.coffee')
  router    = require('./router.coffee')
  component = require('./component.coffee')

  m.exports =
    isComponent: component.isComponent
    component: component.component
    isProperty: prop.isProperty
    isObject: obj.isObject
    isCollection: coll.isCollection
    isComputed: computed.isComputed
    isHtml: template.isHtml
    html: template.html
    property: prop.property
    object: obj.object
    collection: coll.collection
    computed: computed.computed
    router: router.router
    route: router.route
    history: router.history

)(@, module, require('lodash'))
