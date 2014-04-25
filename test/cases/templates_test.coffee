gunray = require 'gunray'

h = require '../helpers.coffee'
sim = require 'simulate'
sinon = require 'sinon'
_ = require 'lodash'

html = gunray.html
isHtml = gunray.isHtml

property = gunray.property
object = gunray.object
collection = gunray.collection
computed = gunray.computed

domDiv = null

QUnit.module "Gunray Template",
  setup: ->
    domDiv = document.createElement('div')
    document.body.appendChild domDiv
  teardown: ->
    document.body.removeChild domDiv
    domDiv = null

test 'creates template', 3, ->
  t = html(['p'])
  notEqual t, undefined
  notEqual t, null
  ok isHtml(t)

test 'simple', 4, ->
  h1 = html(['h1'])
  equal h1.children.length, 0
  h.equalHtml h1, '<h1></h1>'
  h1hello = html(['h1', 'hello world'])
  equal h1hello.children.length, 0
  h.equalHtml h1hello, '<h1>hello world</h1>'

test 'nested', 4, ->
  div = html(
    ['div',
    ['h1', 'Title'],
    ['p', 'Paragraph']]
  )

  equal div.children.length, 2
  h.equalHtml div, '<div><h1>Title</h1><p>Paragraph</p></div>'

  div2 = html(
    ['div',
    ['h1', 'Title'],
    ['p', 'Paragraph', ['span', 'Words']]]
  )

  equal _.last(div2.children).children.length, 1

  h.equalHtml(
    div2, '<div><h1>Title</h1><p>Paragraph<span>Words</span></p></div>'
  )

test 'arrays for nesting is ok', 4, ->
  template = html(['div', [['h1', 'Title'], ['p', 'Paragraph']]])
  h.equalHtml template, '<div><h1>Title</h1><p>Paragraph</p></div>'
  equal template.children.length, 2

  template = html(['div', [['h1', 'Title']], ['p', 'Paragraph']])
  h.equalHtml template, '<div><h1>Title</h1><p>Paragraph</p></div>'
  equal template.children.length, 2

test 'can use id selector', 1, ->
  h.equalHtml html(['div#frame']), '<div id="frame"></div>'

test 'can use id attribute', 1, ->
  h.equalHtml html(['div', id: 'frame']), '<div id="frame"></div>'

test 'can use class selector', 2, ->
  h.equalHtml html(['div.foo']), '<div class="foo"></div>'
  h.equalHtml html(['div.foo.bar']), '<div class="foo bar"></div>'

test 'can use class attribute', 1, ->
  h.equalHtml(
    html(
      ['div', class: 'panel']
    ), '<div class="panel"></div>', 'can use class attribute'
  )

test 'can combine id and class selectors', 2, ->
  h.equalHtml html(['div#baz.foo']), '<div id="baz" class="foo"></div>'
  h.equalHtml html(['div#baz.foo.bar']), '<div id="baz" class="foo bar"></div>'

test 'default tag type is div', ->
  h.equalHtml html(['#baz']), '<div id="baz"></div>', 'default tag type is div'

test 'can set properties', 2, ->
  a = html(['a', href: 'http://google.com']).dom
  equal a.href, 'http://google.com/'

  h.equalHtml(
    html(
      ['input', name: 'yes', type: 'checkbox']
    ), '<input name="yes" type="checkbox">'
  )

test 'registers event handlers', 2, ->
  onClick = sinon.spy()
  p = html(['p', click: onClick, 'something']).dom
  sim.click p
  equal onClick.called, true
  equal onClick.calledWith(p), true

test 'sets styles', 1, ->
  div = html(['div', style: {color: 'red'}]).dom
  equal div.style.color, 'red'

test 'property styles', 2, ->
  color = property('red')
  div = html(['div', style: {color: color}]).dom
  equal div.style.color, 'red'
  color('blue')
  equal div.style.color, 'blue'

asyncTest 'computed property styles', 5, ->
  bool1 = property(true)
  bool2 = property(false)
  comp = computed bool1, bool2, (a, b) ->
    switch
      when a and not b then 'red'
      when not a and not b then 'green'
      when a and b then 'blue'
  counter = 0

  comp -> counter += 1

  div = html(['div', style: {color: comp}]).dom

  equal div.style.color, 'red', 'equals computed value'

  bool1(false)

  h.waitForSync ->
    equal counter, 1, 'calls binding'
    equal div.style.color, 'green', 'equals computed value after update'

    bool1(true); bool2(true)
    h.waitForSync ->
      equal counter, 2, 'calls binding once'
      equal div.style.color, 'blue', 'equals computed value after update'
      start()

