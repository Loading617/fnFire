require 'glimmer-dsl-swt'
require 'ffi'

class InputEvent < FFI::Struct
  layout :tv_sec, :long,
         :tv_usec, :long,
         :type, :ushort,
         :code, :ushort,
         :value, :int
end

MEDIA_KEYS = {
  164 => 'Play/Pause',
  163 => 'Next Track',
  165 => 'Previous Track',
  115 => 'Volume Up',
  114 => 'Volume Down'
}

class fnFire
  include Glimmer::UI::CustomShell

  attr_accessor :key_bindings, :log_output

  def initialize
    @key_bindings = {
      'Play/Pause' => 'Not set',
      'Next Track' => 'Not set',
      'Previous Track' => 'Not set',
      'Volume Up' => 'Not set',
      'Volume Down' => 'Not set'
    }
    @log_output = ""
    @running = true
    start_fn_key_detection
  end

  shell {
    text 'fnFire'
    minimum_size 400, 300
    grid_layout

    label {
      text "Bind function keys to media actions"
    }

    @key_bindings.each do |action, key|
      composite {
        grid_layout 2, false
        layout_data :fill, :center, true, false

        label {
          text "#{action}:"
          layout_data :fill, :center, true, false
        }

        text {
          text key
          layout_data :fill, :center, true, false
          editable false

          on_mouse_down do
            text_widget = self
            Thread.new do
              Glimmer::SWT::DisplayProxy.instance.async_exec do
                text_widget.text = "Press any key..."
              end
              char = STDIN.getch rescue nil
              Glimmer::SWT::DisplayProxy.instance.async_exec do
                if char
                  key_bindings[action] = char.upcase
                  text_widget.text = char.upcase
                  @log_output += "Bound #{action} to #{char.upcase}\n"
                else
                  text_widget.text = "Failed"
                end
              end
            end
          end
        }
      }
    end

    button {
      text 'Simulate Key Press'
      layout_data :center, :center, false, false
      on_widget_selected do
        simulate_key_event
      end
    }

    text(:multi, :read_only, :wrap, :border, :v_scroll) {
      layout_data :fill, :fill, true, true
      text bind(self, :log_output)
    }

    on_swt_close {
      @running = false
    }
  }

  def simulate_key_event
    pressed_key = 'P'
    matched = @key_bindings.find { |_, v| v == pressed_key }
    if matched
      action = matched[0]
      @log_output += "Detected key #{pressed_key}, triggered: #{action}\n"
    else
      @log_output += "Detected key #{pressed_key}, no action bound\n"
    end
  end

  def start_fn_key_detection
    Thread.new do
      input_devices = Dir["/dev/input/event*"]
      readers = input_devices.map do |device|
        begin
          File.open(device, 'rb')
        rescue Errno::EACCES
          nil
        end
      end.compact

      loop do
        break unless @running

        readers.each do |f|
          begin
            data = f.read(24)
            next unless data && data.bytesize == 24

            event = InputEvent.new(data)
            if event[:type] == 1 && event[:value] == 1 # key down
              if MEDIA_KEYS.key?(event[:code])
                Glimmer::SWT::DisplayProxy.instance.async_exec do
                  @log_output += "Auto-detected Fn key: #{MEDIA_KEYS[event[:code]]}\n"
                end
              end
            end
          rescue IOError, EOFError
            next
          end
        end

        sleep(0.05)
      end

      readers.each(&:close)
    end
  end
end

fnFire.new.open
