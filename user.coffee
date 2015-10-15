fs = require('fs')

reservedNicks = fs.readFileSync('reserved_nicks').toString().trim().split('\n')
nickSessionMap = {}
bannedSessions = []
status = {}

# Verify the nick of user
verifyNick = (nick)->
  if !nick
    return false

  for reservedNick in reservedNicks
    if nick.toLowerCase().indexOf(reservedNick) != -1
      return false

  return true

# Verify the session of user
verifySession = (sessionId)->
  if !sessionId
    return false

  if sessionId in bannedSessions
    return false

  return true


module.exports = {
  # Ban nick when nick is posted to /user/nick/ban
  banNick: (nick)->
    if !nick
      return false

    fs.appendFile 'reserved_nicks', nick + "\n", (err)->
      return false if err
    reservedNicks.push nick

    return true

  # Ban session when nick is posted to /user/session/ban
  banSession: (nick)->
    if !nick
      return false

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
