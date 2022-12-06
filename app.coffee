# First task is to setup environment
if process.env.NODE_ENV != 'production'
  dotenv = require 'dotenv'
  dotenv.load()

express = require('express.io')
fs = require('fs')
path = require('path')
CBuffer = require('CBuffer');
slack = require('slack')
slack_utils = require('./slack-utils')(process.env.API_TOKEN, process.env.INCOMING_HOOK_URL)
presence = require('./presence.coffee')(process.env.API_TOKEN)
rate_limit = require('./rate_limit.coffee')
app = express().http().io()
announcementHandler = require('./announcements.coffee')(app.io, slack_utils)
userInfoHandler = require('./userinfo.coffee')(app.io, slack_utils)
showdown = require('showdown')
showdownHtmlEscape = require('showdown-htmlescape')
sanitizeHtml = require('sanitize-html')

converter = new showdown.Converter
  extensions: [showdownHtmlEscape]
  simplifiedAutoLink: true
  openLinksInNewWindow: true
  strikethrough: true

sanitizerOptions =
  allowedTags: ['b', 'i', 'em', 'strong', 'a', 'strike', 'del', 'code']
  allowedAttributes:
    'a': ['href', 'target']
  allowedSchemes: ['http', 'https', 'ftp', 'mailto']

# Process markdown and sanitize message
sanitizeMessage = (msg) ->
  sanitizeHtml converter.makeHtml(msg), sanitizerOptions

if !!process.env.RESERVED_NICKS_URL
  userVerifier = require('./user.coffee')(slack_utils)
else
  console.error "WARNING: banning won't work as RESERVED_NICKS_URL is not provided"

if !process.env.ORGANIZATION_NAME
  console.error "ERROR: Please provide an ORGANIZATION_NAME environment variable."
  process.exit 1

# This is a circular buffer of messages, which are stored in memory
messages = new CBuffer(parseInt(process.env.BUFFER_SIZE))
onlineMemberList = []
connectNotify = process.env.MEMBER_JOIN_NOTIFY
senders =  new CBuffer(10)
senders_count = 0

setConnectNotify = (val) ->
  connectNotify = val

# Setup your sessions, just like normal.
app.use express.cookieParser()
app.use express.bodyParser()

app.set('trust proxy', 1);

sessionConfig =
  secret: process.env.SESSION_SECRET
  # key: 'connect.sid'
  # cookie:
  #   proxy: process.env.NODE_ENV == 'production',
  #   sameSite: "none"
  #   secure: process.env.NODE_ENV == 'production'
  #   resave: true


app.use express.session sessionConfig
app.use express.static __dirname + '/public'

app.io.set 'transports', ['websocket', 'xhr-polling']

# This function is for interpreting the commands sent to jinora from slack by appending ! to the message
interpretCommand = (commandText, adminNick) ->
  userVerifierCommands = ["ban", "unban"]
  announcementCommands = ["announce", "announcement"]
  clearCommands = ["clean", "clear"]
  userInfoCommands = ["info", "connectnotify"]
  lastUserCommands = ["lastusers"]
  firstWord = commandText.split(' ')[0]
  secondWord = commandText.split(' ')[1]
  if (firstWord in userVerifierCommands)
    if(userVerifier)
      userVerifier.interpret commandText, adminNick, userInfoHandler.fetchOnlineUsers()
    else
      errorText = "Banning feature is not configured. Add RESERVED_NICKS_URL to .env file."
      slack_utils.postMessage errorText, process.env.SLACK_CHANNEL, "Jinora"
  else if (firstWord in announcementCommands)
    announcementHandler.interpret commandText, adminNick
  else if (firstWord in userInfoCommands)
    if firstWord == "connectnotify"
      command = commandText.substr(commandText.indexOf(' ') + 1)
      if command is 'on' or command is 'off'
        setConnectNotify command
        text = "Turned #{connectNotify} user connect notifications"
      else
        text = "Invalid command.\n"
        text += "_Sample commands:_\n"
        text += "\t`!connectnotify on` for turning on user connect notifications.\n"
        text += "\t`!connectnotify off` for turning off user connect notifications.\n"
      slack_utils.postMessage text, process.env.SLACK_CHANNEL, 'Jinora'
    else
      userInfoHandler.interpret commandText

  else if (firstWord in clearCommands)
    if (!secondWord || isNaN(secondWord))
      messages = new CBuffer(parseInt(process.env.BUFFER_SIZE))
    else
      for i in [0..parseInt(secondWord)]
        messages.pop()
  else if firstWord is "lastusers"
    msg = ""
    for i in [0,Math.min(10,senders_count)]
      details = senders.get(senders_count-1-i)
      if details
        msg += details['nick']+":"+details['sid']
        msg += "\n"
    slack_utils.postMessage msg, process.env.SLACK_CHANNEL, 'Jinora'
  else if firstWord is "users"
    msg = userInfoHandler.getOnlineUsers().join ', '
    slack_utils.postMessage msg, process.env.SLACK_CHANNEL, 'Jinora'
  else if firstWord is "help"
    announcementHandler.showHelp()

