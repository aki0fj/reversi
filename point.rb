$KCODE = "s"
#
# Point of Disc
#
class Point
  attr_reader :x, :y
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

