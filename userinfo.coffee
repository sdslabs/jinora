platform = require('platform')

module.exports = (ioObject, slackObject, setConnectNotify) ->
  io = ioObject
  slack = slackObject
  users = {}

  addUser: (req) ->
    user =
      nick: req.data.nick
      platform: platform.parse(req.headers['user-agent'])
      ip:
        public: req.headers['x-forwarded-for']
        local: []
    users[req.io.socket.id] = user

  removeUser: (id)->
    if !!users[id]
      nick = users[id].nick
      delete users[id]
      nick

  addUserIp: (req) ->
    user = users[req.io.socket.id]
    user.ip.local.push req.data.localip if user

  getOnlineUsers: ()->
    onlineUsers = []
    for id, user of users
      onlineUsers.push user.nick+":"+user.ip.public
    onlineUsers
  
  fetchOnlineUsers: ()->
    u = {}
    for id, user of users
      u[user.nick] = user.ip.public
    console.log u
    return u

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
      userExist = Object.keys(users).some (id) ->
        user = users[id]
        if user.nick == nick
          text = "Info for #{nick}:\n"
          text += "\t*platform:* #{user.platform}\n"
          text += "\t*public ip:* #{user.ip.public}\n"
          text += "\t*local ip:* #{user.ip.local.join '|'}"
          slack.postMessage text, process.env.SLACK_CHANNEL, 'Jinora'
          return true
        false
      slack.postMessage "No such user found", process.env.SLACK_CHANNEL, 'Jinora' if !userExist

