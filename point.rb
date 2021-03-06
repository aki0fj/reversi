# -*- coding: utf-8 -*-
# point.rb

#
# Point of Disc
#
class Point
  attr_accessor :x, :y
  def initialize(x = 0, y = 0)
    @x = x
    @y = y
  end

  def to_s
    s = ""
    s << ("a".bytes.to_a[0] + @x - 1).chr
    s << @y.to_s
  end
end

