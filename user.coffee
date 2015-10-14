fs = require('fs')

reservedNicks = fs.readFileSync('reserved_nicks').toString().split('\n')

module.exports = (nick)->
  # If the nick empty
  if nick == null or nick == ""
    return false
  # If the nick contains any of reservedNicks
  for reservedNick in reservedNicks
    if nick.toLowerCase().indexOf(reservedNick) != -1
      return false

  return true
