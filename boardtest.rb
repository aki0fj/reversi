$KCODE = "s"
 
require "board"
 
class ConsoleBoard < Board
  def print_board
    y_str = %w(1 2 3 4 5 6 7 8)
    puts " abcdefgh"
    for y in 1..8
      print y_str.shift
      for x in 1..8
        case get_color(Point.new(x, y))
        when Disc::BLACK
          print "x"
        when Disc::WHITE
          print "o"
        else
          print " "
        end
      end
      puts
    end
  end
end
 
board = ConsoleBoard.new
 
def str_to_ary(str)
  if str.size < 2
    return [0, 0]
  else
    x = str.bytes.to_a[0] - "a".bytes.to_a[0] + 1
    y = str[1].chr.to_i
    return [x, y]
  end
end
 
loop do
  board.print_board
 
  print "x: #{board.count_disc(Disc::BLACK)} "
  print "o: #{board.count_disc(Disc::WHITE)} "
  puts "emp:#{board.count_disc(Disc::EMPTY)}"
 
  player = board.get_current_color == Disc::BLACK ? "x" : "o"
  print "input position turns=#{board.get_turns + 1} player=#{player}: "
 
=begin
  input_point = board.get_movable_pos.first
  if input_point.nil?
    board.pass
    puts "pass"
    puts
    next
  else
    puts input_point.to_s
    puts
  end
=end
 
  input = STDIN.gets
  case input.chomp!
  when "p"
    unless board.pass
      puts "cannot pass"
    end
    next
  when "u"
    board.undo
    next
  when "q"
    break
  end
 
  begin
    x, y = str_to_ary(input)
    input_point = Point.new(x, y)
  rescue
    puts "position format is invalid"
    next
  end
 
  if not board.move(input_point)
    puts "position is not available"
    next
  end
 
  if board.is_gameover
    puts "Game Over"
 
    board.print_board
    print "x: #{board.count_disc(Disc::BLACK)} "
    print "o: #{board.count_disc(Disc::WHITE)} "
    if board.count_disc(Disc::BLACK) == board.count_disc(Disc::WHITE)
      puts "Draw"
    elsif board.count_disc(Disc::BLACK) > board.count_disc(Disc::WHITE)
      puts "x Win"
    else
      puts "o Win"
    end
    #board.movable_pos.each_with_index do |ary, i|
    #  printf "%3d=>%3d\n", i, ary.size
    #end
    break
  end
end
