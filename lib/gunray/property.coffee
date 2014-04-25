((g, m, u, _) ->

  Property = ->
  Property.create = ->
    bindings = []
    value = _.first(arguments)
    returnFunc = (val) ->
      switch
        when !isProperty(val) and _.isFunction(val)
          bindings.push(val)
          -> _.remove bindings, (x) -> x is val
        when u.isBlank(val)
          value
        else
          old = value
          value = val
          u.debug "property changed", value, bindings
          for obs in bindings
            obs(value, old)
          value

    _.extend returnFunc,
      __type__: Property

    returnFunc

  property = u.creator(Property)
  isProperty = u.isTypeFunc(Property)

  m.exports =
    property: property
    isProperty: isProperty

)(@, module, require('./utils.coffee'), require('lodash'))