test 'sets data attributes', 1, ->
  div = html(['div', 'data-value': 5]).dom
  equal div.getAttribute('data-value'), '5'

test 'boolean, number, date, regex get to-string\'ed', 1, ->
  e = html(['p', true, false, 4, new Date('Mon Jan 15 2001'), /hello/]).dom
  ok e.outerHTML.match(
    "<p>truefalse4Mon Jan 15 2001 00:00:00 [0-9A-Z- ()]+/hello/"
  )

test 'observable content', ->
  title = property()
  title 'initial content'
  h1 = html(['h1', title])
  h.equalHtml h1, '<h1>initial content</h1>'
  title 'updated content'
  h.equalHtml h1, '<h1>updated content</h1>'

test 'observable property', ->
  checked = property()
  checked true
  checkbox = html(['input', type: 'checkbox', checked: checked]).dom
  equal checkbox.checked, true
  checked false
  equal checkbox.checked, false

test 'observable object property', ->
  obj = object(name: 'Karen')
  div = html(['div', obj.prop('name')])
  h.equalHtml div, "<div>Karen</div>"

  obj.set('name', 'Louis')
  h.equalHtml div, "<div>Louis</div>"

test 'observable selected', ->
  coll = collection(['foo','bar','fizz','buzz'])
  content = html(
    ["#content",
    "!!",
    coll.html(selected: (selected) -> ["h1", selected, selected.index])
    "!!"]
  )
  h.equalHtml content, '<div id="content">!!!!</div>'
  coll.selectAt(0)
  h.equalHtml content, '<div id="content">!!<h1>foo0</h1>!!</div>'
  # coll.selectAt(1)
  # h.equalHtml content, '<div id="content">!!<h1>bar1</h1>!!</div>'

test 'observable collection properties', 2, ->
  coll = collection(['foo','bar','fizz','buzz'])
  ul = html(
    ['ul', coll.html((obj) -> ['li', obj.index, obj])]
  )

  h.equalHtml(
    ul, "<ul><li>0foo</li><li>1bar</li><li>2fizz</li><li>3buzz</li></ul>"
  )

  coll.removeAt(1)

  h.equalHtml(
    ul, "<ul><li>0foo</li><li>1fizz</li><li>2buzz</li></ul>"
  )

test 'observable collection objects', ->
  coll = collection([name: 'Karen'])

  ul = html(
    ['ul', coll.html((obj) -> ['li', obj.index, obj.prop("name")])]
  )

  h.equalHtml ul, "<ul><li>0Karen</li></ul>"
  coll.at(0).set('name', 'Louis')
  h.equalHtml ul, "<ul><li>0Louis</li></ul>"
  coll.add(name: 'Keith')
  h.equalHtml ul, "<ul><li>0Louis</li><li>1Keith</li></ul>"
  coll.add(name: 'Richard')
  h.equalHtml ul, "<ul><li>0Louis</li><li>1Keith</li><li>2Richard</li></ul>"
  coll.removeAt(1)
  h.equalHtml ul, "<ul><li>0Louis</li><li>1Richard</li></ul>"

asyncTest 'computed properties', ->
  [p1, p2] = _.times 2, (n) -> property(n)
  comp = computed(p1, p2, (a, b) -> "" + a + b)
  p = html(['p', {}, comp])
  h.equalHtml p, '<p>01</p>', 'outputs computed property to html'
  p1(1)
  h.waitForSync ->
    h.equalHtml p, '<p>11</p>', 'outputs computed property to html'
    start()

test 'template uses existing dom ids', ->
  domDiv.id = 'foo'

  div = html(['#foo', ['p', 'hello page']])
  equal domDiv.innerHTML, div.dom.innerHTML

test 'does not use existing dom ids if tags do not match', ->
  domDiv.id = 'foo'

  div = html(['p#foo', ['p', 'hello page']])
  notEqual domDiv.innerHTML, div.dom.innerHTML
