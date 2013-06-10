
window.SliderMover = class SliderMover
  constructor: ->
    @go_url = '/crawler/omni.json'
    @stop_url = "/crawler/stop"
    @skip_count = 0
    @same_command_skip_count = 10
    @command_pending = false
  move_crawler: =>
    if @command_pending == true
      console.log "Command still pending..."
      if @skip_count-- > 0
        return true
    else
      @command_pending = true
    drive_train = {}
    steering = {}
    speedValue = ($ '#speed')[0].value
    drive_train.direction =
      if speedValue > 0
        'fwd'
      else
        'rev'

    drive_train.speed = Math.abs(speedValue) / 100
    steeringValue = ($ '#steering')[0].value
    steering.direction =
      if steeringValue > 0
        'right'
      else
        'left'
    steering.position = Math.abs steeringValue / 100
    @send_omni_command drive_train, steering

  send_stop_command: () =>
    console.log @stop_url
    $.get @stop_url,undefined ,(data,text_status) =>
      @command_pending = false
      console.log "stop command done"
      return true

  send_omni_command: (drive_train, steering) ->
    data = "turn #{steering.direction} #{steering.position}"
    if drive_train.speed == 0
      data += ";stop;"
    else
    data += ";dir #{drive_train.direction};speed #{drive_train.speed};"
    if @last_command == data
      if @skip_count-- > 0
        @command_pending = false
        return true
    console.log "Doing it!!!"
    @skip_count = @same_command_skip_count
    @last_command = data
    console.log data
    jQuery.get @go_url, {command_string: data}, =>
      @command_pending = false
      console.log "command done...."
      return true

 (jQuery document).ready ->
  window.crawler = new SliderMover()
  ($ '#speed').mouseup =>
    ($ '#speed')[0].value = 0
    return true
  ($ '#speed').bind 'touchend', =>
    ($ '#speed')[0].value = 0
    return true
  ($ '#steering').mouseup =>
    ($ '#steering')[0].value = 0
    return true
  ($ '#steering').bind 'touchend', =>
    ($ '#steering')[0].value = 0
    return true
#  window.crawler.send_stop_command()
  setInterval window.crawler.move_crawler ,500


