var socket = io.connect();
var userName = prompt("Enter your username");

$(function(){
  // Compile template function
  var messageFn = doT.template($('#template-message').text());

  // Attach event handler
  $('#message-input').keypress(function(e){
    if(e.which == 13){
      var $input = $(this);
      socket.emit('chat:msg', {message: $input.val(), classes:"", nick: userName});
      $input.val("");
    }
  })

  // Handle a chat message
  socket.on('chat:msg', function(data){
    console.log(data);
    var html = messageFn({classes: '', message: data.message, nick: data.nick});
    $('.channel-log tbody').append(html);
  })
});