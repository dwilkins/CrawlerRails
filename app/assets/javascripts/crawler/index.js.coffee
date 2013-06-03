# Place all the behaviors and hooks related to the matching controller action here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

($ document).ready ->
  MicroEvent.mixin VirtualJoystick
  crawler = new Crawler()
  joystick = new VirtualJoystick({
    container	: document.getElementById('crawler-js-container'),
    baseElement: crawler.base_element(),
    stickElement: crawler.stick_element(),
    mouseSupport : true
    })
  joystick.bind '_onMove', (x,y) =>
    crawler.on_move x,y
  joystick.bind '_onDown', (x,y) =>
    crawler.on_start_move(x,y)
  joystick.bind '_onUp', () =>
    crawler.on_stop_move()

window.Crawler = class Crawler
  constructor: ->
    @last_drive_train = {
      direction: 'unknown',
      speed: -1,
      distance: 100000
    }
    @last_steering = {
      direction: 'unknown'
      position: -1,
      distance: 100000
      }
    @start_x = 0
    @start_y = 0
    @move_x = -1
    @move_y = -1
    @moving = false
    @important_command = ''
    @max_x_distance = 200
    @max_y_distance = 200
    @min_x_distance = 20
    @min_y_distance = 20
    @last_command = ''
    @last_response = ''
    @debug_element = ''


  base_element: ->
    canvas = document.createElement 'canvas'
    canvas.width  = 226
    canvas.height = 226

    ctx = canvas.getContext '2d'
    ctx.beginPath()
    ctx.strokeStyle = 'cyan'
    ctx.lineWidth = 6
    ctx.arc canvas.width / 2, canvas.width / 2, 100, 0, Math.PI*2, true
    ctx.stroke()

    ctx.beginPath()
    ctx.strokeStyle = 'cyan'
    ctx.lineWidth = 20
    ctx.arc canvas.width/2, canvas.width/2, 80, 0, Math.PI*2, true
    ctx.stroke()
    return canvas

  stick_element: ->
    canvas = document.createElement 'canvas'
    canvas.width  = 186
    canvas.height = 186
    ctx = canvas.getContext '2d'
    ctx.beginPath()
    ctx.strokeStyle = 'red'
    ctx.lineWidth = 20
    ctx.arc canvas.width/2, canvas.width/2, 80, 0, Math.PI*2, true
    ctx.stroke()
    ctx.beginPath()
    ctx.strokeStyle = 'red'
    ctx.lineWidth = 10
    ctx.arc canvas.width/2, canvas.width/2, 30, 0, Math.PI*2, true
    ctx.stroke()
    return canvas

  on_start_move: (x,y) ->
    @moving = true
    [@start_x, @start_y] = [x,y]
    [@move_x, @move_y] = [x,y]
    @last_x_distance = @last_y_distance = 0
    console.log "on_start_move ",x,y

  on_stop_move: ->
    @moving = false
    @send_stop_command()
    console.log "on_stop_move "

  on_move: (x,y) ->
    [@move_x, @move_y] = [x,y]
    @move_crawler()

  move_crawler: ->
    @last_x_distance = @start_x - @move_x
    @last_y_distance = @start_y - @move_y
    @last_x_distance =
      if Math.abs(@last_x_distance) > @max_x_distance
        @apply_sign @last_x_distance,@max_x_distance
      else
        @last_x_distance
    @last_y_distance =
      if Math.abs(@last_y_distance) > @max_y_distance
        @apply_sign @last_y_distance,@max_y_distance
      else
        @last_y_distance
    drive_train = {}
    steering = {}
    drive_train.direction =
      if @last_y_distance > 0
        'fwd'
      else
        'rev'
#    console.log "move_crawler",@last_x_distance, @last_y_distance, @start_x, @start_y, @move_x, @move_y
    drive_train.distance = @last_y_distance
    drive_train.speed = Math.abs(@last_y_distance) / @max_y_distance
    steering.distance = @last_x_distance
    steering.direction =
      if @last_x_distance > 0
        'left'
      else
        'right'
    steering.position = Math.abs(@last_x_distance) / @max_x_distance
    @send_omni_command drive_train, steering
#    @send_drive_train_command drive_train
#    @send_steering_command steering

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



  send_drive_train_command: (params) ->
    if @command_pending || ((params.direction == @last_drive_train.direction) && ((params.distance < @last_drive_train.distance + @min_y_distance) && (params.distance > @last_drive_train.distance - @min_y_distance)))
      return
    if @command_pending
      return
    if params.direction != @last_drive_train.direction
      @last_drive_train.direction = params.direction
      @last_drive_train.speed = params.speed
      @last_drive_train.distance = 0
      url = '/crawler/dir'
      data = {direction: @last_drive_train.direction}
      @last_command = url + "?direction=#{data.direction}"
    else
      @last_drive_train.speed = params.speed
      @last_drive_train.distance = params.distance
      url = '/crawler/speed'
      data = {speed: @last_drive_train.speed}
      @last_command = url + "?speed=#{data.speed}"
    @command_pending = true
    $.get url, data,(data,text_status) =>
      @finished(data,text_status)

  finished: (data,text_status) ->
    @last_response = data
    @command_pending = false

  send_steering_command: (params) ->
    if((params.direction == @last_steering.direction) && (params.distance > @last_steering.distance - @min_x_distance) && (params.distance < @last_steering.distance + @min_x_distance))
      return
    if @command_pending
      return
    @last_steering.direction = params.direction
    @last_steering.position = params.position
    @last_steering.distance = params.distance
    url = '/crawler/turn'
    data = {
      direction: @last_steering.direction,
      position: @last_steering.position
      }
    @last_command = url + "?direction=#{data.direction}&position=#{data.position}"
    @command_pending = true
    $.get url, data,(data,text_status) =>
      @finished(data,text_status)

  apply_sign: (x,num = 1) ->
    sign =
      if x >= 0
        1
      else
        -1
    num * sign
