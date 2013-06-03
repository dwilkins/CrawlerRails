class CrawlerController < ApplicationController

  respond_to :html, :json
  def index
#	`/usr/bin/stty 115200 raw < /dev/ttyUSB0`
  end

  # dir/:direction
  # where :direction is fwd or rev
  def dir
    @direction = params[:direction]
    @message = ""
    if @direction
      @message = arduino_command "dir #{@direction}"
    end
    respond_with(@message) do |format|
      format.json { render text: @message }
    end
  end
  # speed/:speed
  # where :speed is a number between 0 and 1 inclusive
  def speed
    @speed = params[:speed]
    if @speed
      @message = arduino_command "speed #{@speed}"
    end
    respond_with(@message) do |format|
      format.json { render text: @message }
    end
  end

  def stop
    @message = arduino_command "stop"
    respond_with(@message) do |format|
      format.json { render text: @message }
    end
  end
  # turn/:direction/:position
  # where :direction is left or right and
  # :position is a percentage with 0 being in the center and 1 being to the far left or right
  def turn
    @direction = params[:direction]
    @position = params[:position]
    if @direction && @position
      @message = arduino_command "turn #{@direction} #{@position}"
    end
    respond_with(@message) do |format|
      format.json { render text: @message }
    end
  end
  # string/:command_string
  def omni
    @message = arduino_command params[:command_string]
    respond_with(@message) do |format|
      format.json { render text: @message }
    end
  end

  private

  @arduino = nil
  @arduino_file = "/dev/ttyUSB0"
  def arduino_command command
    retval = "@arduino_file does not exist"
    if File.exists? "/dev/ttyUSB0"
      SerialPort.open("/dev/ttyUSB0", {baud: 300, databits: 8, stopbits: 1}) do |f|
	f.baud = 115200
        f.flow_control = SerialPort::NONE
        f.read_timeout = -1
        f.write command + "\n"
        retval = f.read
      end
    end
    Rails.logger.info(retval)
    retval
  end



end
