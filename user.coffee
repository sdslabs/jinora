fs = require('fs')

reservedNicks = fs.readFileSync('reserved_nicks').toString().trim().split('\n')
nickSessionMap = {}
bannedSessions = []
status = {}

makeSlackMessage = (status, banStatus, type, userNick, adminNick) ->
  if status == true
    if banStatus[0] == "ban"
      slackMessage = "#{adminNick} just #{type}-banned #{userNick}"
    else if banStatus[0] == "unban"
      slackMessage = "#{adminNick} just removed #{type}-ban from #{userNick}"
  else if status == "error"
    slackMessage = "Error while #{type}-banning #{userNick}"
  else if status == "invalid"
    if banStatus.length == 1
      slackMessage = "Invalid command for #{banStatus}ning.\n"
    else
      slackMessage = "Invalid command.\n"
    slackMessage += "Sample commands:\n"
    for ban in banStatus
      slackMessage += "`!#{ban} nick cat` for #{ban}ning nick `cat`\n`!#{ban} user cat` for shadow-#{ban}ning user `cat`\n"
  return slackMessage

# Verify the nick of user
verifyNick = (nick) ->
  return false if !nick

  nick = nick.toLowerCase()

  for reservedNick in reservedNicks
    if nick.indexOf(reservedNick) != -1
      return false

  return true

# Verify the session of user
verifyUser = (sessionId) ->
  return false if !sessionId
  return false if sessionId in bannedSessions

  return true

banFunction = {
  ban: {
    nick: (nick) ->
      return false if !nick
      return true if !verifyNick nick

      nick = nick.toLowerCase()

      fs.appendFile 'reserved_nicks', nick + "\n", (err)->
        return false if err

      reservedNicks.push nick

      return true

    user: (nick) ->
      return false if !nick

      nick = nick.toLowerCase()

      if nickSessionMap[nick]
        bannedSessions.push nickSessionMap[nick] if nickSessionMap[nick] not in bannedSessions
        return true

      return false
  }
    
  unban: {
    nick: (nick) ->
      return false if !nick

      nick = nick.toLowerCase()

      if nick in reservedNicks
        reservedNicks.pop nick
        fs.writeFile 'reserved_nicks', reservedNicks.join('\n')+'\n', (err) ->
          return false if err
        return true

      return false

    user: (nick) ->
      return false if !nick

      nick = nick.toLowerCase()

      if nickSessionMap[nick]
        bannedSessions.pop nickSessionMap[nick] if nickSessionMap[nick] in bannedSessions
        return true

      return false
  }

}


module.exports = {
  # Verify and return the auth status
  verify: (nick, sessionId) ->
    nick = (nick || "").toLowerCase()
    nickSessionMap[nick] = sessionId
    status['nick'] = verifyNick(nick)
    status['session'] = verifyUser(sessionId)

    return status

  interpret: (message, adminNick) ->
    message = message.toLowerCase()
    words = message.split(' ')
    bans = ["ban", "unban"]
    types = {"nick": "nick", "user": "shadow"}
    commandStatus = "invalid"
    type = ""
    banStatus = bans
    if words[0] in bans
      banStatus = [words[0]]
      userNick = words[2] || ""
      if types.hasOwnProperty(words[1])
        type = words[1]
        commandStatus = eval("banFunction.#{words[0]}.#{type}")(userNick) || "error"

    slackMessage = makeSlackMessage(commandStatus, banStatus, type, userNick, adminNick)
    return slackMessage

}
