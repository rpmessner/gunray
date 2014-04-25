((g, m, u, _) ->

  bindFunc = (self, bindings) ->
    ->
      u.debug "binding: ", self, bindings, arguments
      first = _.first(arguments)
      bound = []
      switch
        when _.isFunction(first)
          bindings.push(event: 'all', callback: first)
          bound.push _.last(bindings)
        when _.isObject(first)
          for event, func of first
            [event, prop] = event.split(":")
            bindings.push(event: event, callback: func, property: prop)
            bound.push _.last(bindings)
      -> _.remove bindings, (x) -> _.include bound, x

  triggerFunc = (self, bindings) ->
    (item, event, value, previous) ->
      u.debug "triggering: ", self, bindings, arguments
      for binding in _.clone(bindings)
        if binding.event is event or binding.event is 'all'
          unless u.isBlank(binding.property)
            binding.callback(
              item.get(binding.property), item, event, previous
            ) unless u.isBlank item.prop(binding.property)
          else
            binding.callback(item, event, previous)
      triggerUpstream(self, arguments)

  triggerUpstream = (item, args) ->
    if hasUpstream(item)
      item.collection().trigger.apply(item, args)

  o = c = null

  hasUpstream = (item) ->
    o ||= require('./object.coffee')
    c ||= require('./collection.coffee')
    o.isObject(item) and
    _.isFunction(item.collection) and
    c.isCollection(item.collection())

  m.exports =
    triggerFunc: triggerFunc
    bindFunc: bindFunc

)(@, module, require('./utils.coffee'), require('lodash'))
