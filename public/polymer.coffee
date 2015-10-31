template = document.querySelector('#template')
socket = io.connect document.location.origin,
  reconnectionDelay: 200
  reconnectionDelayMax: 1000

template.announcement = ""

template.status = 'connected'

template.messages = []

template.users = []

defaultNames = ["Killer Whale", "Giraffe", "Rabbit", "Polar Bear", "Cheetah", "Snow Leopard", "Eagle", "Fox", "Panda", "Salamander", "Jackal", "Elephant ", "Lion", "Horse", "Monkey", "Penguin ", "Wolf", "Dolphin", "Tiger", "Cat", "Shinigami", "Korra", "Aang", "Izumi", "Katara"]

template.userName = prompt "Enter a nick:"

template.avatar = "http://eightbitavatar.herokuapp.com/?id=" + escape(template.userName) + "&s=male&size=80"

sendMessage = (msg)->
  socket.emit 'chat:msg',
    message: msg
    nick: template.userName
    avatar: template.avatar

showMessage = (msg)->
  template.messages.push msg
  template.async ()->
    chatDiv = document.querySelector('.chat-list');
    chatDiv.scrollTop = chatDiv.scrollHeight;

template.sendMyMessage = () ->
  $input = $("#input")
  
  if socket.socket.connected == false
    alert 'Please wait while we reconnect'
  else if $input.val().trim() != ''
    sendMessage $input.val()
    $input.val ''


template.checkKey = (e) ->
  if e.which == 13
    template.sendMyMessage()
  e.preventDefault()

socket.on 'disconnect', ->
  template.status = 'disconnected'

socket.on 'reconnect', ->
  template.status = 'connected'

socket.on 'connect', ->
  template.status = 'connected'
  socket.emit 'chat:demand'
  socket.emit 'announcement:demand'
  socket.emit 'presence:demand'

socket.on 'chat:msg', (msg)->
  defaultName = defaultNames[(Math.random() * defaultNames.length) >>> 0]
  if msg.invalidNick
    setTimeout () ->
      msg.nick = template.userName = prompt('Sorry! You can\'t have this username.\nPlease enter another username', defaultName) or defaultName
      sendMessage msg.message
    , 1
  else
    showMessage msg

socket.on 'announcement:data', (data)->
  if data['text'].length > 2
    $("#announcement-text")[0].innerHTML = data['text']
    $("#announcement-area")[0].style.display = "block"
  else
    $("#announcement-area")[0].style.display = "none"
  $("#chat-heading")[0].innerHTML = data['heading']
  document.title = data['pageTitle']

socket.on 'chat:log', (log)->
  log.map showMessage

socket.on 'presence:list', (list)->
  template.users = list
