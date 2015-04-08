class window.Notify

  @update: ()->
   ++@count if document[@visibilityEvent.property]
   if @Supported
      @favicon.badge @count
   else
        document.title '(' + @count+ ') New Messsages'
        
    
  @clear: ()->
    @count = 0
    if @Supported
      @favicon.reset()
    else 
      document.title 'Chat with SDSLabs'

  # This is called
  # whenever visibility is changed
  @toggle: ()=>
    @clear() unless document[@visibilityEvent.property]

  @setup: ()->
    @count = 0
    @Supported = true
    if bowser.msie && bowser.version <=10
      @Supported= false
    if @Supported
      @favicon = new Favico
        animation: 'popFade'
        bgColor: '#d00'
        textColor: '#fff'
        fontFamily: 'Arial'
        fontStyle: 'bold'

    visibilityChangeProperty =
      hidden: 'visibilitychange', # Opera 12.10 and Firefox 18 and later support
      mozHidden: 'mozvisibilitychange', # Older firefox?
      msHidden: 'msvisibilitychange', # Internet Explorer
      webkitHidden: 'webkitvisibilitychange' # Webkit based browsers

    for property, e of visibilityChangeProperty
      if document[property]?
        @visibilityEvent =
          property: property,
          event: e

    $(document).on @visibilityEvent.event, Notify.toggle if @visibilityEvent

Notify.setup()
