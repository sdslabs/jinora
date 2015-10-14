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

banFunction = {
  ban: {
    nick: (nick) ->
      banned = () ->
        nick = nick.toLowerCase()
        fs.appendFile 'reserved_nicks', nick + "\n", (err)->
          return false if err
        reservedNicks.push nick
        return true
        
      return !!nick and (!verifyNick(nick) or banned())

    user: (nick) ->
      banned = () ->
        nick = nick.toLowerCase()
        if nickSessionMap[nick]
          bannedSessions.push nickSessionMap[nick] if nickSessionMap[nick] not in bannedSessions
          return true

      return !!nick and banned()
  }
    
  unban: {
    nick: (nick) ->
      unbanned = () ->
        nick = nick.toLowerCase()
        if nick in reservedNicks
          reservedNicks.pop nick
          fs.writeFile 'reserved_nicks', reservedNicks.join('\n')+'\n', (err) ->
            return false if err
          return true

      return !!nick and unbanned()

    user: (nick) ->
      unbanned = () ->
        nick = nick.toLowerCase()
        if nickSessionMap[nick]
          bannedSessions.pop nickSessionMap[nick] if nickSessionMap[nick] in bannedSessions
          return true

      return !!nick and unbanned()
  }

}


module.exports = {
  # Verify and return the auth status
  verify: (nick, sessionId) ->
    nick = (nick or "").toLowerCase()
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
      userNick = words[2] or ""
      if types.hasOwnProperty(words[1])
        type = words[1]
        commandStatus = eval("banFunction.#{words[0]}.#{type}")(userNick) or "error"

    slackMessage = makeSlackMessage(commandStatus, banStatus, types[type], userNick, adminNick)
    return slackMessage

}
