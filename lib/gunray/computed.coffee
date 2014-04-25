((g, m, p, c, u, _) ->

  Computed = ->
  Computed.create = ->
    properties = Array::slice.call(arguments)
    func = properties.pop()

    bindings = []

    _.map properties, (prop) ->
      switch
        when c.isCollection(prop)
          prop.bind -> callBindings()
        when p.isProperty(prop)
          prop -> callBindings()

    callBindings = _.debounce((
      ->
        _.map(bindings, (binding) -> binding getComputed())
    ), 1)

    propertyValues = ->
      _.map properties, (x) ->
        if p.isProperty(x) then x.call()
        else x

    getComputed = =>
      func.apply @, propertyValues()

    retval = (binding) ->
      unless u.isBlank binding
        bindings.push(binding)
      else
        getComputed()

    _.extend retval,
      __type__: Computed

    retval

  computed = u.creator(Computed)
  isComputed = u.isTypeFunc(Computed)

  m.exports =
    computed: computed
    isComputed: isComputed

)(@, \
  module, \
  require('./property.coffee'), \
  require('./collection.coffee'), \
  require('./utils.coffee'), \
  require('lodash'))
