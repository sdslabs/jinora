if process.env.NODE_ENV != 'production'
  dotenv = require 'dotenv'
  dotenv.load()

request = require('request')


slack = 
msg = {}
nickSessionMap = {}
bannedIps = []
bannedSessions = []
HEADERS = {
  "Content-Type": "application/json",
  "Accept": "application/json"
}
reservedNicks = []

# Get json object from RESERVED_NICKS_URL and set the value of reservedNicks
getJsonBlob = () ->
  options = {
    method: "GET"
    url: process.env.RESERVED_NICKS_URL,
    headers: HEADERS
  }
  callback = (error, response, body) ->
    if !error and response.statusCode == 200
      res = JSON.parse body
      reservedNicks = res.nicks || []

  return request options, callback

updateJsonBlob = () ->
  options = {
    method: "PUT"
    url: process.env.RESERVED_NICKS_URL,
    headers: HEADERS
    body: JSON.stringify {"nicks": reservedNicks}
  }
  callback = (error, response, body) ->
    if !error and response.statusCode == 200
      msg.cmdStatus = true
    else
      msg.cmdStatus = "error"

    msg.message = makeSlackMessage()
    slack.postMessage msg.message, process.env.SLACK_CHANNEL, "Jinora"

  return request options, callback

# Form custom message to be sent to slack
makeSlackMessage = () ->
  if msg.cmdStatus == true
    if msg.banStatus[0] == "ban"
      msg.message = "#{msg.adminNick} just #{msg.type}-banned #{msg.userNick}"
    else if msg.banStatus[0] == "unban"
      msg.message = "#{msg.adminNick} just removed #{msg.type}-ban from #{msg.userNick}"
  else if msg.cmdStatus == "error"
    msg.message = "Error while #{msg.type}-banning #{msg.userNick}"
  else if msg.cmdStatus == "invalid"
    if msg.banStatus.length == 1
      msg.message = "Invalid command for #{msg.banStatus}ning.\n"
    else
      msg.message = "Invalid command.\n"
    msg.message += "Sample commands:\n"
    for ban in msg.banStatus
      msg.message += "`!#{ban} nick cat` for #{ban}ning nick `cat`\n`!#{ban} user cat` for shadow-#{ban}ning user `cat`\n"
  return msg.message

# Verify the nick of user
verifyNick = (nick) ->
  verified = () ->
    nick = nick.toLowerCase()
    for reservedNick in reservedNicks
      if nick.indexOf(reservedNick) != -1
        return false
    return true

  return !!nick and if !verified() then false else true

# Verify the session of user
verifyUser = (sessionId) ->
  return !!sessionId and if sessionId in bannedSessions then false else true

# Verify the ip of user
verifyIp = (nick, onlineUsers) ->
  return if onlineUsers[nick] in bannedIps then false else true

banFunction = {
  nick: {
    ban: (nick) ->
      banned = () ->
        nick = nick.toLowerCase()
        reservedNicks.push nick
        updateJsonBlob()
        return true
      return !!nick and (verifyNick(nick) and banned())

    unban: (nick) ->
      unbanned = () ->
        nick = nick.toLowerCase()
        if nick in reservedNicks
          reservedNicks.splice(reservedNicks.indexOf(nick), 1)
          updateJsonBlob()
          return true

      return !!nick and unbanned()
  }

  user: {
    ban: (nick) ->
      banned = () ->
        nick = nick.toLowerCase()
        if nickSessionMap[nick]
          bannedSessions.push nickSessionMap[nick] if nickSessionMap[nick] not in bannedSessions
          msg.cmdStatus = true
          msg.message = makeSlackMessage()
          slack.postMessage msg.message, process.env.SLACK_CHANNEL, "Jinora"
          return true

      return !!nick and banned()

    unban: (nick) ->
      unbanned = () ->
        nick = nick.toLowerCase()
        if nickSessionMap[nick]
          bannedSessions.pop nickSessionMap[nick] if nickSessionMap[nick] in bannedSessions
          msg.cmdStatus = true
          msg.message = makeSlackMessage()
          slack.postMessage msg.message, process.env.SLACK_CHANNEL, "Jinora"
          return true

      return !!nick and unbanned()
  }

  ip : {
    ban: (add) ->
      banned = () ->
        bannedIps.push add
        msg.cmdStatus = true
        msg.message = makeSlackMessage()
        slack.postMessage msg.message, process.env.SLACK_CHANNEL, "Jinora"
        return true
      return !!add and banned()

    unban: (add) ->
      unbanned = () ->
        if add in bannedIps
          bannedIps.splice(bannedIps.indexOf(add), 1)
          msg.cmdStatus = true
          msg.message = makeSlackMessage()
          slack.postMessage msg.message, process.env.SLACK_CHANNEL, "Jinora"

          return true
      return !!add and unbanned()
  }

}

module.exports = (slackObject) ->

  slack = slackObject

  return {
    # Verify and return the auth status
    verify: (nick, sessionId, onlineUsers) ->
      nick = (nick or "").toLowerCase()
      nickSessionMap[nick] = sessionId
      status = {}
      status['nick'] = verifyNick(nick)
      status['session'] = verifyUser(sessionId)
      status['ip'] = verifyIp(nick, onlineUsers)
      return status

    # Intepret private messages from slack to jinora and send a message to slack accordingly
    interpret: (message, adminNick, onlineUsers) ->
      msg.adminNick = adminNick
      msg.message = message.toLowerCase()
      msg.type = ""
      msg.cmdStatus = "invalid"
      words = msg.message.split(' ')
      types = ["nick", "user", "ip"]
      bans = ["ban", "unban"]
      msg.banStatus = bans
      if words[0] in bans
        msg.banStatus = [words[0]]
        msg.userNick = words[2..].join(" ") or ""
        if words[1] in types
          msg.type = words[1]
          if msg.type == "ip"
            msg.userNick = onlineUsers[msg.userNick]
          msg.cmdStatus = eval("banFunction.#{msg.type}.#{words[0]}")(msg.userNick) || "error"
      if msg.cmdStatus != true
        msg.message = makeSlackMessage()
        slack.postMessage msg.message, process.env.SLACK_CHANNEL, "Jinora"

  }

getJsonBlob()
