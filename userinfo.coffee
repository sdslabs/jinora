platform = require('platform')

module.exports = (ioObject, slackObject) ->
  io = ioObject
  slack = slackObject
  users = {}
  addUser: (req) ->
    users[req.data.nick] = req
  interpret: (message) ->
    index = message.indexOf(' ')
    if `index == -1`
      command = message
      nick = ''
    else
      command = message.substr(0, index)
      nick = message.substr(index + 1)
    command = command.toLowerCase()
    if `command == 'info'`
      if `nick == ''`
        slack.postMessage "No nick supplied", process.env.SLACK_CHANNEL, 'Jinora'
        return
      if `!(nick in users)`
      	slack.postMessage "No such user found", process.env.SLACK_CHANNEL, 'Jinora'
      	return
      user =
        platform: platform.parse(users[nick].headers['user-agent'])
        ip: users[nick].headers['x-forwarded-for']
      text = "Info for #{nick}:\n"
      text += "\t*platform:* #{user.platform}\n"
      text += "\t*public ip:* #{user.ip}"
      slack.postMessage(text, process.env.SLACK_CHANNEL, 'Jinora')