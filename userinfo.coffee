platform = require('platform')

module.exports = (ioObject, slackObject, setConnectNotify) ->
  io = ioObject
  slack = slackObject
  users = []
  addUser: (req) ->
    user =
      nick: req.data.nick
      platform: platform.parse(req.headers['user-agent'])
      ip: 
        public: req.headers['x-forwarded-for']
        local: []
    users.unshift user
    users.pop if users.length > 100

  addUserIp: (nick, ip) ->
    users.some (user) ->
      if user.nick == nick
        user.ip.local.push ip
        return true
    false

  interpret: (message) ->
    index = message.indexOf(' ')
    if index == -1
      command = message
      nick = ''
    else
      command = message.substr(0, index)
      nick = message.substr(index + 1)
    command = command.toLowerCase()
    if command == 'info'
      if nick == ''
        slack.postMessage "No nick supplied", process.env.SLACK_CHANNEL, 'Jinora'
        return
      userExist = users.some (user) ->
        if user.nick == nick
          text = "Info for #{nick}:\n"
          text += "\t*platform:* #{user.platform}\n"
          text += "\t*public ip:* #{user.ip.public}\n"
          text += "\t*local ip:* #{user.ip.local.join '|'}"
          slack.postMessage text, process.env.SLACK_CHANNEL, 'Jinora'
          return true
        false
      slack.postMessage "No such user found", process.env.SLACK_CHANNEL, 'Jinora' if !userExist
      