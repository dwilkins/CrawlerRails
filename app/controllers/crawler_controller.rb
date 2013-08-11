class CrawlerController < ApplicationController
  before_filter :set_as_private

  def set_as_private
    expires_now
  end

  respond_to :html, :json
  def index
  end
  def slider
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


  def image
    respond_with() do |format|
      format.jpg {
        `/usr/bin/fswebcam -d /dev/video0 #{Rails.root}/tmp/camera.jpg`
        send_file "#{Rails.root}/tmp/camera.jpg", :type => 'image/jpeg', :disposition => 'inline'
      }
      format.jpg {
        `/usr/bin/fswebcam -d /dev/video0 #{Rails.root}/tmp/camera.png`
        send_file "#{Rails.root}/tmp/camera.png", :type => 'image/png', :disposition => 'inline'
      }
    end
  end


  private

  @@arduino = nil
  @@arduino_file = "/dev/ttyUSB0"
  def old_arduino_command command
    retval = "@arduino_file does not exist"
    if File.exists? "/dev/ttyUSB0"
      SerialPort.open("/dev/ttyUSB0", {baud: 300, databits: 8, stopbits: 1}) do |f|
	f.baud = 115200
        f.flow_control = SerialPort::NONE
        f.read_timeout = 500
        f.write command + "\n"
        retval = f.read
      end
    end
    Rails.logger.info(retval)
    retval
  end
  def arduino_command command
    candidate_files = ["/dev/ttyUSB0","/dev/ttyUSB1","/dev/ttyACM0"]
    retval = "@arduino_file does not exist"
    if @@arduino.nil? || @@arduino.closed?
      candidate_files.each do |cf|
        begin
          if File.exists?(cf)
            Rails.logger.error("*****************************Opening the Serial Port...#{cf}")
            @@arduino = SerialPort.new("/dev/ttyUSB0", {baud: 300, databits: 8, stopbits: 1})
            @@arduino.baud = 115200
            @@arduino.flow_control = SerialPort::NONE
            @@arduino.read_timeout = 50
            break
          end
        rescue Exception => e
        end
      end
    end
    if@@arduino.nil? || @@arduino.closed?
      @@arduino = nil
      return retval
    end
    @@arduino.write command + "\n"
    retval = ""
    retval = @@arduino.read
    Rails.logger.info(retval)
    retval
  end


  def close_arduino
    SerialPort.close(@@arduno)
  end

end

at_exit do
  if !CrawlerController.arduino.nil? && CrawlerController.arduino.closed?
    puts "Closing Arduino connection..."
    SerialPort.close(CrawlerController.arduino)
  end
end
