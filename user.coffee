fs = require('fs')

reservedNicks = fs.readFileSync('reserved_nicks').toString().trim().split('\n')
nick_session_map = {}
banned_sessions = []
status = {}

# Verify the nick of user
verify_nick = (nick)->
  if nick == null or nick == ""
    return false

  for reservedNick in reservedNicks
    if nick.toLowerCase().indexOf(reservedNick) != -1
      return false

  return true

# Verify the session of user
verify_session = (session_id)->
  if session_id == null or session_id == undefined or session_id == ""
    return false

  if session_id in banned_sessions
    return false

  return true


module.exports = {
  # Ban nick when nick is posted to /user/nick/ban
  ban_nick: (nick)->
    if nick == null or nick == undefined or nick == ""
      return false

    fs.appendFile 'reserved_nicks', nick + "\n", (err)->
      return false if err
    reservedNicks.push nick

    return true

  # Ban session when nick is posted to /user/session/ban
  ban_session: (nick)->
    if nick == null or nick == undefined or nick == ""
      return false

    if nick_session_map[nick] != undefined
      banned_sessions.push nick_session_map[nick] if banned_sessions[nick_session_map[nick]] == undefined
      return true
    
    return false

  # Verify and return the auth status
  verify: (nick, session_id)->
    nick_session_map[nick] = session_id
    status['nick'] = verify_nick(nick)
    status['session'] = verify_session(session_id)

    return status

}
