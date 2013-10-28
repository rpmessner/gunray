(function() {
  (function(global, _) {
    var Collection, Computed, DEBUG, Gunray, Obj, Property, Template, addChildNode, addChildTemplate, addTextNode, applyAttributes, applyRest, assert, bindFunc, collection, computed, creator, debug, events, findOrCreateDom, getAttributes, hasUpstream, html, isAttributes, isBlank, isColl, isCollection, isComputed, isHtml, isObj, isObject, isProperty, isTag, isTypeFunc, object, property, removeChild, removeChildDom, splitTag, tagSplitter, toString, triggerFunc, triggerUpstream, updateAttribute, updateClassName, updateItem, updateStyle;
    Gunray = {};
    toString = function(x) {
      return "" + x;
    };
    isBlank = function(val) {
      return _.isUndefined(val) || _.isNull(val);
    };
    creator = function(klass) {
      return function() {
        return klass.create.apply(new klass, arguments);
      };
    };
    isTypeFunc = function(type) {
      return function(object) {
        return !isBlank(object) && object.__type__ === type;
      };
    };
    assert = function(cond, msg) {
      if (_.isArray(cond)) {
        if (!_.all(cond)) {
          throw msg;
        }
      } else {
        if (!cond) {
          throw msg;
        }
      }
    };
    DEBUG = false;
    debug = function() {
      if (DEBUG) {
        return console.log.apply(global, arguments);
      }
    };
    Property = function() {};
    Property.create = function() {
      var bindings, returnFunc, value;
      bindings = [];
      value = _.first(arguments);
      returnFunc = function(val) {
        switch (false) {
          case !_.isFunction(val):
            bindings.push(val);
            return function() {
              return _.remove(bindings, function(x) {
                return x === val;
              });
            };
          case !isBlank(val):
            return value;
          default:
            value = val;
            debug("property changed", value, bindings);
            _.each(bindings, function(obs) {
              return obs(value);
            });
            return value;
        }
      };
      _.extend(returnFunc, {
        __type__: Property
      });
      return returnFunc;
    };
    property = creator(Property);
    isProperty = isTypeFunc(Property);
    bindFunc = function(self, bindings) {
      return function() {
        var bound, first;
        debug("binding: ", self, bindings, arguments);
        first = _.first(arguments);
        bound = [];
        switch (false) {
          case !_.isFunction(first):
            bindings.push({
              event: 'all',
              callback: first
            });
            bound.push(_.last(bindings));
            break;
          case !_.isObject(first):
            _.each(first, function(func, event) {
              var prop, _ref;
              _ref = event.split(":"), event = _ref[0], prop = _ref[1];
              bindings.push({
                event: event,
                callback: func,
                property: prop
              });
              return bound.push(_.last(bindings));
            });
        }
        return function() {
          return _.remove(bindings, function(x) {
            return _.include(bound, x);
          });
        };
      };
    };
    triggerFunc = function(self, bindings) {
      return function(item, event, value, previous) {
        debug("triggering: ", self, bindings, arguments);
        _.each(_.clone(bindings), function(binding) {
          if (binding.event === event || binding.event === 'all') {
            if (!isBlank(binding.property)) {
              if (!isBlank(item.prop(binding.property))) {
                return binding.callback(item.get(binding.property), item, event, previous);
              }
            } else {
              return binding.callback(item, event);
            }
          }
        });
        return triggerUpstream(self, arguments);
      };
    };
    triggerUpstream = function(item, args) {
      if (hasUpstream(item)) {
        return item.collection().trigger.apply(item, args);
      }
    };
    hasUpstream = function(item) {
      return isObject(item) && _.isFunction(item.collection) && isCollection(item.collection());
    };
    Obj = function() {};
    Obj.create = function() {
      var bind, bindings, data, getProperty, getValue, input, setValue, trigger;
      input = _.first(arguments);
      data = _.reduce(input, function(coll, value, key) {
        var obj;
        switch (false) {
          case !_.isArray(value):
            coll[key] = collection(value);
            break;
          case !_.isObject(value):
            obj = object(value);
            coll[key] = obj;
            break;
          default:
            coll[key] = property();
            coll[key](value);
        }
        return coll;
      }, {});
      setValue = function() {
        var path, set, value,
          _this = this;
        path = arguments[0], value = arguments[1];
        set = function(attribute, value) {
          var previous, prop;
          prop = getProperty(attribute);
          previous = prop();
          if (previous === value) {
            return;
          }
          prop(value);
          return trigger(_this, 'update', value, previous);
        };
        switch (false) {
          case !_.isString(path):
            return set(path, value);
          case !_.isObject(path):
            return _.each(path, function(value, key) {
              return set(key, value);
            });
        }
      };
      getValue = function(key) {
        return getProperty(key)();
      };
      getProperty = function(path) {
        return _.reduce(path.split("."), function(coll, prop) {
          var matches;
          switch (false) {
            case !(matches = prop.match(/^at\((\d)\)$/)):
              assert(isCollection(coll), "Tried to use index access on a non-collection");
              return coll.at(_.last(matches));
            case !_.isFunction(coll.prop):
              return coll.prop(prop);
            case !_.isObject(coll):
              return coll[prop];
            default:
              return coll;
          }
        }, data);
      };
      bindings = [];
      bind = bindFunc(this, bindings);
      trigger = triggerFunc(this, bindings);
      _.extend(this, {
        __type__: Obj,
        get: getValue,
        set: setValue,
        prop: getProperty,
        bind: bind
      });
      return this;
    };
    object = creator(Obj);
    isObj = isObject = isTypeFunc(Obj);
    Collection = function() {};
    Collection.create = function() {
      var addItem, arg, atIndex, bind, bindings, data, each, iterator, length, makeCollectionItem, map, mapHtml, options, reduce, removeIndex, removeItem, trigger,
        _this = this;
      arg = _.first(arguments);
      assert(_.isArray(arg), "Invalid Argument");
      makeCollectionItem = function(item, index) {
        var retval;
        retval = (function() {
          switch (false) {
            case !isObject(item):
              return item;
            case !isHtml(item):
              return item;
            case !_.isObject(item):
              return object(item);
            case !_.isArray(item):
              return collection(item);
            default:
              return property(item);
          }
        })();
        retval.index = property(index);
        retval.collection = property(_this);
        return retval;
      };
      data = _.map(arg, makeCollectionItem);
      options = _.first(_.rest(arguments)) || {};
      bindings = options.bindings || [];
      bind = bindFunc(this, bindings);
      trigger = triggerFunc(this, bindings);
      iterator = options.iterator || function(x) {
        return x;
      };
      length = function() {
        return data.length;
      };
      addItem = function(item) {
        item = makeCollectionItem(item, data.length);
        data.push(item);
        return trigger(item, 'add', item, null);
      };
      removeIndex = function(index) {
        var item;
        item = atIndex(index);
        data.splice(index, 1);
        _.each(data, function(item) {
          return item.index(_.indexOf(data, item));
        });
        return trigger(item, 'remove', item, null);
      };
      removeItem = function(item) {
        return removeIndex(_.indexOf(data, item));
      };
      atIndex = function(i) {
        return _.first(_.at(data, i));
      };
      each = function(func) {
        return collection(_.each(data, func));
      };
      map = function(func) {
        return collection(_.map(data, func), {
          bindings: bindings,
          iterator: func
        });
      };
      mapHtml = function(func) {
        return map(function(item) {
          return html(func(item), {
            collection: _this,
            item: item
          });
        });
      };
      reduce = function(memo, func) {
        return collection(_.reduce(data, func, memo));
      };
      _.extend(this, {
        __type__: Collection,
        at: atIndex,
        add: addItem,
        remove: removeItem,
        removeAt: removeIndex,
        bind: bind,
        iterator: iterator,
        trigger: trigger,
        first: function() {
          return _.first(data);
        },
        rest: function() {
          return _.rest(data);
        },
        last: function() {
          return _.last(data);
        },
        length: length,
        each: each,
        map: map,
        html: mapHtml,
        inject: reduce,
        reduce: reduce
      });
      return this;
    };
    collection = creator(Collection);
    isCollection = isColl = isTypeFunc(Collection);
    Computed = function() {};
    Computed.create = function() {
      var bindings, bound, callBindings, func, getComputed, retval,
        _this = this;
      bound = Array.prototype.slice.call(arguments);
      func = bound.pop();
      assert(_.map(bound, function(x) {
        return isProperty(x);
      }), 'must bind on properties');
      bindings = [];
      _.map(bound, function(x) {
        return x(function() {
          return callBindings();
        });
      });
      callBindings = _.debounce(function() {
        return _.map(bindings, function(binding) {
          return binding(getComputed());
        });
      }, 1);
      getComputed = function() {
        return func.apply(_this, _.map(bound, function(x) {
          return x.call();
        }));
      };
      retval = function(binding) {
        if (!isBlank(binding)) {
          return bindings.push(binding);
        } else {
          return getComputed();
        }
      };
      _.extend(retval, {
        __type__: Computed
      });
      return retval;
    };
    computed = creator(Computed);
    isComputed = isTypeFunc(Computed);
    removeChildDom = function(node, child) {
      return function() {
        return node.removeChild(child);
      };
    };
    removeChild = function(children, child) {
      return function() {
        return children.slice(_.indexOf(children, child), 1);
      };
    };
    addTextNode = function(node, content, coll) {
      var childRemove, textNode;
      textNode = document.createTextNode((function() {
        switch (false) {
          case !(isProperty(content) || isComputed(content)):
            content(function(value) {
              return textNode.data = toString(value);
            });
            return content();
          default:
            return toString(content);
        }
      })());
      childRemove = removeChild(this.children, content);
      return node.appendChild(textNode);
    };
    addChildNode = function(node, content, coll) {
      var child;
      child = html(content);
      return addChildTemplate.call(this, node, child, coll);
    };
    addChildTemplate = function(node, child, coll) {
      var childRemove, domRemove, unbind;
      this.children.push(child);
      domRemove = removeChildDom(node, child.dom);
      childRemove = removeChild(this.children, child);
      if (!isBlank(coll)) {
        unbind = coll.bind({
          remove: function(item) {
            if (item === child.__context__) {
              domRemove();
              childRemove();
              return unbind();
            }
          }
        });
      }
      return node.appendChild(child.dom);
    };
    applyRest = function(node, rest, coll) {
      var _this = this;
      return _.each(rest, function(arg) {
        var applyItem;
        switch (false) {
          case !isHtml(arg):
            return addChildTemplate.call(_this, node, arg, coll);
          case !isCollection(arg):
            applyItem = function(itemFunc) {
              return function(item) {
                return applyRest.call(_this, node, [itemFunc(item)], arg);
              };
            };
            arg.bind({
              add: applyItem(arg.iterator)
            });
            return arg.each(applyItem(function(item) {
              return item;
            }));
          case !(_.isArray(arg) && _.isArray(_.first(arg))):
            return applyRest.call(_this, node, arg);
          case !_.isArray(arg):
            return addChildNode.call(_this, node, arg, coll);
          default:
            return addTextNode.call(_this, node, arg, coll);
        }
      });
    };
    tagSplitter = /([^\s\.\#]*)(?:\#([^\s\.\#]+))?(?:\.([^\s\#]+))?/;
    splitTag = function(tagName) {
      var classnames, id, __, _ref;
      _ref = tagName.match(tagSplitter), __ = _ref[0], tagName = _ref[1], id = _ref[2], classnames = _ref[3];
      return [tagName || 'div', id, (classnames ? classnames.split(".") : void 0)];
    };
    events = ("click focus blur dblclick change mousedown mousemove mouseout " + "mouseover mouseup resize scroll select submit load unload").split(" ");
    updateClassName = function(node, __, classes) {
      return node.className = classes.join(" ");
    };
    updateAttribute = function(node, name, attr) {
      var checked;
      switch (name) {
        case 'checked':
          checked = !!attr;
          if (checked) {
            node.setAttribute(name, attr);
          } else {
            node.removeAttribute(name);
          }
          return node.checked = checked;
        default:
          return node.setAttribute(name, attr);
      }
    };
    updateStyle = function(node, property, style) {
      return node.style.setProperty(property, style);
    };
    updateItem = function(node, name, prop, updateFunc) {
      return updateFunc(node, name, isProperty(prop) || isComputed(prop) ? (prop(_.curry(updateFunc)(node, name)), prop()) : prop);
    };
    applyAttributes = function(node, id, classes, attributes) {
      var classname;
      if (id) {
        attributes['id'] = id;
      }
      if (classes) {
        attributes['classes'] = classes;
      }
      if ((classname = attributes['class'])) {
        attributes['classes'] || (attributes['classes'] = []);
        attributes['classes'].push(classname);
      }
      return _.each(attributes, function(attr, name) {
        switch (false) {
          case name !== 'classes':
            return updateItem(node, 'className', attr, updateClassName);
          case name !== 'style':
            return _.each(attr, function(style, property) {
              return updateItem(node, property, style, updateStyle);
            });
          case !_.include(events, name):
            return attr(node);
          default:
            return updateItem(node, name, attr, updateAttribute);
        }
      });
    };
    getAttributes = function(template) {
      var next, rest;
      rest = _.rest(template);
      next = _.first(rest);
      if (isAttributes(next)) {
        return [next, _.rest(rest)];
      } else {
        return [{}, rest];
      }
    };
    isAttributes = function(arg) {
      return _.isObject(arg) && !_.isArray(arg) && !_.isFunction(arg) && !isCollection(arg);
    };
    isTag = function(node, tagName) {
      return !isBlank(node) && !isBlank(tagName) && node.tagName.toLowerCase() === tagName.toLowerCase();
    };
    findOrCreateDom = function(id, tagName) {
      var ret;
      ret = document.getElementById(id);
      if (isBlank(ret) || !isTag(ret, tagName)) {
        return document.createElement(tagName);
      } else {
        return ret;
      }
    };
    Template = function() {};
    Template.create = function(template, options) {
      var attributes, children, classes, id, node, rest, tagName, _ref, _ref1;
      options = options || {};
      assert(_.isArray(template), "Invalid Template");
      tagName = _.first(template);
      assert(_.isString(tagName), "Invalid Template");
      _ref = splitTag(tagName), tagName = _ref[0], id = _ref[1], classes = _ref[2];
      _ref1 = getAttributes(template), attributes = _ref1[0], rest = _ref1[1];
      children = [];
      node = findOrCreateDom(id, tagName);
      _.extend(this, {
        __type__: Template,
        __context__: options.item,
        dom: node,
        children: children
      });
      applyAttributes.call(this, node, id, classes, attributes);
      applyRest.call(this, node, rest, options.collection);
      return this;
    };
    html = creator(Template);
    isHtml = isTypeFunc(Template);
    _.extend(Gunray, {
      isProperty: isProperty,
      isObject: isObject,
      isCollection: isCollection,
      isHtml: isHtml,
      isComputed: isComputed,
      html: html,
      property: property,
      object: object,
      collection: collection,
      computed: computed
    });
    return global.Gunray = Gunray;
  })(this, _);

}).call(this);
