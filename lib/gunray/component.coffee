((g, m, p, t, u, _)->

  Component = ->
  Component.create = (options={})->
    state = p.property(options.state)
    name = p.property(options.name)
    dom =
      switch
        when t.isHtml options.html
          p.property(options.html)
        when _.isFunction options.html
          =>
            @html = p.property(t.html(options.html(state())))
            @html()
    #       else null

    #   children = []
    #   addChild = (child) ->
    #     children.push child
    #     dom = @html()
    #     childDom = child.html()
    #     # dom.children.push childDom
    #     dom.appendChild childDom.dom

    _.extend @,
      __type__: Component
      state: state
      html: dom
      # name: name
      # addChild: addChild

    @

  component = u.creator(Component)
  isComponent = u.isTypeFunc(Component)

  m.exports =
    component: component
    isComponent: isComponent

)(@, \
  module, \
  require('./property.coffee'), \
  require('./template.coffee'), \
  require('./utils.coffee'), \
  require('lodash'))
