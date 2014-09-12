dotenv = require 'dotenv'
dotenv.load()

express = require('express.io')
app = express().http().io()

# Setup your sessions, just like normal.
app.use express.cookieParser()
app.use express.bodyParser()
app.use express.session secret: process.env.SESSION_SECRET
app.use express.static __dirname + '/public'

app.post "/webhook", (req, res) ->
  try
    throw "Invalid Token" if req.body.token != process.env.OUTGOING_TOKEN
    # Send a blank response if the message was by us
    # Prevents us from falling into a loop
    return res.json {} if req.body.user_name == process.env.USER_NAME

    # Broadcast the message to all clients
    console.log req.body
    app.io.broadcast "chat:msg", message: req.body.text, nick: req.body.user_name, classes: ""
  catch e
    console.error e
  # Send a blank response to the server
  # If we add anything here, jinora goes into a loop.
  res.json {}

# Broadcast the chat message to all connected clients, 
# including the one who made the request
# also send it to slack
app.io.route 'chat:msg', (req)->
  app.io.broadcast 'chat:msg', req.data
  

app.get "/", (req, res) ->
  res.sendfile "index.html"

app.listen 3000