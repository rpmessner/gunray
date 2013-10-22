#= require sinon
#= require simulate
#= require_self

Function::andThen = (argFunction) ->
  invokingFunction = @
  -> argFunction.call @, invokingFunction.apply(@, arguments)

Function::compose = (argFunction) ->
  invokingFunction = @
  -> invokingFunction.call @, argFunction.apply(@, arguments)

_.extend window,
  sim: Simulate
  equalHtml: (dom, string) -> equal dom.dom.outerHTML, string
