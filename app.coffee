# First task is to setup environment
if process.env.NODE_ENV != 'production'
  dotenv = require 'dotenv'
  dotenv.load()

slack = require('./slack')
express = require('express.io')
request = require('request')
CBuffer = require('CBuffer');

app = express().http().io()
messages = new CBuffer(100) # This is a circular buffer of 100 messages, which are stored in memory

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
  
  # Broadcast the message to all clients
  msg = 
    message: slack.parseMessage(req.body.text),
    nick: req.body.user_name,
    classes: "admin",
    timestamp: Math.floor(req.body.timestamp*1000)
  
  app.io.broadcast "chat:msg", msg
  
  # Also store the message in memory
  messages.push msg
      
  # Send a blank response, so slack knows we got it.
  res.send ""

# Broadcast the chat message to all connected clients, 
# including the one who made the request
# also send it to slack
app.io.route 'chat:msg', (req)->
  req.data.timestamp = (new Date).getTime()
  # Send the message to all jinora users
  app.io.broadcast 'chat:msg', req.data
  # Send message to slack
  slack.postMessage req.data.message, req.data.nick
  # Store message in memory
  messages.push req.data

# Once a new chat client connects
# Send them back the last 100 messages
app.io.route 'chat:demand', (req)->
  req.io.emit 'chat:log', messages.toArray()

# Render the homepage
app.get "/", (req, res) ->
  res.sendfile "index.html"

app.listen process.env.PORT || 3000

