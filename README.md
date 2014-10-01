#jinora

jinora is a simple slack-backed chat application that proxies messages to and fro between slack and an anonymous chat platform. It allows your team to maintain a `#public` channel where anonymous users can come and talk to your entire team. You can then direct users wanting support, for example, to your jinora instance where you can help them resolve the issue over chat. 

No more need to having your team monitor IRC or Olark, it can all be done in Slack.

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/captn3m0/jinora)

![Jinora artwork by peachei](https://i.imgur.com/WNRjxyN.jpg)

#[LIVE DEMO](http://chat.sdslabs.co)

##Features

1. Make a truly public channel in Slack (no need of a paid plan)
2. Emoji support
3. Translates all #channel hashtags and user @mentions properly
4. Messages sent from Slack are highlighted as official
5. Circular buffer that stores last 100 messages in memory

##Setup Instructions

Configuration Options:

- **OUTGOING_TOKEN** Service Token from Slack's outgoing webhook
- **INCOMING_TOKEN** Service Token from Slack's incoming webhook
- **TEAM_DOMAIN** Domain name of your slack team (just sdslabs, not sdslabs.slack.com)
- **SESSION_SECRET** Session secret key
- **API_TOKEN** API Token for the slack team. Generated at <https://api.slack.com> (scroll to bottom).

These configuration options can either be provided via a `.env` file in development, or via Heroku config variables, if you are deploying to Heroku. A sample env file is provided in `.env.sample`. You can see service tokens on the left sidebar in Slack configuration.

###Slack-side configuration
1. Create a `#public` channel (could be called anything).
2. Create an outgoing webhook that listens only on `#public`.
3. Create an incoming webhook, and note down its token. Set the webhook's channel to `#public`.

Screenshots for a better understanding (outgoing and then incoming):

![Outgoing Webhook](https://i.imgur.com/myIfQeQ.png)

![Incoming Webhook](https://i.imgur.com/v2rWjJw.png)

##Architecture

           +--------------+        
           |    #public   |        
           |    channel   |        
           +--^--------^--+        
              |        |           
           +--v--------v--+        
           |    SLACK     |        
           |              |        
           +--^--------^--+        
              |        |           
    Incoming  |        |  Outgoing 
     webhook  |        |  webhook  
           +--v--------v--+        
           |              |        
           |    JINORA    |        
           |    SERVER    |        
           |              |        
           +--^--------^--+        
              |        |           
              |        |  Socket.IO
              |        |           
           +--v--------v--+        
           |              |        
           |     YOUR     |        
           |    USERS     |        
           |              |        
           +--------------+        

Jinora communicates with slack by means of two webhooks, one incoming and one outgoing. This communication is then broadcasted to all clients connected to Jinora. On the other side, all messages that Jinora receives from any of the user is sent back to Slack.

##Licence
Jinora is licenced under the [MIT Licence](http://nemo.mit-license.org/).

##Credits
- Artwork by [peachei.deviantart.com](http://peachei.deviantart.com/art/Older-Jinora-317463839)