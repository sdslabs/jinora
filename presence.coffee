rtm = require('slack-utils/rtm')(process.env.API_TOKEN)
EventEmitter = require('events').EventEmitter
presence = new EventEmitter
online = []

presence.online = ()->
  online

rtm.on 'active', (username)->
  online.push username if username not in online
  presence.emit 'change'

rtm.on 'away', (username)->
  index = online.indexOf username
  online.splice index, 1 if index > -1
  presence.emit 'change'

rtm.on 'ready', ()->
  console.log "Connected to Slack RTM API"

module.exports = presence
