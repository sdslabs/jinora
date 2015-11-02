#jinora

jinora is a simple slack-backed chat application that proxies messages to and fro between slack and an anonymous chat platform. It allows your team to maintain a `#public` channel where anonymous users can come and talk to your entire team. You can then direct users wanting support, for example, to your jinora instance where you can help them resolve the issue over chat. 

No more need to having your team monitor IRC or Olark, it can all be done in Slack.

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy?template=https://github.com/sdslabs/jinora)

![Jinora artwork by peachei](https://i.imgur.com/WNRjxyN.jpg)

#[LIVE DEMO](http://chat.sdslabs.co)

##Features

1. Make a truly public channel in Slack (no need of a paid plan)
2. Emoji support
3. Translates all #channel hashtags and user @mentions properly
4. Messages sent from Slack are highlighted as official
5. Circular buffer that stores messages in memory (configurable limit)
6. Supports shadow-banning of users. Also nicks can be reserved by adding them to your [jsonblob](https://jsonblob.com).
7. Announcements can be made by team members which are visible to all clients.

##Setup Instructions

Configuration Options:

- **OUTGOING_TOKEN** Service Token from Slack's outgoing webhook
- **INCOMING_HOOK_URL** URL from Slack's incoming webhook
- **SESSION_SECRET** Session secret key (currently useless)
- **API_TOKEN** API Token for the slack team. Generated at <https://api.slack.com/web> (scroll to bottom). Bot users tokens may work, but have not been tested.
- **BUFFER_SIZE** Number of messages to keep in memory. This is automatically rotated and lost on reboots. Recommended value is 500-1000
- **SLACK_CHANNEL** Name of slack channel to send messages to. Default is "public".
- **BANNED_CHANNEL** Name of slack channel to send messages from banned users. Default is "public-hell".
- **RESERVED_NICKS_URL** Link to your jsonblob url `/api/jsonblob/<blobid>`
- **ORGANIZATION_NAME** Name of your organization. The title and heading of the page will be "Chat with <ORGANIZTION_NAME>"

These configuration options can either be provided via a `.env` file in development, or via Heroku config variables, if you are deploying to Heroku. A sample env file is provided in `.env.sample`.

###Slack-side configuration
1. Create a `#public` channel (could be called anything).
2. Create an outgoing webhook that listens only on `#public`.
3. Create an incoming webhook, and note down its URL.
4. Create a `#public-hell` channel (could be called anything).

Screenshots for a better understanding (outgoing and then incoming):

![Outgoing Webhook](http://i.imgur.com/dja9jqa.png)

![Incoming Webhook](http://i.imgur.com/iCDEAok.png)

![JsonBlob Sample](http://i.imgur.com/Cpo3M2i.png)

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

### How to ban?
> Read this [wiki](https://github.com/sdslabs/jinora/wiki/Banning-nicks-and-sessions)

### How to make announcements?

Announcements can be made by typing `!announce some_announcement` in your public channel where some_announcement is to be replaced by some text. Anouncements are sent in real time to all clients and dispayed in an announcement area at the top right. You can remove announcement by typing `!announce -`.

Remember that messages prefixed with `!` are commands interpreted by jinora, and these messages are not sent to clients. You can see a list of all jinora commands by entering `!help` in the public channel.

#Upgrading

Make sure you upgrade to 2.0.1 atleast. To upgrade from 1.x to 2.x, follow these steps:

1. Go to your incoming webhook and note down the URL
2. Go to heroku config and set the following variables:  
```
INCOMING_HOOK_URL=https://hooks.slack.com/services/WHAT_YOU_COPIED
BUFFER_SIZE=1000
SLACK_CHANNEL=public
BASE_URL=https://jinora.herokuapp.com #Replace this with your base url
```
3. Push the update.
4. You can remove the old `INCOMING_TOKEN` config.

##Licence
Jinora is licenced under the [MIT Licence](http://nemo.mit-license.org/).

##Credits
Artwork by [peachei.deviantart.com](http://peachei.deviantart.com/art/Older-Jinora-317463839)

The polymer source is based on [paper-chat](https://github.com/pubnub/paper-chat) by pubnub.
