((global, _) ->

  #- Setup -------------------------------------------------
  Gunray = {}

  toString = (x) -> "" + x
  isBlank = (val) -> _.isUndefined(val) or _.isNull(val)

  creator = (klass) ->
    -> klass.create.apply(new klass, arguments)

  isTypeFunc = (type) ->
    (object) -> !isBlank(object) and object.__type__ is type

  assert = (cond, msg) -> throw msg unless cond

  #- Property ----------------------------------------------
  Property = ->
  Property.create = ->
    bindings = []
    value = _.first(arguments)
    returnFunc = (val) ->
      switch
        when _.isFunction(val)
          bindings.push(val)
          -> _.remove bindings, (x) -> x is val
        when isBlank(val)
          value
        else
          value = val
          _.each bindings, (obs) -> obs(value)
          value

    _.extend returnFunc,
      __type__: Property

    returnFunc

  property = creator(Property)
  isProperty = isTypeFunc(Property)

  #- Events ------------------------------------------------
  bindFunc = (self, bindings) ->
    ->
      first = _.first(arguments)
      bound = []
      switch
        when _.isFunction(first)
          bindings.push(event: 'all', callback: first)
          bound.push _.last(bindings)
        when _.isObject(first)
          _.each first, (func, event) ->
            [event, prop] = event.split(":")
            bindings.push(event: event, callback: func, property: prop)
            bound.push _.last(bindings)
      -> _.remove bindings, (x) -> _.include bound, x

  triggerFunc = (self, bindings) ->
    (item, event, value, previous) ->
      _.each _.clone(bindings), (binding) ->
        if binding.event is event or binding.event is 'all'
          unless isBlank(binding.property)
            unless isBlank(item.prop(binding.property))
              binding.callback(item.get(binding.property), item, event, previous)
          else
            binding.callback(item, event)
      if isObject(self) and _.isFunction(self.collection) and isCollection(self.collection())
        self.collection().trigger(item, event, value, previous)

  #- Object ------------------------------------------------
  Obj = ->
  Obj.create = ->
    input = _.first(arguments)
    data = _.reduce input, (coll, value, key) ->
      switch
        when _.isFunction(value) then null
        when _.isArray(value)
          coll[key] = collection(value)
        when _.isObject(value)
          obj = object(value)
          coll[key] = obj
        else
          coll[key] = property()
          coll[key](value)
      coll
    , {}

    setValue = ->
      [path, value] = arguments
      set = (attribute, value) =>
        prop = getProperty(attribute)
        previous = prop()
        return if previous is value
        prop(value)
        trigger(@, 'update', value, previous)
      switch
        when _.isString path
          set(path, value)
        when _.isObject path
          _.each path, (value, key) ->
            set(key, value)

    getValue = (key) ->
      getProperty(key)()

    getProperty = (path) ->
      _.reduce path.split("."), (coll, prop) ->
        switch
          when (matches = prop.match /^at\((\d)\)$/)
            assert isCollection(coll), "Tried to use index access on a non-collection"
            coll.at _.last(matches)
          when _.isFunction(coll.prop)
            coll.prop(prop)
          when _.isObject(coll)
            coll[prop]
          else coll
      , data

    bindings = []

    bind = bindFunc(@, bindings)
    trigger = triggerFunc(@, bindings)

    _.extend @,
      __type__: Obj
      __data__: data
      __bindings__: bindings
      get: getValue
      set: setValue
      trigger: trigger
      prop: getProperty
      bind: bind

    @

  object = creator(Obj)
  isObj = isObject = isTypeFunc(Obj)

  #- Collection --------------------------------------------
  Collection = ->
  Collection.create = ->
    arg = _.first(arguments)

    assert _.isArray(arg), "Invalid Argument"

    identity = property(@)

    makeCollectionItem = (item) =>
      retval =
        switch
          when isObject(item) then item
          when isHtml(item) then item
          when _.isObject(item) then object(item)
          when _.isArray(item) then collection(item)
          else  property(item)
      retval.collection = identity
      retval

    data = _.map arg, (datum) -> makeCollectionItem(datum)

    options = _.first(_.rest(arguments)) || {}
    bindings =  options.bindings || []

    bind = bindFunc(@, bindings)
    trigger = triggerFunc(@, bindings)
    iterator = options.iterator || identity

    length = -> data.length

    addItem = (item) ->
      item = makeCollectionItem(item)
      data.push item
      trigger(item, 'add', item, null)

    removeIndex = (index) ->
      item = atIndex(index)
      data.splice index, 1
      trigger(item, 'remove', item, null)

    removeItem = (item) -> removeIndex _.indexOf(data, item)

    atIndex = (i) -> _.first _.at(data, i)
    each = (func) -> collection _.each(data, func)
    map = (func) -> collection _.map(data, func), bindings: bindings, iterator: func
    mapHtml = (func) ->
      map (item) -> html(func(item), collectionItem: item)
    reduce = (memo, func) -> collection _.reduce(data, func, memo)

    _.extend @,
      __type__: Collection
      __data__: data
      __bindings__: bindings
      at: atIndex
      add: addItem
      remove: removeItem
      removeAt: removeIndex
      bind: bind
      iterator: iterator
      trigger: trigger
      first: -> _.first(data)
      rest: -> _.rest(data)
      last: -> _.last(data)
      length: length
      count: length
      size: length
      each: each
      map: map
      mapHtml: mapHtml
      inject: reduce
      reduce: reduce

    @

  collection = creator(Collection)
  isCollection = isColl = isTypeFunc(Collection)

  #- Template ----------------------------------------------
  removeChildDom = (node, child) ->
    -> node.removeChild(child)

  removeChild = (children, child) ->
    -> children.slice _.indexOf(children, child), 1

  addTextNode = (node, content, collection) ->
    textNode =
      document.createTextNode(
        switch
          when isProperty(content)
            content (value) ->
              textNode.data = toString(value)
            content()
          else toString(content)
      )
    childRemove = removeChild(node, textNode)
    # unbind = collection.bind(
    #   remove: (item) ->
    #     childRemove()
    #     unbind()
    # ) unless isBlank collection
    node.appendChild(textNode)

  addChildNode = (node, content, collection) ->
    child = html(content)
    addChildTemplate.call(@, node, child, collection)

  addChildTemplate = (node, child, collection) ->
    @children.push(child)
    domRemove = removeChildDom(node, child.dom)
    childRemove = removeChild(@children, child)
    unbind = collection.bind(
      remove: (item) ->
        if item is child.collectionItem
          domRemove()
          childRemove()
          unbind()
    ) unless isBlank collection
    node.appendChild child.dom

  applyRest = (node, rest, collection) ->
    _.each rest, (arg) =>
      switch
        when isHtml(arg)
          addChildTemplate.call(@, node, arg, collection)
        when isCollection(arg)
          applyItem = (itemFunc) =>
            (item) => applyRest.call(@, node, [itemFunc(item)], arg)
          arg.bind(add: applyItem(arg.iterator))
          arg.each applyItem((item) -> item)

        when isBlank(arg) then null
        when _.isArray(arg) and _.isArray(_.first(arg))
          applyRest.call(@, node, arg)
        when _.isArray(arg) and _.isString(_.first(arg))
          addChildNode.call(@, node, arg, collection)
        else addTextNode(node, arg, collection)

  tagSplitter = /([^\s\.\#]+)(?:\#([^\s\.\#]+))?(?:\.([^\s\#]+))?/

  splitTag = (tagName) ->
    [__, tagName, id, classnames] = tagName.match tagSplitter
    [tagName, id, (classnames.split(".") if classnames)]

  events =
    ("click focus blur dblclick change mousedown mousemove mouseout " +
     "mouseover mouseup resize scroll select submit load unload").split(" ")

  updateNodeClassName = (node) ->
    (classes) -> updateClassName(node, classes)

  updateClassName = (node, classes) ->
    node.className = classes.join(" ")

  updateNodeAttribute = (node, name) ->
    (attr) -> updateAttribute(node, name, attr)

  updateAttribute = (node, name, attr) ->
    switch name
      when 'checked'
        checked = !!attr
        if checked then node.setAttribute(name, attr)
        else node.removeAttribute(name)
        node.checked = checked
      else
        node.setAttribute(name, attr)

  applyAttributes = (node, id, classes, attributes) ->
    attributes['id'] = id if id
    attributes['classes'] = classes if classes
    if (classname = attributes['class'])
      attributes['classes'] ||= []
      attributes['classes'].push classname
    _.each attributes, (attr, name) ->
      switch
        when name is 'classes'
          updateClassName(node,
            if isProperty(attr)
              attr(updateNodeClassName(node))
              attr()
            else attr
          )
        when name is 'style'
          _.each attr, (style, property) ->
            node.style.setProperty(property, style)
        when _.include(events, name)
          attr(node)
        else
          updateAttribute(node, name,
            if isProperty(attr)
              attr(updateNodeAttribute(node, name))
              attr()
            else attr
          )

  getAttributes = (template) ->
    rest = _.rest(template)
    next = _.first(rest)
    if _.isObject(next) and !_.isArray(next) and !_.isFunction(next) and !isCollection(next)
      [next, _.rest(rest)]
    else
      [{}, rest]

  Template = ->
  Template.create = (template, options) ->
    options = options || {}

    assert _.isArray(template), "Invalid Template"

    tagName = _.first(template)

    assert _.isString(tagName), "Invalid Template"

    [tagName, id, classes] = splitTag(tagName)
    [attributes, rest] = getAttributes(template)

    children = []

    collectionItem = options.collectionItem
    node = document.createElement(tagName)

    _.extend @,
      __type__: Template
      dom: node
      children: children
      collectionItem: collectionItem

    applyAttributes.call(@, node, id, classes, attributes)
    applyRest.call(@, node, rest)

    @

  html = creator(Template)
  isHtml = isTypeFunc(Template)

  #- Export ------------------------------------------------
  _.extend Gunray,
    isProperty: isProperty
    isObject: isObject
    isCollection: isCollection
    isHtml: isHtml
    html: html
    property: property
    object: object
    collection: collection

  global.Gunray = Gunray

)(this, _)
