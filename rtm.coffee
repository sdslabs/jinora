request = require('request')
WebSocket = require('ws')
EventEmitter = require('events').EventEmitter
ws = undefined
slackData = undefined
rtm = undefined
#eventemitter FTW!
#we emit 2 events: active and away
#parses an RTM event

parseMessage = (msg) ->
  msg = JSON.parse(msg)
  #we are only interested in presence change
  if msg.type == 'presence_change'
    #ignore the presence of slackbot
    if msg.user == 'USLACKBOT'
      return
    rtm.emit msg.presence, userIdToNick(msg.user)
  else if msg.type == 'hello'
    console.log 'Connected to slack'
    rtm.emit 'ready'
  return

#translates a slack unique userid to readable username

userIdToNick = (userid) ->
  users = slackData.users
  for i of users
    `i = i`
    user = users[i]
    if user.id == userid
      return user.name
  'unknown'

#throw the initial data to the database
#via the events

sendInitialPresenceEvent = (users) ->
  for i of users
    `i = i`
    user = users[i]
    #again ignore the slackbot
    if user.id != 'USLACKBOT'
      rtm.emit user.presence, user.name
  return

rtm = new EventEmitter

module.exports = (API_TOKEN) ->
  #First call the rtm.start method of Slack API
  request.get {
    url: 'https://slack.com/api/rtm.start?token=' + API_TOKEN
    json: true
  }, (err, res, json) ->
    if err
      throw err
    #This is the initial response data with a lot of interesting keys
    #So we store it as well
    slackData = json
    #Emit events for initial data
    sendInitialPresenceEvent slackData.users
    #Connect the websocket
    ws = new WebSocket(json.url)
    #Sets up the callback for websocket messaging
    ws.on 'message', parseMessage
    return
  #Return the eventemitter
  rtm
