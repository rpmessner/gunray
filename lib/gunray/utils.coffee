((g, m, _) ->

  toString = (x) -> "" + x

  isBlank = (val) ->
    _.isUndefined(val) or _.isNull(val) or
    _.isEqual({}, val) or _.isEqual([], val)

  creator = (klass) ->
    -> klass.create.apply(new klass, arguments)

  isTypeFunc = (type) ->
    (object) -> !isBlank(object) and object.__type__ is type

  assert = (cond, msg) ->
    if _.isArray(cond)
      throw msg unless _.all(cond)
    else
      throw msg unless cond

  DEBUG = false
  debug = -> if DEBUG then console.log.apply(console, arguments)

  m.exports =
    toString: toString
    isBlank: isBlank
    isTypeFunc: isTypeFunc
    creator: creator
    assert: assert
    debug: debug

)(@, module, require('lodash'))
