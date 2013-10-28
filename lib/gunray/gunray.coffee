((global, _) ->

  #- Setup -------------------------------------------------
  Gunray = {}

  toString = (x) -> "" + x
  isBlank = (val) -> _.isUndefined(val) or _.isNull(val)

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
  debug = -> if DEBUG then console.log.apply(global, arguments)

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
          debug "property changed", value, bindings
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
      debug "binding: ", self, bindings, arguments
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
      debug "triggering: ", self, bindings, arguments
      _.each _.clone(bindings), (binding) ->
        if binding.event is event or binding.event is 'all'
          unless isBlank(binding.property)
            binding.callback(
              item.get(binding.property), item, event, previous
            ) unless isBlank item.prop(binding.property)
          else
            binding.callback(item, event)
      triggerUpstream(self, arguments)

  triggerUpstream = (item, args) ->
    if hasUpstream(item)
      item.collection().trigger.apply(item, args)

  hasUpstream = (item) ->
    isObject(item) and
    _.isFunction(item.collection) and
    isCollection(item.collection())

  #- Object ------------------------------------------------
  Obj = ->
  Obj.create = ->
    input = _.first(arguments)
    data = _.reduce input, (coll, value, key) ->
      switch
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
            assert(
              isCollection(coll),
              "Tried to use index access on a non-collection"
            )
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
      get: getValue
      set: setValue
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

    makeCollectionItem = (item, index) =>
      retval =
        switch
          when isObject(item)   then item
          when isHtml(item)     then item
          when _.isObject(item) then object(item)
          when _.isArray(item)  then collection(item)
          else  property(item)
      retval.index = property(index)
      retval.collection = property(@)
      retval

    data = _.map arg, makeCollectionItem

    options = _.first(_.rest(arguments)) || {}
    bindings =  options.bindings || []

    bind = bindFunc(@, bindings)
    trigger = triggerFunc(@, bindings)
    iterator = options.iterator || (x) -> x

    length = -> data.length

    addItem = (item) ->
      item = makeCollectionItem(item, data.length)
      data.push item
      trigger(item, 'add', item, null)

    removeIndex = (index) ->
      item = atIndex(index)
      data.splice index, 1
      _.each data, (item) ->
        item.index _.indexOf(data, item)
      trigger(item, 'remove', item, null)

    removeItem = (item) -> removeIndex _.indexOf(data, item)

    atIndex = (i) -> _.first _.at(data, i)
    each = (func) -> collection _.each(data, func)

    map = (func) ->
      collection _.map(data, func), bindings: bindings, iterator: func

    mapHtml = (func) =>
      map (item) => html(func(item), collection: @, item: item)

    reduce = (memo, func) -> collection _.reduce(data, func, memo)

    _.extend @,
      __type__: Collection
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
      each: each
      map: map
      html: mapHtml
      inject: reduce
      reduce: reduce

    @

  collection = creator(Collection)
  isCollection = isColl = isTypeFunc(Collection)

  #- Computed ----------------------------------------------
  Computed = ->
  Computed.create = ->
    bound = Array::slice.call(arguments)
    func = bound.pop()

    assert (_.map bound, (x) -> isProperty(x)), 'must bind on properties'

    bindings = []

    _.map bound, (x) ->
      x -> callBindings()

    callBindings = _.debounce(->
      _.map bindings, (binding) -> binding getComputed()
    , 1)

    getComputed = => func.apply @, _.map bound, (x) -> x.call()

    retval = (binding) ->
      unless isBlank binding
        bindings.push(binding)
      else
        getComputed()

    _.extend retval,
      __type__: Computed

    retval

  computed = creator(Computed)
  isComputed = isTypeFunc(Computed)

  #- Template ----------------------------------------------
  removeChildDom = (node, child) ->
    -> node.removeChild(child)

  removeChild = (children, child) ->
    -> children.slice _.indexOf(children, child), 1

  addTextNode = (node, content, coll) ->
    textNode =
      document.createTextNode(
        switch
          when isProperty(content) or isComputed(content)
            content (value) ->
              textNode.data = toString(value)
            content()
          else toString(content)
      )
    childRemove = removeChild(@children, content)
    node.appendChild(textNode)

  addChildNode = (node, content, coll) ->
    child = html(content)
    addChildTemplate.call(@, node, child, coll)

  addChildTemplate = (node, child, coll) ->
    @children.push(child)
    domRemove = removeChildDom(node, child.dom)
    childRemove = removeChild(@children, child)
    unbind = coll.bind(
      remove: (item) ->
        if item is child.__context__
          domRemove()
          childRemove()
          unbind()
    ) unless isBlank coll
    node.appendChild child.dom

  applyRest = (node, rest, coll) ->
    _.each rest, (arg) =>
      switch
        when isHtml(arg)
          addChildTemplate.call(@, node, arg, coll)
        when isCollection(arg)
          applyItem = (itemFunc) =>
            (item) => applyRest.call(@, node, [itemFunc(item)], arg)
          arg.bind(add: applyItem(arg.iterator))
          arg.each applyItem((item) -> item)
        when _.isArray(arg) and _.isArray(_.first(arg))
          applyRest.call(@, node, arg)
        when _.isArray(arg)
          addChildNode.call(@, node, arg, coll)
        else addTextNode.call(@, node, arg, coll)

  tagSplitter = /([^\s\.\#]+)(?:\#([^\s\.\#]+))?(?:\.([^\s\#]+))?/

  splitTag = (tagName) ->
    [__, tagName, id, classnames] = tagName.match tagSplitter
    [tagName, id, (classnames.split(".") if classnames)]

  events =
    ("click focus blur dblclick change mousedown mousemove mouseout " +
     "mouseover mouseup resize scroll select submit load unload").split(" ")

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

  updateItem = (node, name, prop, updateFunc) ->
    updateFunc(node, name,
      if isProperty(prop) or isComputed(prop)
        prop(_.curry(updateFunc)(node, name))
        prop()
      else prop
    )

  applyAttributes = (node, id, classes, attributes) ->
    attributes['id'] = id if id
    attributes['classes'] = classes if classes
    if (classname = attributes['class'])
      attributes['classes'] ||= []
      attributes['classes'].push classname
    _.each attributes, (attr, name) ->
      switch
        when name is 'classes'
          updateItem(node, 'classes', attr, updateClassName)
        when name is 'style'
          _.each attr, (style, property) ->
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
    !isCollection(arg)

  Template = ->
  Template.create = (template, options) ->
    options = options || {}

    assert _.isArray(template), "Invalid Template"

    tagName = _.first(template)

    assert _.isString(tagName), "Invalid Template"

    [tagName, id, classes] = splitTag(tagName)
    [attributes, rest] = getAttributes(template)

    children = []

    node = document.createElement(tagName)

    _.extend @,
      __type__: Template
      __context__: options.item
      dom: node
      children: children

    applyAttributes.call(@, node, id, classes, attributes)
    applyRest.call(@, node, rest, options.collection)

    @

  html = creator(Template)
  isHtml = isTypeFunc(Template)

  #- Export ------------------------------------------------
  _.extend Gunray,
    isProperty: isProperty
    isObject: isObject
    isCollection: isCollection
    isHtml: isHtml
    isComputed: isComputed
    html: html
    property: property
    object: object
    collection: collection
    computed: computed
  global.Gunray = Gunray

)(this, _)
