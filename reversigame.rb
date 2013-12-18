# -*- encoding: utf-8 -*-
# reversigame.rb
 
require "ai"
require "consoleboard"
 
class GameException < Exception; end
class UndoException < GameException; end
class ExitException < GameException; end
class GameOverException < GameException; end
 
class Player
  def on_turn(board)
  end
end
 
class HumanPlayer < Player
  def on_turn(board)
    if board.get_movable_pos.empty?
      puts "passed your turn"
      board.pass
      return
    end
 
    loop do
      puts "input point ex.\"f5\" or (u:undo/x:exit):"
      input = gets
      input.chomp!.downcase!
 
      case input
      when "u"
        puts "undo processing..."
        board.undo
        board.undo
        board.undo while board.get_movable_pos.empty?
        return
      when "x"
        puts "exiting.."
        exit
      else
        begin
          point = Point[input]
        rescue
          puts "invalid input"
          next
        end
      end
 
      unless board.move(point)
        puts "cannot put there"
        next
      end
 
      break
    end
  end
end
 
class AIPlayer < Player
  def initialize
    @ai = AlphaBetaAI.new
  end
 
  def on_turn(board)
    puts "thinking now..."
    e = @ai.move(board)
 
    printf("candidate position:%s value:%5d\n", board.get_history.last.to_s, e )
  end
end
 
board = ConsoleBoard.new
 
player = {}
player[1] = AIPlayer.new
player[-1] = AIPlayer.new
 
 
loop do
  board.print_board
  print "x: #{board.count_disc(Disc::BLACK)} "
  print "o: #{board.count_disc(Disc::WHITE)} "
  puts "EMPTY#{board.count_disc(Disc::EMPTY)}"
  msg = board.get_current_color == 1 ? "Black(x)" : "White(o)"
  puts "turn=#{board.get_turns + 1}  #{msg}"
  player[board.get_current_color].on_turn(board)
  puts
 
  if board.is_gameover
    board.print_board
    puts "Game Over"
    puts "x: #{board.count_disc(Disc::BLACK)}"
    puts "o: #{board.count_disc(Disc::WHITE)}"
    break
  end
end
