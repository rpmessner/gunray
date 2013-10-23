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
    observers = []
    value = _.first(arguments)
    returnFunc = (val) ->
      switch
        when _.isFunction(val)
          observers.push(val)
          -> _.remove observers, (x) -> x is val
        when isBlank(val)
          value
        else
          value = val
          _.each observers, (obs) -> obs(value)
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
      switch
        when _.isFunction(first) then bindings.push(event: 'all', callback: first)
        when _.isObject(first)
          _.each first, (func, event) ->
            [event, prop] = event.split(":")
            bindings.push(event: event, callback: func, property: prop)

  triggerFunc = (self, bindings) ->
    (item, event, value, previous) ->
      _.each bindings, (binding) ->
        if binding.event is event or binding.event is 'all'
          unless isBlank(binding.property)
            binding.callback(item.get(binding.property), item, event, previous) unless isBlank(item.prop(binding.property))
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
      switch
        when _.isString path
          prop = getProperty(path)
          previous = prop()
          return if previous is value
          prop(value)
          trigger(@, 'update', value, previous)
        when _.isObject key then null

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
      value: getValue
      val: getValue
      get: getValue
      set: setValue
      trigger: trigger
      property: getProperty
      prop: getProperty
      bind: bind
      on: bind

    @

  object = creator(Obj)
  isObj = isObject = isTypeFunc(Obj)

  #- Collection --------------------------------------------
  Collection = ->
  Collection.create = ->
    arg = _.first(arguments)

    assert _.isArray(arg), "Invalid Argument"

    makeCollectionItem = (item) =>
      retval =
        switch
          when isObject(item) then item
          when _.isObject(item) then object(item)
          when _.isArray(item) then collection(item)
          else  property(item)
      retval.collection = => @
      retval

    data = _.map arg, (datum) -> makeCollectionItem(datum)

    bindings = _.first(_.rest(arguments)) || []

    bind = bindFunc(@, bindings)
    trigger = triggerFunc(@, bindings)

    length = -> data.length

    addItem = (item) ->
      item = makeCollectionItem(item)
      data.push item
      trigger(item, 'add', item, null)

    removeItem = (index) ->
      item = atIndex(index)
      data.splice index, 1
      trigger(item, 'remove', item, null)

    atIndex = (i) -> _.first _.at(data, i)
    each = (func) -> collection _.each(data, func)
    map = (func) -> collection _.map(data, func), bindings
    reduce = (memo, func) -> collection _.reduce(data, func, memo)

    _.extend @,
      __type__: Collection
      __data__: data
      __bindings__: bindings
      at: atIndex
      add: addItem
      removeAt: removeItem
      bind: bind
      on: bind
      trigger: trigger
      first: -> _.first(data)
      rest: -> _.rest(data)
      length: length
      count: length
      size: length
      each: each
      map: map
      inject: reduce
      reduce: reduce

    @

  collection = creator(Collection)
  isCollection = isColl = isTypeFunc(Collection)

  #- Template ----------------------------------------------
  addTextNode = (node, content) ->
    textNode =
      document.createTextNode(
        switch
          when isProperty(content)
            content (value) ->
              textNode.data = toString(value)
            content()
          else toString(content)
      )
    node.appendChild(textNode)

  applyRest = (node, rest) ->
    _.each rest, (arg) =>
      switch
        when isBlank(arg) then null
        when _.isArray(arg) and _.isArray(_.first(arg))
          applyRest.call(@, node, arg)
        when _.isArray(arg) and _.isString(_.first(arg))
          child = html(arg)
          @children().push child
          node.appendChild child.dom
        else addTextNode(node, arg)

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
    if _.isObject(next) and !_.isArray(next) and !_.isFunction(next)
      [next, _.rest(rest)]
    else
      [{}, rest]

  Template = ->
  Template.create = (template) ->
    assert _.isArray(template), "Invalid Template"

    tagName = _.first(template)

    assert _.isString(tagName), "Invalid Template"

    [tagName, id, classes] = splitTag(tagName)
    [attributes, rest] = getAttributes(template)

    children = []
    node = document.createElement(tagName)

    _.extend @,
      __type__: Template
      dom: node
      children: -> children

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