# Slack outgoing webhook is caught here
app.post "/webhook", (req, res) ->
  throw "Invalid Token" unless req.body.token == process.env.OUTGOING_TOKEN
  # Send a blank response if the message was by a service
  # Prevents us from falling into a loop
  return res.json {} if req.body.user_id == 'USLACKBOT'

  message = slack_utils.parseMessage(req.body.text)
  adminNick = req.body.user_name
  # If the message is not meant to be sent to jinora users, but it is a command meant to be interpreted by jinora
  isCommand = (req.body.text[0] == "!")
  if isCommand
    commandText = message.substr(1)
    interpretCommand(commandText, adminNick)
    res.send ""
    return

  if slack_utils.userInfoById(req.body.user_id)
    profile = slack_utils.userInfoById(req.body.user_id)['profile']
    avatar = profile['image_72']
    avatar192 = profile['image_192']
    if process.env.ADMIN_NICK == "full"
      adminNick = slack_utils.userInfoById(req.body.user_id)['profile']['real_name']
  else
    avatar = "images/default_admin.png"

  message = sanitizeMessage message

  # Broadcast the message to all clients
  msg =
    message: message,
    nick: adminNick,
    admin: 1,
    online: 1,
    timestamp: (new Date).toISOString(),
    avatar: avatar,
    avatar192: avatar192

  # Broadcast the message to all connected clients
  app.io.broadcast "chat:msg", msg

  # Also store the message in memory
  messages.push msg

  # Send a blank response, so slack knows we got it.
  res.send ""


# Broadcast the chat message to all connected clients,
# including the one who made the request
# also send it to slack
app.io.route 'chat:msg', (req)->
  return if rate_limit(req.socket.id)
  return if typeof req.data != "object"
  return if typeof req.data.message != "string"

  delete req.data.invalidNick
  req.data.admin = 0 # Indicates that the message is not sent by a team member
  req.data.online = 0 # Online status of end user is not tracked, always set to 0
  req.data.timestamp = (new Date).toISOString() # Current Time
  if !req.data.avatar
    req.data.avatar = process.env.BASE_URL + "/images/default_user.png"
  # If RESERVED_NICKS_URL doesn't exist => userVerifier = ""
  status = if req.cookies && !!(userVerifier) then userVerifier.verify req.data.nick, req.cookies['connect.sid'], userInfoHandler.fetchOnlineUsers(), req.sessionID else {
    "nick": true,
    "session": true
  }
  storeMsg = true

  slackChannel = process.env.SLACK_CHANNEL
  originalMsg = req.data.message
  req.data.message = sanitizeMessage originalMsg
  senders.push {"nick":req.data.nick,"sid":req.sessionID.toLowerCase()}
  senders_count += 1
  # If the nick is reserved
  if !status['nick']
    req.data.invalidNick = true;
    req.io.emit 'chat:msg', req.data
    return

# If the session is banned
  else if !status['session'] or !status['ip']
    req.io.emit 'chat:msg', req.data
    slackChannel = process.env.BANNED_CHANNEL
    storeMsg = false

# If the message is private
  else if req.data.message[0] == '!'
    req.io.emit 'chat:msg', req.data
    storeMsg = false

  else
# Send the message to all jinora users
    app.io.broadcast 'chat:msg', req.data

  # Send message to slack
  # If we were given a valid avatar
  if req.data.avatar
    icon = req.data.avatar
    slack_utils.postMessage originalMsg, slackChannel, req.data.nick, icon
  else
    slack_utils.postMessage originalMsg, slackChannel, req.data.nick

  # Store message in memory
  if storeMsg
    messages.push req.data

# Once a new chat client connects
# Send them back the last 100 messages
app.io.route 'chat:demand', (req)->
  logs = messages.toArray()
  req.io.emit 'chat:log', logs

app.io.route 'member:connect', (req)->
  userInfoHandler.addUser req
  if connectNotify == "on"
    slack_utils.postMessage "#{req.data.nick} entered channel", process.env.SLACK_CHANNEL, "Jinora"

app.io.route 'presence:demand', (req)->
  req.io.emit 'presence:list', onlineMemberList

app.io.route 'userinfo:data', (req)->
  userInfoHandler.addUserIp req

app.io.on 'connection', (socket)->
  socket.on 'disconnect', ()->
    nick = userInfoHandler.removeUser socket.id
    if connectNotify == "on"
      slack_utils.postMessage "#{nick} left channel", process.env.SLACK_CHANNEL, "Jinora"

presence.on 'change', ()->
  onlineMemberList = []
  for username in presence.online()
    userInfo = slack_utils.userInfoByName(username)
    if userInfo
      if !!userInfo.is_bot    # Continue for loop in case is_bot is true. '!!'' take care of case when is_bot is undefined
        continue
      avatar = userInfo['profile']['image_72']
      if process.env.ADMIN_NICK == "full"
        username = userInfo['profile']['real_name']
    else
      avatar = "images/default_admin.png"

    onlineMemberList.push({
      name: username
      avatar: avatar
    })

  app.io.broadcast 'presence:list', onlineMemberList

# Render the homepage
app.get "/", (req, res) ->
  res.sendfile "public/index.html"

app.listen process.env.PORT || 3000
