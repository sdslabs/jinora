rtm = require('slack-utils/rtm')(process.env.API_TOKEN)

online = []

rtm.on 'active', (username)->
  online.push username

rtm.on 'away', (username)->
  index = online.indexOf username
  online.splice index, 1 if index > -1

rtm.on 'ready', ()->
  console.log "Connected to Slack RTM API"

module.exports = online
