dotenv = require 'dotenv'
dotenv.load()

express = require('express.io')
app = express().http().io()

# Setup your sessions, just like normal.
app.use express.cookieParser()
app.use express.bodyParser()
app.use express.session {secret: 'monkey'}
app.use express.static __dirname + '/public'

app.post "/webhook", (req, res) ->
  try
    throw "Invalid Token" if req.body.token != process.env.OUTGOING_TOKEN
    req.io.broadcast "chat:msg", text: req.body.text, user: req.body.user_name
  catch e
    console.error e
  # Send a blank response to the server
  # If we add anything here, jinora goes into a loop.
  res.json {}

app.get "/", (req, res) ->
  res.sendfile "index.html"

app.listen 3000