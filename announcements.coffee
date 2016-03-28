
# ioObject is the express().http().io().io object for communicating with clients
module.exports = (ioObject, slackObject) ->
  io = ioObject
  slack = slackObject
  announcement =
    heading: if !!process.env.ORGANIZATION_NAME then ("#Chat with " + process.env.ORGANIZATION_NAME) else "#chat"
    pageTitle: if !!process.env.ORGANIZATION_NAME then ("Chat with " + process.env.ORGANIZATION_NAME) else "#chat"
    notificationTitle: if !!process.env.ORGANIZATION_NAME then (process.env.ORGANIZATION_NAME + " chat") else "#chat"
    text: ""
    showMembers: if !!process.env.HIDE_ADMIN_NAMES then false else true

  helpText = """
  *Usage:*
  \t!ban nick <nick> _to ban a nick._
  \t!ban user <nick> _to ban the user session corresponding to given nick._
  \t!unban nick <nick>
  \t!unban user <nick>
  \t!announcement _to see the current announcement._
  \t!announce <announcement> _to change announcement._
  \t!announce - _to remove announcement._
  \t!clear _to remove all the latest messages from the public view._
  \t!help _to show this message._
  """

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
