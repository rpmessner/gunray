_ = require 'lodash'

Function::andThen = (argFunction) ->
  invokingFunction = @
  -> argFunction.call @, invokingFunction.apply(@, arguments)

Function::compose = (argFunction) ->
  invokingFunction = @
  -> invokingFunction.call @, argFunction.apply(@, arguments)

LocationDouble = (href) ->
  @replace(href)

_.extend LocationDouble.prototype,
  parser: document.createElement('a')
  toString: -> @href
  replace: (href) ->
    @parser.href = href
    _.extend(
      @, \
      _.pick(@parser, \
        'href', 'hash', 'host', 'search', \
        'fragment', 'pathname', 'protocol' \
      )
    )
    @pathname = "/#{@pathname}" unless /^\//.test @pathname

module.exports =
  Location: LocationDouble
  waitForSync: (func) -> _.delay(func, 5)
  equalHtml: (dom, string) -> equal dom.dom.outerHTML, string
