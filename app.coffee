# First task is to setup environment
if process.env.NODE_ENV != 'production'
  dotenv = require 'dotenv'
  dotenv.load()

slack = require('./slack')
express = require('express.io')
app = express().http().io()

# Setup your sessions, just like normal.
app.use express.cookieParser()
app.use express.bodyParser()
app.use express.session secret: process.env.SESSION_SECRET
app.use express.static __dirname + '/public'

# Slack outgoing webhook is caught here
app.post "/webhook", (req, res) ->
  try
    throw "Invalid Token" unless req.body.token == process.env.OUTGOING_TOKEN
    
    # Send a blank response if the message was by a service
    # Prevents us from falling into a loop
    return res.json {} if req.body.user_id == 'USLACKBOT'

    # Broadcast the message to all clients
    app.io.broadcast "chat:msg", message: req.body.text, nick: req.body.user_name, classes: ""

# Broadcast the chat message to all connected clients, 
# including the one who made the request
# also send it to slack
app.io.route 'chat:msg', (req)->
  app.io.broadcast 'chat:msg', req.data
  slack.postMessage req.data.message, req.data.nick

# Render the homepage
app.get "/", (req, res) ->
  res.sendfile "index.html"

app.listen process.env.PORT