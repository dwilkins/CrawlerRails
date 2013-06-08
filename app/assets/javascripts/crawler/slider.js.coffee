($ document).ready ->
  window.crawler = new SliderMover()
  ($ '#speed').change =>
    window.crawler.move_crawler()
    return true
  ($ '#speed').mouseup =>
    ($ '#speed')[0].value = 0
    ($ '#speed').change()
    window.crawler.send_stop_command()
    return true
  ($ '#speed').bind 'touchend', =>
    ($ '#speed')[0].value = 0
    ($ '#speed').change()
    window.crawler.send_stop_command()
    return true

  ($ '#steering').change =>
    window.crawler.move_crawler()
  ($ '#steering').mouseup =>
    ($ '#steering')[0].value = 0
#    ($ '#steering').change()
    window.crawler.move_crawler()
  ($ '#steering').bind 'touchend', =>
    ($ '#steering')[0].value = 0
    return true
#    ($ '#steering').change()
    window.crawler.move_crawler()
  window.crawler.send_stop_command()

window.SliderMover = class SliderMover
  constructor: ->
    @go_url = '/crawler/omni.json'
    @stop_url = "/crawler/stop"
    @command_pending = false
    @pending_command = ""
    @pending_url = ""
  move_crawler: ->
    drive_train = {}
    steering = {}
    speedValue = ($ '#speed')[0].value
    drive_train.direction =
      if speedValue > 0
        'fwd'
      else
        'rev'

    drive_train.speed = Math.abs(speedValue) / 100
#    if drive_train.speed == 0
#      @send_stop_command()
    steeringValue = ($ '#steering')[0].value
    steering.direction =
      if steeringValue > 0
        'right'
      else
        'left'
    steering.position = Math.abs steeringValue / 100
    @send_omni_command drive_train, steering

  send_stop_command: () ->
    @pending_command = ""
    @pending_command = @stop_url
    @command_pending = false
    $.get @stop_url,undefined ,(data,text_status) =>
      console.log @stop_url

  send_omni_command: (drive_train, steering) =>
    data = "turn #{steering.direction} #{steering.position}"
    if drive_train.speed > 0
      data += ";dir #{drive_train.direction};speed #{drive_train.speed};"
    console.log data
    if @command_pending
      console.log "Dang!   @command_pending  is true - returning"
      @pending_command = data
      @pending_url = @go_url
      setTimeout =>
        @send_pending_command()
      ,1000
      return
    @command_pending = true
    @pending_command = ""
    @pending_url = ""
    jQuery.get @go_url, {command_string: data}, =>
      console.log "command done...."
      @command_pending = false

  send_pending_command: =>
    if @command_pending
      setTimeout =>
        @send_pending_command
      , 1000
      return
    if @pending_url.length > 0
      @command_pending = true
      console.log "Sending pending command - " + @pending_command
      jQuery.get @pending_url, {command_string: @pending_command}, =>
        console.log "command done...."
        @pending_command = ""
        @pending_url = ""
        @command_pending = false
