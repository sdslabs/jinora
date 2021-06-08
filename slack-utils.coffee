slack = require('slack')

listToHash = (list, keyName, innerKey)->
  list = list[keyName]
  hash = {}
  for item in list
    if innerKey?
      hash[item.id] = item[innerKey]
    elseslack = require('slack')

listToHash = (list, keyName, innerKey)->
  list = list[keyName]
  hash = {}
  for item in list
    if innerKey?
      hash[item.id] = item[innerKey]
    else
      hash[item.id] = item
  hash

data = {}

getUsers = (token)->
  slack.users.list(token: token)
    .then (res) ->
      if res.ok
          data['users.simple'] = listToHash res, "members", "name"
          data['users'] = listToHash res, "members"

getChannels = (token)->
  slack.conversations.list (token: token)
    .then (res) ->
      if res.ok
        data['channels.simple'] = listToHash res, "channels", "name"
        data['channels'] = listToHash res, "channels"

module.exports = (API_TOKEN, HOOK_URL)->
  if API_TOKEN?
    getUsers(API_TOKEN)
    getChannels(API_TOKEN)

  postMessage: (message, channel, nick, icon)->
    messageData =
      token: API_TOKEN
      text: message
      parse: "full"
      as_user: false

    if icon? and (icon[0..7] == 'https://' or icon[0..6] == 'http://')
      messageData.icon_url=icon
    # If icon is present and is not an emoji
    else if icon? and not icon.match /^\:\w*\:$/
      messageData.icon_emoji=":#{icon}:"
    # If icon is present and is an emoji
    else if icon? and icon.match /^\:\w*\:$/
      messageData.icon_emoji="#{icon}"
    if channel?
      messageData.channel = "##{channel}"
    if nick?
      messageData.username="#{nick}"

    slack.chat.postMessage(messageData)
  # exporting this to test the method
  listToHash: listToHash
  parseMessage: (message)->
    message
      .replace("<!channel>", "@channel")
      .replace("<!group>", "@group")
      .replace("<!everyone>", "@everyone")
      .replace /<#(C\w*)>/g, (match, channelId)->
        "##{data['channels.simple'][channelId]}"
      .replace /<@(U\w*)>/g, (match, userId)->
        "@#{data['users.simple'][userId]}"
      .replace /<(\S*)>/g, (match, link)->
        link
      .replace /http(s)?:\/\/([^\s]*)\|([^\s]*)/g, (match, protocol, href1, href2) ->
        return ("http" + (protocol || "") + "://" + href1) if href1 == href2
      .replace /&amp;/g, "&"
      .replace /&lt;/g, "<"
      .replace /&gt;/g, ">"

  userInfoById: (search_id)->
    for id, info of data['users']
      return info if search_id == id

  userInfoByName: (username)->
    for id, info of data['users']
      return info if info['name'] == username
      hash[item.id] = item
  hash

data = {}

getUsers = (token)->
  slack.users.list(token: token)
    .then (res) ->
      if res.ok
          data['users.simple'] = listToHash res, "members", "name"
          data['users'] = listToHash res, "members"

getChannels = (token)->
  slack.conversations.list (token: token)
    .then (res) ->
      if res.ok
        data['channels.simple'] = listToHash res, "channels", "name"
        data['channels'] = listToHash res, "channels"

module.exports = (API_TOKEN, HOOK_URL)->
  if API_TOKEN?
    getUsers(API_TOKEN)
    getChannels(API_TOKEN)

  postMessage: (message, channel, nick, icon)->
    messageData =
      token: API_TOKEN
      text: message
      parse: "full"
      as_user: false

    if icon? and (icon[0..7] == 'https://' or icon[0..6] == 'http://')
      messageData.icon_url=icon
    # If icon is present and is not an emoji
    else if icon? and not icon.match /^\:\w*\:$/
      messageData.icon_emoji=":#{icon}:"
    # If icon is present and is an emoji
    else if icon? and icon.match /^\:\w*\:$/
      messageData.icon_emoji="#{icon}"
    if channel?
      messageData.channel = "##{channel}"
    if nick?
      messageData.username="#{nick}"

    slack.chat.postMessage(messageData)
  # exporting this to test the method
  listToHash: listToHash
  parseMessage: (message)->
    message
      .replace("<!channel>", "@channel")
      .replace("<!group>", "@group")
      .replace("<!everyone>", "@everyone")
      .replace /<#(C\w*)>/g, (match, channelId)->
        "##{data['channels.simple'][channelId]}"
      .replace /<@(U\w*)>/g, (match, userId)->
        "@#{data['users.simple'][userId]}"
      .replace /<(\S*)>/g, (match, link)->
        link
      .replace /http(s)?:\/\/([^\s]*)\|([^\s]*)/g, (match, protocol, href1, href2) ->
        return ("http" + (protocol || "") + "://" + href1) if href1 == href2
      .replace /&amp;/g, "&"
      .replace /&lt;/g, "<"
      .replace /&gt;/g, ">"

  userInfoById: (search_id)->
    for id, info of data['users']
      return info if search_id == id

  userInfoByName: (username)->
    for id, info of data['users']
      return info if info['name'] == username
