rtm = require './rtm'

module.exports = (token, cb)->

  eventHandler = rtm(token)

  # Update user_list each time the above handlers are called

  eventHandler.on 'active', (username)->
  
    user_list.push(username)
    console.log "#{username} became active"
    ###########

  eventHandler.on 'away', (username)->
      i= user_list.indexOf(username)
      if(i!=-1)
      user_list.splice(i,1)

    console.log "#{username} went away"
    #######

  fetch = ()->
    return user_list

  eventHandler.on 'ready', ()->
    cb(fetch)
    console.log user_list
    console.log "RTM is ready"

  user_list = []