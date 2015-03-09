rtm = require './rtm'

module.exports = (token, cb)->

  eventHandler = rtm(token)

  # Update user_list each time the above handlers are called

  eventHandler.on 'active', (username)->
    ####### FILL THIS
    console.log "#{username} became active"
    ###########

  eventHandler.on 'away', (username)->
    ####### FILL THIS
    console.log "#{username} went away"
    #######

  fetch = ()->
    return user_list

  eventHandler.on 'ready', ()->
    cb(fetch)
    console.log "RTM is ready"

  user_list = []