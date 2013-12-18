# -*- coding: utf-8 -*-
# colorstorage.rb

#
# Infomation of Disc(by color)
#
class ColorStorage
  def initialize
    @data = {}
  end

  def get(color)
    @data[color]
  end

  def set(color, value)
    @data[color] = value
  end
end

