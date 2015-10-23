# First task is to setup environment
if process.env.NODE_ENV != 'production'
  dotenv = require 'dotenv'
  dotenv.load()

express = require('express.io')
fs = require('fs')
path = require('path')
CBuffer = require('CBuffer');
slack = require('slack-utils/api')(process.env.API_TOKEN, process.env.INCOMING_HOOK_URL)
presence = require('./presence.coffee')
rate_limit = require('./rate_limit.coffee')
app = express().http().io()
if !!process.env.RESERVED_NICKS_URL
  user = require('./user.coffee')(slack)
else
  console.error "ERROR: banning won't work as RESERVED_NICKS_URL is not provided"

# This is a circular buffer of messages, which are stored in memory
messages = new CBuffer(parseInt(process.env.BUFFER_SIZE))

# Note that this is a sorted list
avatars = fs.readdirSync('./public/images/avatars').map (filename)->
  path.basename(filename, '.jpg')

# Setup your sessions, just like normal.
app.use express.cookieParser()
app.use express.bodyParser()
app.use express.session secret: process.env.SESSION_SECRET
app.use express.static __dirname + '/public'

app.io.set 'transports', ['xhr-polling']

# Slack outgoing webhook is caught here
app.post "/webhook", (req, res) ->
  throw "Invalid Token" unless req.body.token == process.env.OUTGOING_TOKEN

  # Send a blank response if the message was by a service
  # Prevents us from falling into a loop
  return res.json {} if req.body.user_id == 'USLACKBOT'

  if slack.userInfoById(req.body.user_id)
    avatar = slack.userInfoById(req.body.user_id)['profile']['image_72']

  message = slack.parseMessage(req.body.text)

  # Broadcast the message to all clients
  msg =
    message: message,
    nick: req.body.user_name,
    classes: "admin",
    timestamp: Math.floor(req.body.timestamp*1000)
    avatar: avatar

  # If RESERVED_NICKS_URL doesn't exist => user = ""
  if !!typeof(user)
    privateMsg = if message[0] == "!" then true else false
    # If the message is not meant to be sent to jinora users, but to be interpreted by jinora
    if privateMsg
      tempMessage = msg.message.substr(1)
      adminNick = msg.nick
      res.send ""

      user.interpret tempMessage, adminNick
      return

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
  return if typeof req.data.message != "string"
  req.data.timestamp = (new Date).getTime()
  # If RESERVED_NICKS_URL doesn't exist => user = ""
  req.data.status = if !!typeof(user) then user.verify req.data.nick, req.cookies['connect.sid'] else {"nick": true, "session": true}

  slackChannel = process.env.SLACK_CHANNEL

  # If the nick is reserved
  if !req.data.status['nick']
    req.io.emit 'chat:msg', req.data
    return
  # If the session is banned
  else if !req.data.status['session']
    req.io.emit 'chat:msg', req.data
    slackChannel = process.env.BANNED_CHANNEL
  # If the message is private
  else if req.data.message[0] == '!'
    req.data.private = true
    req.io.emit 'chat:msg', req.data
  else
    # Send the message to all jinora users
    app.io.broadcast 'chat:msg', req.data

  # Send message to slack
  # If we were given a valid avatar
  if process.env.BASE_URL? and req.data.avatar and avatars[req.data.avatar]
    icon = "#{process.env.BASE_URL}/images/avatars/#{avatars[req.data.avatar]}.jpg"
    slack.postMessage req.data.message, slackChannel, req.data.nick, icon
  else
    slack.postMessage req.data.message, slackChannel, req.data.nick
  # Store message in memory
  messages.push req.data

# Once a new chat client connects
# Send them back the last 100 messages
app.io.route 'chat:demand', (req)->
  logs = messages.toArray()
  # We filter out non-private messages
  logs = logs.filter (msg)->
    msg.message[0] != '!'
  req.io.emit 'chat:log', logs

app.io.route 'presence:demand', (req)->
  req.io.emit 'presence:list', presence.online()

presence.on 'change', ()->
  app.io.broadcast 'presence:list', presence.online()

# Render the homepage
app.get "/", (req, res) ->
  res.sendfile "public/index.html"

app.get "/old", (req, res) ->
  res.sendfile "index.html"

app.listen process.env.PORT || 3000
