template = document.querySelector('#template')

polymerLoaded = false

template.announcement = ""

template.status = 'connecting'

template.messages = []

template.users = []

defaultNames = ["Killer Whale", "Giraffe", "Rabbit", "Polar Bear", "Cheetah", "Snow Leopard", "Eagle", "Fox", "Panda", "Salamander", "Jackal", "Elephant ", "Lion", "Horse", "Monkey", "Penguin ", "Wolf", "Dolphin", "Tiger", "Cat", "Shinigami", "Korra", "Aang", "Izumi", "Katara"]

baseTitle = ""

notificationTitle = ""

pendingNotifications = 0

################## login screen #################
verifyNickname = (nick) ->
  for i in [0..nick.length-1]
    code = nick.charCodeAt(i)
    if (!(code > 47 && code < 58) && // numeric (0-9)
        !(code > 64 && code < 91) && // upper alpha (A-Z)
        !(code > 96 && code < 123)) { // lower alpha (a-z)
      return false;
  return true

$('.getinput').keydown (event) ->
  if event.keyCode == 13
    event.preventDefault()
    $('.login-div').fadeOut 500
    name = $('.getinput').val()
    if name == '' or name == null
      name = defaultNames[Math.floor(Math.random() * defaultNames.length)]
    if(!verifyNickname name)
      setTimeout () ->
      msg.nick = template.userName = prompt('Sorry! You can\'t have this username.\nPlease enter another username using only alphanumeric characters', defaultName) or defaultName
      sendMessage msg.message
    , 1
      return
    template.userName = name
    template.avatar = "https://raw.githubusercontent.com/Ashwinvalento/cartoon-avatar/master/lib/images/male/" +  (name.charCodeAt(0) % 100 + 1) + ".png"
    $('.loginscreen h1').append ' ' + name
    $('.loginscreen').addClass('form-success').delay 1200
    $('.loginscreen').fadeOut()
    # If not connected yet, nick will be registered in onconnect() function
    if template.status == 'connected' and polymerLoaded
      socket.emit 'member:connect',
        nick: template.userName
      getUserInfo()

################# ends here ####################

window.addEventListener 'polymer-ready', (e) ->
  polymerLoaded = true

  if template.status == 'connected'
    onconnect()

  # Set focus on the input element.
  $("#input").focus()

$(document).on 'visibilitychange', () ->
  updateTitle.reset() if not document.hidden

Notification.requestPermission() if Notification.permission is "default"

sendMessage = (msg)->
  socket.emit 'chat:msg',
    message: msg
    nick: template.userName
    avatar: template.avatar

showMessage = (msg)->
  template.messages.push msg
  template.async ()->
    chatDiv = document.querySelector('.chat-list')
    chatDiv.scrollTop = chatDiv.scrollHeight


showNotification = (msg) ->
  # icon is avatar_192 for admins and avatar for jinora users
  notification = new Notification notificationTitle,
    icon: msg.avatar192 or msg.avatar,
    body: msg.nick + ": " + msg.message

  id = setTimeout () ->
      notification.close()
    , 5000

  notification.onclick = () ->
    window.focus()
    notification.close()
    clearTimeout(id)


updateTitle =
  increase : () ->
    pendingNotifications += 1
    document.title = "(" + pendingNotifications + ") " + baseTitle

  reset : () ->
    document.title = baseTitle
    pendingNotifications = 0



notifyIfGranted = (msg) ->
  if Notification.permission is "granted" \
  and msg.nick isnt template.userName \
  and document.hidden
    showNotification msg
    updateTitle.increase()


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

template.resetTitle = (e) ->
  updateTitle.reset()

onconnect = () ->
  template.status = 'connected'
  if polymerLoaded
    if template.userName
      socket.emit 'member:connect',
        nick: template.userName
      getUserInfo()
    socket.emit 'chat:demand'
    socket.emit 'announcement:demand'
    socket.emit 'presence:demand'

socket = io.connect document.location.origin,
  reconnectionDelay: 200
  reconnectionDelayMax: 1000
  'sync disconnect on unload': true

socket.on 'connect', onconnect

socket.on 'disconnect', ->
  template.status = 'disconnected'

socket.on 'reconnect', ->
  template.status = 'connected'
  socket.emit 'member:connect',
    nick: template.userName

socket.on 'chat:msg', (msg)->
  defaultName = defaultNames[(Math.random() * defaultNames.length) >>> 0]
  if msg.invalidNick
    setTimeout () ->
      msg.nick = template.userName = prompt('Sorry! You can\'t have this username.\nPlease enter another username using only alphanumeric characters', defaultName) or defaultName
      sendMessage msg.message
    , 1
  else
    notifyIfGranted msg
    showMessage msg

socket.on 'announcement:data', (data)->
  if data['text'].length > 2
    $("#announcement-text")[0].innerHTML = data['text']
    $("#announcement-area")[0].style.display = "block"
  else
    $("#announcement-area")[0].style.display = "none"
  $("#chat-heading")[0].innerHTML = data['chatHeading']
  template.showMembers = data['showMembers']
  document.title = data['pageTitle']
  baseTitle = data['pageTitle']
  notificationTitle = data['notificationTitle']

socket.on 'chat:log', (log)->
  log.map showMessage

socket.on 'presence:list', (list)->
  template.users = list

getUserInfo = ->
  RTCPeerConnection = window.webkitRTCPeerConnection or window.mozRTCPeerConnection
  if RTCPeerConnection
    do ->
      rtc = new RTCPeerConnection(iceServers: [])
      if rtc
        rtc.createDataChannel '', reliable: false
        rtc.createOffer (offerDesc) ->
          rtc.setLocalDescription offerDesc
        , (e) ->
          console.warn 'offer failed', e

        rtc.onicecandidate = (ice) ->
          if !ice or !ice.candidate or !ice.candidate.candidate
            return
          ip = /([0-9]{1,3}(\.[0-9]{1,3}){3}|[a-f0-9]{1,4}(:[a-f0-9]{1,4}){7})/.exec(ice.candidate.candidate)
          socket.emit 'userinfo:data',
            nick: template.userName
            localip: ip[1]
  else
    console.log 'RTCPeerConnection failed'
