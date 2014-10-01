var socket = io.connect(document.location.origin,{
  reconnectionDelay: 200,
  reconnectionDelayMax: 1000
});
// Convert smileys to emoji as well
emojione.ascii = true;

var userName = prompt("Enter your username");

$(function(){

  // Compile template function
  var template = $('#template-message').text();
  Mustache.parse(template);

  var app = {
    chatHandler: function(data){
      var timestamp = new Date(data.timestamp).toISOString();
      // Escape the message and run it through emojione
      var message = emojione.shortnameToImage(Mustache.escape(data.message));
      var templateData = {
        classes: data.classes,
        message: message,
        nick: data.nick,
        timestamp: timestamp
      };
      var html = Mustache.render(template, templateData);
      $el = $(html);
      $('.channel-log tbody').append($el);
      $el.find('.date').timeago();
    },
    scroll: function(){
      $('.channel-log').animate({
        scrollTop: $('.channel-log')[0].scrollHeight
      });
    }
  }

  // Attach event handler
  $('#message-input').keydown(function(e){
    var $input = $(this);
    if(e.which == 13){
      if(socket.socket.connected===false){
        alert('Please wait while we reconnect');
        return;
      }
      if($input.val().trim() !== ""){
        socket.emit('chat:msg', {message: $input.val(), classes:"", nick: userName});
        $input.val("");
      }
      e.preventDefault();
    }
  }).focus();

  // Handle a chat message
  socket.on('chat:msg', function(data){
    app.chatHandler(data);
    app.scroll();
  });

  socket.on('chat:log', function(msgs){
    for(i in msgs){
      var msg = msgs[i];
      app.chatHandler(msg);
    }
    // Scroll to Bottom after everything's done
    app.scroll();
  });

  socket.on('connect', function(){
    socket.emit('chat:demand');
  });
  socket.on('reconnect', function(){
    $('#message-input').removeClass('disconnected').attr('placeholder', "Message");
  });
  socket.on('disconnect', function(){
    $('#message-input').addClass('disconnected').attr('placeholder', "Disconnected");
  });
});