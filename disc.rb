# -*- coding: utf-8 -*-
#
# Disc
#
class Disc < Point
  BLACK = 1
  EMPTY = 0  # value of null
  WHITE = -1
  WALL = 2
  attr_accessor :x, :y, :color

  def initialize(x = 0, y = 0, color = EMPTY)
    super(x, y)
    @color = color
  end

end

