# -*- cording: utf-8 -*-
# coordinatestransformer.rb
 
require 'point'
 
class CoordinatesTransformer
  def initialize(first)
    @rotate = 0
    @mirror = false
 
    if first.equals(Point["d3"])
      @rotate = 1
      @mirror = true
    elsif first.equals(Point["c4"])
      @rotate = 2
    elsif first.equals(Point["e6"])
      @rotate = -1
      @mirror = true
    end
  end
 
  #
  # transform coordinate start from f5
  #
  def normalize(point)
    new_point = rotate_point(point, @rotate)
    new_point = mirror_point(new_point) if @mirror
 
    return new_point
  end
 
  #
  # restore coordinate
  #
  def denormalize(point)
    new_point = Point.new(point.y, point.x)
    new_point = mirror_point(new_point) if @mirror
    new_point = rotate_point(new_point, -@rotate)
 
    return new_point
  end
 
  #
  # rotete coordinate (turn left 90dig by 1)
  #
  def rotate_point(old_point, rotate)
    rotate %= 4
    rotate += 4 if rotate < 0
    new_point = Point.new
 
    case rotate
    when 1
      new_point.y = Board::BOARD_SIZE - old_point.x + 1
      new_point.x = old_point.y
    when 2
      new_point.y = Board::BOARD_SIZE - old_point.y + 1
      new_point.x = Board::BOARD_SIZE - old_point.x + 1
    when 3
      new_point.y = old_point.x
      new_point.x = Board::BOARD_SIZE - old_point.y + 1
    else
      new_point.y = old_point.y
      new_point.x = old_point.x
    end
 
    return new_point
  end
 
  #
  # flip horizontal
  #
  def mirror_point(point)
    new_point = Point.new
    new_point.y = point.y
    new_point.x = Board::BOARD_SIZE - point.x + 1
 
    return new_point
  end
end
