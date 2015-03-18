template = document.querySelector('body template:first-child')
socket = io.connect document.location.origin,
  reconnectionDelay: 200
  reconnectionDelayMax: 1000

avatars = ['tabby', 'bengal', 'persian', 'mainecoon', 'ragdoll', 'sphynx', 'siamese', 'korat', 'japanesebobtail', 'abyssinian', 'scottishfold']
colors = ['navy', 'slate', 'olive', 'moss', 'chocolate', 'buttercup', 'maroon', 'cerise', 'plum', 'orchid']

avatar = (Math.random() * avatars.length) >>> 0
color  = (Math.random() * colors.length) >>> 0

template.avatar = "images/avatars/#{avatars[avatar]}.jpg"
template.color  = colors[color]
template.status = 'connected'
template.messages = []
template.users = []
template.userName = prompt('Enter your username')

sendMessage = (msg)->
  socket.emit 'chat:msg',
    message: msg
    nick: template.userName
    avatar: avatar
    color: color

template.sendMyMessage = (msg) ->
  sendMessage(msg)

template.checkKey = (e) ->
  $input = $(e.target)
  if e.which == 13
    if socket.socket.connected == false
      alert 'Please wait while we reconnect'
    else if $input.val().trim() != ''
      sendMessage $input.val()
      $input.val ''
  e.preventDefault()

socket.on 'disconnect', ->
  template.status = 'disconnected'

socket.on 'reconnect', ->
  template.status = 'connected'

socket.on 'connect', ->
  template.status = 'connected'
  socket.emit 'chat:demand'
  socket.emit 'presence:demand'

socket.on 'chat:msg', (data)->
  data.timestamp = new Date(data.timestamp).toISOString();
  data.avatar = "images/avatars/#{avatars[data.avatar]}.jpg" if Number.isInteger data.avatar
  data.color = colors[data.color] if data.color?
  template.messages.push data

socket.on 'presence:list', (list)->
  console.log list
  template.users = list
