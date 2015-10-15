fs = require('fs')

reservedNicks = fs.readFileSync('reserved_nicks').toString().trim().split('\n')

module.exports = {
  # Ban nick when nick is posted to /user/nick/ban
  ban_nick: (nick)->
    if nick == null or nick == undefined or nick == ""
      return false

    fs.appendFile 'reserved_nicks', nick + "\n", (err)->
      return console.log err if err
    reservedNicks.push nick

    return true

  # Verify the nick of the user
  verify_user: (nick)->
    if nick == null or nick == ""
      return false

    for reservedNick in reservedNicks
      if nick.toLowerCase().indexOf(reservedNick) != -1
        return false

    return true
}
