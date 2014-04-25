((g, m, p, e, u, _) ->

  c = null

  Obj = ->
  Obj.create = ->
    c ||= require './collection.coffee'
    input = _.first(arguments)
    data = _.reduce input, (
      (coll, value, key) ->
        switch
          when _.isArray(value)
            coll[key] = c.collection(value)
          when _.isObject(value)
            obj = object(value)
            coll[key] = obj
          else
            coll[key] = p.property()
            coll[key](value)
        coll
      ), {}

    setValue = ->
      [path, value] = arguments
      set = (attribute, value) =>
        prop = getProperty(attribute)
        u.assert p.isProperty(prop), 'Improper call to set'
        previous = prop()
        return if previous is value
        prop(value)
        trigger(@, 'update', value, previous)
      switch
        when _.isString path
          set(path, value)
        when _.isObject path
          for key, value of path
            set(key, value)

    getValue = (key) ->
      getProperty(key)()

    getProperty = (path) ->
      _.reduce(
        path.split("."), (
          (coll, prop) ->
            switch
              when (matches = prop.match /^at\((\d)\)$/)
                u.assert(
                  c.isCollection(coll), \
                  "Tried to use index access on a non-collection"
                )
                coll.at _.last(matches)
              when _.isFunction(coll.prop)
                coll.prop(prop)
              when _.isObject(coll)
                coll[prop]
              else coll
        ), data
      )

    bindings = []

    bind = e.bindFunc(@, bindings)
    trigger = e.triggerFunc(@, bindings)

    _.extend @,
      __type__: Obj
      get: getValue
      set: setValue
      prop: getProperty
      bind: bind

    @

  object = u.creator(Obj)
  isObject = u.isTypeFunc(Obj)

  m.exports =
    object: object
    isObject: isObject

)(@, \
  module, \
  require('./property.coffee'), \
  require('./events.coffee'), \
  require('./utils.coffee'), \
  require('lodash'))
