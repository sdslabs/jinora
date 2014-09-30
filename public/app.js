var socket = io.connect();
var userName = prompt("Enter your username");

$(function(){
  // Compile template function
  var template = $('#template-message').text();
  Mustache.parse(template);
  // Attach event handler
  $('#message-input').keydown(function(e){
    var $input = $(this);
    if(e.which == 13){
      if($input.val().trim() != ""){
        socket.emit('chat:msg', {message: $input.val(), classes:"", nick: userName});
        $input.val("");
      }
      e.preventDefault();
    }
  }).focus();

  // Handle a chat message
  socket.on('chat:msg', function(data){
    var data = {
      classes: '', message: data.message, nick: data.nick, timestamp: data.timestamp
    };
    var html = Mustache.render(template, data);
    $el = $(html);
    $('.channel-log tbody').append($el);
    $el.find('.date').timeago();
  })

  socket.on('connect', function(){
    socket.emit('chat:demand');
  })
});