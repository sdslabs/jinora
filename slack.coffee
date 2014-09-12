request = require('request')
module.exports =
  postMessage: (message, nick)->
    request.post
      url: "https://#{process.env.TEAM_DOMAIN}.slack.com/services/hooks/incoming-webhook?token=#{process.env.INCOMING_TOKEN}"
      headers: 
        "Content-Type": "application/json"
      json:
        text:     message
        username: nick
        parse:    "full"