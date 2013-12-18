# -*- coding: utf-8 -*-
# boardtest.rb
 
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

  def get_history
    history = []
    @update_log.each do |update|
      history << ("a".bytes.to_a[0] + update[0].x - 1).chr + update[0].y.to_s
    end
    return history
  end
end
 
