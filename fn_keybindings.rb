def play_pause
  system("playerctl play-pause")
end

def next_track
  system("playerctl next")
end

def previous_track
  system("playerctl previous")
end

def volume_up
  system("pactl set-sink-volume @DEFAULT_SINK@ +5%")
end

def volume_down
  system("pactl set-sink-volume @DEFAULT_SINK@ -5%")
end

puts "Listening for key commands..."
loop do
  print "> "
  cmd = gets.chomp.downcase

  case cmd
  when "play", "pause", "toggle"
    play_pause
  when "next"
    next_track
  when "prev", "previous"
    previous_track
  when "volup"
    volume_up
  when "voldown"
    volume_down
  when "exit", "quit"
    break
  else
    puts "Unknown command: #{cmd}"
  end
end