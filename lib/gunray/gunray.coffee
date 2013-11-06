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
        when !isProperty(val) and _.isFunction(val)
          bindings.push(val)
          -> _.remove bindings, (x) -> x is val
        when isBlank(val)
          value
        else
          old = value
          value = val
          debug "property changed", value, bindings
          _.each bindings, (obs) -> obs(value, old)
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
            binding.callback(item, event, previous)
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

    collectionHtml = =>
      arg = _.first arguments
      makeHtml = (func) =>
        (item) =>
          html(func(item), collection: @, item: item)
      switch
        when _.isFunction(arg)
          map makeHtml(arg)
        when _.isObject(arg)
          _.tap property([]), (ret) ->
            selectedItem (item) -> ret(makeHtml(arg.selected)(item))

    reduce = (memo, func) -> _.reduce(data, func, memo)

    find = (matchFunc) ->
      ret = null
      each (x) ->
        return unless matchFunc(x)
        ret = x
        false
      ret

    selectedIndex = property(-1)
    selectedItem = property()

    selectedItem (value, previous) =>
      trigger(value, 'select', value, previous)

    selectedIndex (idx) ->
      selectedItem(atIndex(idx))

    selected = ->
      argument = _.first arguments
      switch
        when isBlank argument
          selectedItem()
        when _.isFunction argument
          selectedItem (item) ->
            argument(item, selectedIndex())
        when idx = _.indexOf data, _.first(arguments)
          selectedIndex idx

    selectAt = (index) ->
      selectedIndex(index)

    _.extend @,
      __type__: Collection
      at: atIndex
      add: addItem
      remove: removeItem
      removeAt: removeIndex
      bind: bind
      find: find
      iterator: iterator
      trigger: trigger
      first: -> _.first(data)
      rest: -> _.rest(data)
      last: -> _.last(data)
      length: length
      each: each
      map: map
      html: collectionHtml
      reduce: reduce
      selectAt: selectAt
      selectedIndex: selectedIndex
      selected: selected

    @

  collection = creator(Collection)
  isCollection = isColl = isTypeFunc(Collection)

  #- Computed ----------------------------------------------
  Computed = ->
  Computed.create = ->
    properties = Array::slice.call(arguments)
    func = properties.pop()

    bindings = []

    _.map properties, (prop) ->
      switch
        when isCollection(prop)
          prop.bind -> callBindings()
        when isProperty(prop)
          prop -> callBindings()

    callBindings = _.debounce(->
      _.map bindings, (binding) -> binding getComputed()
    , 1)

    propertyValues = ->
      _.map properties, (x) ->
        if isProperty(x) then x.call()
        else x

    getComputed = =>
      func.apply @, propertyValues()

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
    node.data = toString(value)

  updateItem = (node, name, prop, updateFunc) ->
    updateFunc(node, name,
      if isProperty(prop) or isComputed(prop)
        prop(_.curry(updateFunc)(node, name))
        prop()
      else prop
    )

  addTextNode = (node, content) ->
    textNode = document.createTextNode()
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
    bindChild.apply(@, arguments) unless isBlank(coll)
    unless isBlank index and
           index <= node.childNodes.length and
           sibling = node.childNodes[index]
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
      if (event is 'remove' and item is child.__context__) or
         (event is 'select' and _.last(arguments) is child.__context__)
        unbindAndRemove()
    unbind = coll.bind(bindArg)

  applyRest = (node, rest, coll) ->
    _.each rest, (arg) =>
      switch
        when isHtml(arg)
          addChildTemplate.call(@, node, arg, coll, 'remove')
        when isCollection(arg)
          applyItem = (itemFunc) =>
            (item) => applyRest.call(@, node, [itemFunc(item)], arg)
          arg.bind(add: applyItem(arg.iterator))
          arg.each applyItem((item) -> item)
        when _.isArray(arg) and _.isArray(_.first(arg))
          applyRest.call(@, node, arg)
        when _.isArray(arg)
          addChildNode.call(@, node, arg)
        when isProperty(arg) and (child = arg()) and _.isArray(child)
          index = node.childNodes.length
          updateFunc = (updated) =>
            addChildTemplate.call(
              @, node, updated, updated.__collection__, 'select', index
            )
          arg updateFunc
          updateFunc(child) unless isBlank _.first(child)
        else addTextNode.call(@, node, arg)

  tagSplitter = /([^\s\.\#]*)(?:\#([^\s\.\#]+))?(?:\.([^\s\#]+))?/

  splitTag = (tagName) ->
    [__, tagName, id, classnames] = tagName.match tagSplitter
    [tagName or 'div', id, (classnames.split(".") if classnames)]

  events =
    ("click focus blur dblclick change mousedown mousemove mouseout " +
     "mouseover mouseup resize scroll select submit load unload").split(" ")

  applyAttributes = (node, id, classes, attributes) ->
    attributes['id'] = id if id
    attributes['classes'] = classes if classes
    if (classname = attributes['class'])
      attributes['classes'] ||= []
      attributes['classes'].push classname
    _.each attributes, (attr, name) ->
      switch
        when name is 'classes'
          updateItem(node, 'className', attr, updateClassName)
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

  isTag = (node, tagName) ->
    !isBlank(node) and
    !isBlank(tagName) and
    node.tagName.toLowerCase() is tagName.toLowerCase()

  findOrCreateDom = (id, tagName) ->
    ret = document.getElementById(id)
    if isBlank(ret) or !isTag(ret, tagName)
      document.createElement(tagName)
    else ret

  Template = ->
  Template.create = (template, options) ->
    options = options || {}

    assert _.isArray(template), "Invalid Template"

    tagName = _.first(template)

    assert _.isString(tagName), "Invalid Template"

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

  html = creator(Template)
  isHtml = isTypeFunc(Template)

  #- Router ------------------------------------------------
  path = property()

  baseRoute = null

  Route = ->
    _.extend @,
      handlers: []
      route: Route.create

  parseRouteCreateArgs = (args) ->
    [name, handler] = args
    last = _.last(args)
    [coll, nested] =
      switch
        when args.length is 3 and isCollection last
          [last, null]
        when args.length is 3 and _.isFunction last
          [null, last]
        when args.length is 4
          [args[2], last]
        else [null, null]
    [name, handler, coll, nested]

  Route.create = ->
    [name, handler, coll, nested] =
      parseRouteCreateArgs(arguments)
    @handlers.push
      name: name
      handler: handler
      collection: coll
      subroute: nested.apply new Route() unless isBlank nested
    @

  Router =
    map: (func) -> baseRoute = func.apply(new Route())
    path: -> path()
    reset: -> baseRoute = null

  History = ->
  History.create = (options) ->
    @location = options.location || window.location

    _.extend Router, history: @

    _.extend @,
      navigate: (url) ->
        @location.replace url
        @checkUrl()
      checkUrl: ->
        path @location.pathname.replace(/^\//,'')
        parts = path().split('/')
        _.reduce parts, (current, part) ->
          return null if isBlank current
          ret = current
          _.each current.handlers, (handler) ->
            if matches = handler.name.match /^:([a-zA-Z0-9]+)$/
              field = _.last matches
              item = handler.collection.find (x) ->
                x.get(field) is parseInt(part) or
                x.get(field) is part
              return if isBlank item
              handler.handler(part, item)
            else
              return unless part is handler.name
              ret = handler.subroute
              handler.handler(part)
          ret
        , baseRoute
    @

  history = creator(History)

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
    router: Router
    route: Route.create
    history: history

  global.Gunray = Gunray

)(this, _)
