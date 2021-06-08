slack = require('slack')

EventEmitter = require('events').EventEmitter
online = []


WebSocket = require('ws')
presence = new EventEmitter
slackData = {}

#parses an RTM event

parseMessage = (msg) ->
  msg = JSON.parse(msg)
  #we are only interested in presence change
  if msg.type == 'presence_change'
    sendPresenceEvent msg
  else if msg.type == 'hello'
    presence.emit 'ready'
  else
    presence.emit msg.type, msg
  presence.emit '*', msg
  return

#translates a slack unique userid to readable username

userIdToNick = (userid) ->
  users = slackData.users
  for user in users
    if user.id == userid
      return user.name
  'unknown'

#throw the initial data to the database
#via the events

sendPresenceEvent = (msg) ->
  for user in msg["users"]
  #ignore the slackbot
    if user.id != 'USLACKBOT'
      presence.emit msg.presence, userIdToNick user
  return

getPresenceSubscriptionJson = (users) ->
  JSON.stringify
    type: "presence_sub"
    ids: users.map (user) -> user.id


presence.online = ()->
  online

presence.on 'active', (username)->
  online.push username if username not in online
  presence.emit 'change'

presence.on 'away', (username)->
  index = online.indexOf username
  online.splice index, 1 if index > -1
  presence.emit 'change'

presence.on 'ready', ()->
  console.log "Connected to Slack RTM API"

module.exports = (token) ->
#First call the presence.start method of Slack API
  slack.rtm.start ({token: token, batch_presence_aware: 1})
    .then (res) ->
      #This is the initial response data with a lot of interesting keys
      #So we store it as well
      slackData = res
      #Connect the websocket
      ws = new WebSocket(res.url)
      #Sets up the callback for websocket messaging
      ws.on 'message', parseMessage
      ws.on 'open', (socket)->
        presence.emit 'connect'
      ws.on 'error', (err)->
        presence.emit 'error', err
      presence.on 'ready', () ->
        ws.send getPresenceSubscriptionJson res.users
  #Return the eventemitter
  return presence
