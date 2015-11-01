
# ioObject is the express().http().io().io object for communicating with clients
module.exports = (ioObject, slackObject) ->
  io = ioObject
  slack = slackObject
  announcement =
    heading: if !!process.env.ORGANIZATION_NAME then ("#Chat with " + process.env.ORGANIZATION_NAME) else "#chat"
    pageTitle: if !!process.env.ORGANIZATION_NAME then ("Chat with " + process.env.ORGANIZATION_NAME) else "#chat"
    text: ""
  
  helpText = "*Usage:*\n\t!" +
  "ban nick <nick> _to ban a nick._\n\t" +
  "!ban user <nick> _to ban the user session corresponding to given nick._\n\t" + 
  "!unban nick <nick>\n\t!unban user <nick>\n\t" +
  "!announcement _to see the current announcement._\n\t" + 
  "!announce <announcement> _to change announcement._\n\t" + 
  "!announce - _to remove announcement._\n\t" +
  "!help _to show this message._"

  io.route 'announcement:demand', (req)->
    req.io.emit 'announcement:data', announcement

  showHelp : ->
      slack.postMessage helpText, process.env.SLACK_CHANNEL, "Jinora"

    interpret : (message, adminNick) ->
      index = message.indexOf(" ")
      command = message.substr(0, index)
      content = message.substr(index + 1)
      if index == -1
        command = message
        content = ""
      command = command.toLowerCase()

      if command == "announcement"
        text = "Current announcement is:\n#{announcement.text}"
        slack.postMessage text, process.env.SLACK_CHANNEL, "Jinora"

      if command == "announce"
        if content == ""
          slack.postMessage helpText, process.env.SLACK_CHANNEL, "Jinora"
          return
        announcement['text'] = content
        io.broadcast 'announcement:data',announcement
        text = "*#{adminNick}* changed announcement to:\n#{announcement.text}" 
        slack.postMessage text, process.env.SLACK_CHANNEL, "Jinora"
