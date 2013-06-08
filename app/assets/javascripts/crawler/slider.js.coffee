($ document).ready ->
  crawler = new SliderMover()
  ($ '#speed').change =>
    crawler.move_crawler()
  ($ '#speed').mouseup =>
    ($ '#speed')[0].value = 0
    ($ '#speed').change()
  ($ '#speed').bind 'touchend', =>
    ($ '#speed')[0].value = 0
    ($ '#speed').change()
  ($ '#speed').change()

  ($ '#steering').change =>
    crawler.move_crawler()
  ($ '#steering').mouseup =>
    ($ '#steering')[0].value = 0
    ($ '#steering').change()
  ($ '#steering').bind 'touchend', =>
    ($ '#steering')[0].value = 0
    ($ '#steering').change()
  ($ '#steering').change()

window.SliderMover = class SliderMover
  constructor: ->
    @command_pending = false
  move_crawler: ->
    drive_train = {}
    steering = {}
    speedValue = ($ '#speed')[0].value
    drive_train.direction =
      if speed > 0
        'fwd'
      else
        'rev'
#    console.log "move_crawler",@last_x_distance, @last_y_distance, @start_x, @start_y, @move_x, @move_y
    drive_train.speed = Math.abs(speedValue) / 100
    steeringValue = ($ '#steering')[0].value
    steering.direction =
      if steeringValue > 0
        'left'
      else
        'right'
    steering.position = Math.abs steeringValue
    @send_omni_command drive_train, steering

  send_stop_command: () ->
    url = "/crawler/stop"
    $.get url,undefined ,(data,text_status) =>
      console.log url

  send_omni_command: (drive_train, steering) ->
    if @command_pending == true
      @command_pending = false
      return
    data = "turn #{steering.direction} #{steering.position};dir #{drive_train.direction};speed #{drive_train.speed;}"
    url = '/crawler/omni.json'
    @command_pending = true
    jQuery.get url, {command_string: data}, ->
      @command_pending = false
