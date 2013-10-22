html = Gunray.html
property = Gunray.property
isHtml = Gunray.isHtml

module "Gunray Template",
  setup:  ->
  teardown: ->

test 'creates template', 3, ->
  t = html(['p'])
  notEqual t, undefined
  notEqual t, null
  ok isHtml(t)

test 'simple', 4, ->
  h1 = html(['h1'])
  equal h1.children().length, 0
  equalHtml h1, '<h1></h1>'
  h1hello = html(['h1', 'hello world'])
  equal h1hello.children().length, 0
  equalHtml h1hello, '<h1>hello world</h1>'

test 'nested', 4, ->
  div = html(['div',
        ['h1', 'Title'],
        ['p', 'Paragraph']])
  equal div.children().length, 2
  equalHtml div, '<div><h1>Title</h1><p>Paragraph</p></div>'

  div2 = html(['div',
        ['h1', 'Title'],
        ['p', 'Paragraph', ['span', 'Words']]])
  equal _.last(div2.children()).children().length, 1
  equalHtml div2, '<div><h1>Title</h1><p>Paragraph<span>Words</span></p></div>'

test 'arrays for nesting is ok', 4, ->
  template = html(['div', [['h1', 'Title'], ['p', 'Paragraph']]])
  equalHtml template, '<div><h1>Title</h1><p>Paragraph</p></div>'
  equal template.children().length, 2

  template = html(['div', [['h1', 'Title']], ['p', 'Paragraph']])
  equalHtml template, '<div><h1>Title</h1><p>Paragraph</p></div>'
  equal template.children().length, 2

test 'can use id selector', 1, ->
  equalHtml html(['div#frame']), '<div id="frame"></div>'

test 'can use id attribute', 1, ->
  equalHtml html(['div', id: 'frame']), '<div id="frame"></div>'

test 'can use class selector', 2, ->
  equalHtml html(['div.foo']), '<div class="foo"></div>'
  equalHtml html(['div.foo.bar']), '<div class="foo bar"></div>'

test 'can use class attribute', 1, ->
  equalHtml html(['div', class: 'panel']), '<div class="panel"></div>'

test 'can combine id and class selectors', 2, ->
  equalHtml html(['div#baz.foo']), '<div id="baz" class="foo"></div>'
  equalHtml html(['div#baz.foo.bar']), '<div id="baz" class="foo bar"></div>'

test 'can set properties', 2, ->
  a = html(['a', href: 'http://google.com']).dom
  equal a.href, 'http://google.com/'

  equalHtml html(['input', name: 'yes', type: 'checkbox']),
    '<input name="yes" type="checkbox">'

test 'registers event handlers', 2, ->
  onClick = sinon.spy()
  p = html(['p', click: onClick, 'something']).dom
  sim.click p
  equal onClick.called, true
  equal onClick.calledWith(p), true

test 'sets styles', 1, ->
  div = html(['div', style: {color: 'red'}]).dom
  equal div.style.color, 'red'

test 'sets data attributes', 1, ->
  div = html(['div', 'data-value': 5]).dom
  equal div.getAttribute('data-value'), '5'

test 'boolean, number, date, regex get to-string\'ed', 1, ->
  e = html(['p', true, false, 4, new Date('Mon Jan 15 2001'), /hello/]).dom
  ok e.outerHTML.match("<p>truefalse4Mon Jan 15 2001 00:00:00 [0-9A-Z- ()]+/hello/")

test 'observable content', ->
  title = property()
  title 'Welcome to HyperScript!'
  h1 = html(['h1', title])
  equalHtml h1, '<h1>Welcome to HyperScript!</h1>'
  title 'Leave, creep!'
  equalHtml h1, '<h1>Leave, creep!</h1>'

test 'observable property', ->
  checked = property()
  checked true
  checkbox = html(['input', type: 'checkbox', checked: checked]).dom
  equal checkbox.checked, true
  checked false
  equal checkbox.checked, false

# test 'observable object property', ->
#   obj = object(name: 'Karen')
#   div = html(['div', obj.val("name")])
#   equalHtml div, "<div>Karen</div>"

#   obj.set('name', 'Louis')
#   equalHtml div, "<div>Louis</div>"

# test 'observable collection', ->
#   coll = collection([name: 'Karen'])
#   mapUl = html(['ul',
#               (coll.map((obj, i)->
#                 ['li', i, obj.val("name")]) )])
#   filterUl = html(['ul',
#               (coll.filter(name: 'Louis', (obj, i)->
#                 ['li', i, obj.val("name")]) )])
#   # computedUl = html(['ul',
#   #                   computed(coll, (obj) ->
#   #                     ['li', 8, obj.val('name'), 'Computed'])])
#   attributeUl = html(['ul',
#                     coll.map((obj, i) ->
#                       ['li', {class: "index-#{i}"}, obj.val('name')])])
#   # forUl = html(['ul',
#   #             ['for', ((obj, i)->
#   #               ['li', i, obj.val("name")] )]])

#   equalHtml mapUl, "<ul><li>0Karen</li></ul>"
#   # equalHtml forUl, "<ul><li>0Karen</li></ul>"
#   equalHtml filterUl, "<ul></ul>"
#   # equalHtml computedUl, "<ul><li>8KarenComputed</li></ul>"
#   equalHtml attributeUl, '<ul><li class="index-0">Karen</li></ul>'

#   coll.at(0).set('name', 'Louis')

#   equalHtml mapUl, "<ul><li>Louis</li></ul>"
#   # equalHtml forUl, "<ul><li>Louis</li></ul>"
#   equalHtml filterUl, "<ul></ul>"
#   # equalHtml computedUl, "<ul><li>8LouisComputed</li></ul>"
#   equalHtml attributeUl, '<ul><li class="index-0">Louis</li></ul>'

#   coll.add(name: 'Keith')

#   equalHtml mapUl, "<ul><li>Louis</li><li>Keith</li></ul>"
#   # equalHtml forUl, "<ul><li>Louis</li><li>Keith</li></ul>"
#   equalHtml filterUl, "<ul><li>Louis</li></ul>"
#   # equalHtml computedUl, "<ul><li>8LouisComputed</li><li>8KeithComputed</li></ul>"
#   equalHtml attributeUl, '<ul><li class="index-0">Louis</li><li class="index-1">Keith</li></ul>'
