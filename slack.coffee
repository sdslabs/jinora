request = require('request')

listToHash = (list, keyName)->
  list = list[keyName]
  hash = {}
  for item in list
    hash[item.id] = item.name
  hash

data = {}

getUsers = (token)->
    request.get {url: "https://slack.com/api/users.list?token=#{token}", json: true}, (err, res, users)->
      throw err if err
      data['users'] = listToHash users, "members"

getChannels = (token)->
  request.get {url: "https://slack.com/api/channels.list?token=#{token}", json: true}, (err, res, channels)->
    throw err if err
    data['channels'] = listToHash channels, "channels"

if process.env.API_TOKEN
  do ->
    getUsers(process.env.API_TOKEN)
    getChannels(process.env.API_TOKEN)

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
  
  # exporting this to test the method
  listToHash: listToHash
  parseMessage: (message)->
    message
      .replace("<!channel>", "@channel")
      .replace("<!group>", "@group")
      .replace("<!everyone>", "@everyone")
      .replace /<#(C\w*)>/g, (match, channelId)->
        "##{data['channels'][channelId]}"
      .replace /<@(U\w*)>/g, (match, userId)->
        "@#{data['users'][userId]}"
      .replace /<(\S*)>/g, (match, link)->
        link