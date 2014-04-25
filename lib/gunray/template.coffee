((g, m, p, o, c, d, u, _) ->

  updateClassName = (node, __, classes) ->
    node.className = classes.join(" ")

  updateAttribute = (node, name, attr) ->
    switch name
      when 'checked'
        checked = !!attr
        if checked then node.setAttribute(name, attr)
        else node.removeAttribute(name)
        node.checked = checked
      else
        node.setAttribute(name, attr)

  updateStyle = (node, property, style) ->
    node.style.setProperty(property, style)

  updateTextNode = (node, __, value) ->
    node.data = u.toString(value)

  updateItem = (node, name, prop, updateFunc) ->
    updateFunc node, name, (
      if p.isProperty(prop) or d.isComputed(prop)
        prop(_.curry(updateFunc)(node, name))
        prop()
      else prop
    )

  addTextNode = (node, content) ->
    textNode = document.createTextNode('')
    node.appendChild(textNode)
    updateItem textNode, 'data', content, updateTextNode

  addChildNode = (node, content, coll) ->
    child = html(content)
    addChildTemplate.call(@, node, child, coll)

  removeChildDom = (node, child) ->
    -> node.removeChild(child)

  removeChild = (children, child) ->
    -> children.slice _.indexOf(children, child), 1

  addChildTemplate = (node, child, coll, event, index) ->
    @children.push(child)
    bindChild.apply(@, arguments) unless u.isBlank(coll)
    if !u.isBlank(index) and index <= node.childNodes.length and !u.isBlank(
      sibling = node.childNodes[index]
    )
      node.insertBefore(child.dom, sibling)
    else
      node.appendChild child.dom

  bindChild = (node, child, coll, event) ->
    domRemove = removeChildDom(node, child.dom)
    childRemove = removeChild(@children, child)
    unbindAndRemove = ->
      domRemove()
      childRemove()
      unbind()
    bindArg = {}
    bindArg[event] = (item, event, previous) ->
      if (
        event is 'remove' and item is child.__context__
      ) or (
        event is 'select' and _.last(arguments) is child.__context__
      ) then unbindAndRemove()
    unbind = coll.bind(bindArg)

  applyRest = (node, rest, coll) ->
    for arg in rest
      switch
        when isHtml(arg)
          addChildTemplate.call(@, node, arg, coll, 'remove')
        when c.isCollection(arg)
          applyItem = (itemFunc) =>
            (item) => applyRest.call(@, node, [itemFunc(item)], arg)
          arg.bind(add: applyItem(arg.iterator))
          arg.each applyItem((item) -> item)
        when _.isArray(arg) and _.isArray(_.first(arg))
          applyRest.call(@, node, arg)
        when _.isArray(arg)
          addChildNode.call(@, node, arg)
        when p.isProperty(arg) and (child = arg()) and _.isArray(child)
          index = node.childNodes.length
          updateFunc = (updated) =>
            addChildTemplate.call(
              @, node, updated, updated.__collection__, 'select', index
            )
          updateFunc(child) unless u.isBlank _.first(child)
          arg updateFunc
        else addTextNode.call(@, node, arg)

  tagSplitter = /([^\s\.\#]*)(?:\#([^\s\.\#]+))?(?:\.([^\s\#]+))?/

  splitTag = (tagName) ->
    [__, tagName, id, classnames] = tagName.match tagSplitter
    [tagName or 'div', id, (classnames.split(".") if classnames)]

  events = (
    "click focus blur dblclick change mousedown mousemove mouseout " +
    "mouseover mouseup resize scroll select submit load unload"
  ).split(" ")

  applyAttributes = (node, id, classes, attributes) ->
    attributes['id'] = id if id
    attributes['classes'] = classes if classes
    if (classname = attributes['class'])
      attributes['classes'] ||= []
      attributes['classes'].push classname
    for name, attr of attributes
      switch
        when name is 'classes'
          updateItem(node, 'className', attr, updateClassName)
        when name is 'style'
          for property, style of attr
            updateItem(node, property, style, updateStyle)
        when _.include(events, name)
          attr(node)
        else
          updateItem(node, name, attr, updateAttribute)

  getAttributes = (template) ->
    rest = _.rest(template)
    next = _.first(rest)
    if isAttributes(next)
      [next, _.rest(rest)]
    else
      [{}, rest]

  isAttributes = (arg) ->
    _.isObject(arg) and
    !_.isArray(arg) and
    !_.isFunction(arg) and
    !c.isCollection(arg)

  isTag = (node, tagName) ->
    !u.isBlank(node) and
    !u.isBlank(tagName) and
    node.tagName.toLowerCase() is tagName.toLowerCase()

  findOrCreateDom = (id, tagName) ->
    ret = document.getElementById(id)
    if u.isBlank(ret) or !isTag(ret, tagName)
      document.createElement(tagName)
    else ret

  Template = ->
  Template.create = (template, options) ->
    options = options || {}

    u.assert _.isArray(template), "Invalid Template"

    tagName = _.first(template)

    u.assert _.isString(tagName), "Invalid Template"

    [tagName, id, classes] = splitTag(tagName)
    [attributes, rest] = getAttributes(template)

    children = []

    node = findOrCreateDom(id, tagName)

    _.extend @,
      __type__: Template
      __context__: options.item
      __collection__: options.collection
      dom: node
      children: children

    applyAttributes.call(@, node, id, classes, attributes)
    applyRest.call(@, node, rest, options.collection)

    @

  html = u.creator(Template)
  isHtml = u.isTypeFunc(Template)

  m.exports =
    html: html
    isHtml: isHtml

)(@, \
  module, \
  require('./property.coffee'), \
  require('./object.coffee'), \
  require('./collection.coffee'), \
  require('./computed.coffee'), \
  require('./utils.coffee'), \
  require('lodash'))
