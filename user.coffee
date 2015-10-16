fs = require('fs')

reservedNicks = fs.readFileSync('reserved_nicks').toString().trim().split('\n')
nickSessionMap = {}
bannedSessions = []
status = {}

# Verify the nick of user
verifyNick = (nick)->
  return false if !nick

  nick = nick.toLowerCase()

  for reservedNick in reservedNicks
    if nick.indexOf(reservedNick) != -1
      return false

  return true

# Verify the session of user
verifySession = (sessionId)->
  return false if !sessionId

  return false if sessionId in bannedSessions

  return true


module.exports = {
  # Ban nick when nick is posted to /user/nick/ban
  banNick: (nick)->
    return false if !nick
    return true if !verifyNick nick

    nick = nick.toLowerCase()

    fs.appendFile 'reserved_nicks', nick + "\n", (err)->
      return false if err

    reservedNicks.push nick

    return true

  # Ban session when nick is posted to /user/session/ban
  banSession: (nick)->
    return false if !nick

    nick = nick.toLowerCase()

    if nickSessionMap[nick]
      bannedSessions.push nickSessionMap[nick] if nickSessionMap[nick] not in bannedSessions
      return true
    
    return false

  # Verify and return the auth status
  verify: (nick, sessionId)->
    nickSessionMap[nick] = sessionId
    status['nick'] = verifyNick(nick)
    status['session'] = verifySession(sessionId)

    return status

}
