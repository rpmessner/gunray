((g, m, o, p, e, u, _) ->

  t = null

  Collection = ->
  Collection.create = ->
    t ||= require('./template.coffee')
    arg = _.first(arguments)

    u.assert _.isArray(arg), "Invalid Argument"

    makeCollectionItem = (item, index) =>
      retval =
        switch
          when o.isObject(item) then item
          when t.isHtml(item)   then item
          when _.isObject(item) then o.object(item)
          when _.isArray(item)  then o.collection(item)
          else p.property(item)
      retval.index = p.property(index)
      retval.collection = p.property(@)
      retval

    data = _.map arg, makeCollectionItem

    options = _.first(_.rest(arguments)) or {}
    bindings =  options.bindings or []

    bind = e.bindFunc(@, bindings)
    trigger = e.triggerFunc(@, bindings)
    iterator = options.iterator or (x) -> x

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
          t.html(func(item), collection: @, item: item)
      switch
        when _.isFunction(arg)
          map makeHtml(arg)
        when _.isObject(arg)
          ret = p.property([])
          selectedItem(
            (item) ->
              ret(makeHtml(arg.selected)(item))
          )
          ret

    reduce = (memo, func) -> _.reduce(data, func, memo)

    find = (matchFunc) ->
      ret = null
      each (x) ->
        return unless matchFunc(x)
        ret = x
        false
      ret

    selectedIndex = p.property(-1)
    selectedItem = p.property()

    selectedItem (value, previous) ->
      trigger(value, 'select', value, previous)

    selectedIndex (idx) ->
      selectedItem(atIndex(idx))

    selected = ->
      argument = _.first arguments
      switch
        when u.isBlank argument
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

  collection = u.creator(Collection)
  isCollection = u.isTypeFunc(Collection)

  m.exports =
    collection: collection
    isCollection: isCollection

)(@, \
  module, \
  require('./object.coffee'), \
  require('./property.coffee'), \
  require('./events.coffee'), \
  require('./utils.coffee'), \
  require('lodash'))
