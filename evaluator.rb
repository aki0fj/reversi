# -*- coding: utf-8 -*-
# evaluator.rb

require './point'
require './board'

#
# Perfect Evaluator
#
class PerfectEvaluator
  def evaluate(board)
    board.get_current_color \
      * (board.count_disc(Disc::BLACK) - board.count_disc(Disc::WHITE))
  end
end

#
# Settlement Evaluator
#
class WLDEvaluator
  WIN = 1
  DRAW = 0
  LOSE = -1

  def evaluate(board)
    disc_diff = board.get_current_color \
      * (board.count_disc(Disc::BLACK) - board.count_disc(Disc::WHITE))
    if disc_diff > 0
      WIN
    elsif disc_diff < 0
      LOSE
    else
      DRAW
    end
  end
end

#
# Middle Evaluator
# + mobility count
# - liberty
# - wing
# + stable discs
# -
# -
#
class MidEvaluator
  #
  # Edge Parameter
  #
  class EdgeParam
    attr_accessor :stable, :wing, :mountain, :cmove

    def initialize
      @stable = 0   # count of stable discs
      @wing = 0     # count of wing
      @mountain = 0 # count of mountain
      @cmove = 0    # count of dangerous "c"
    end

    def set(param)
      @stable = param.stable
      @wing = param.wing
      @mountain = param.mountain
      @cmove = param.cmove
    end

    def add(param)
      @stable += param.stable
      @wing += param.wing
      @mountain += param.mountain
      @cmove += param.cmove
      return self
    end
  end

  #
  # Edge parameter by color
  #
  class EdgeStat
    attr_reader :data

    def initialize
      @data = {}
      [Disc::BLACK, Disc::WHITE, Disc::EMPTY].each do |color|
        @data[color] = EdgeParam.new
      end
    end

    def add(stat)
      @data.each do |color, param|
        param.add(stat.data[color])
      end
    end

    def get(color)
      @data[color]
    end
  end

  #
  # Cornor Parameter
  #
  class CornerParam
    attr_accessor :corner, :xmove

    def initialize
      @corner = 0 # count of discs on the cornor
      @xmove = 0 # count of dengerous "x"
    end
  end

  #
  # Conor Parameter by color
  #

  class CornerStat
    attr_reader :data

    def initialize
      @data = {}
      [Disc::BLACK, Disc::WHITE, Disc::EMPTY].each do |color|
        @data[color] = CornerParam.new
      end
    end

    def get(color)
      @data[color]
    end
  end

  #
  # Struct for Weight
  #
  Weight = Struct.new(
    :mobility_w,  
    :liberty_w,  
    :stable_w,  
    :wing_w,   
    :xmove_w,  
    :cmove_w  
  )

  #
  # count of combination of Edge pattern
  # 3 ** 8 = 6561
  #
  TABLE_SIZE = 6561

  # table of Edge parameter by color
  @@edge_table = Array.new(TABLE_SIZE){ EdgeStat.new }

  @@table_init = false

  def MidEvaluator.edge_table
    @@edge_table
  end

  attr_reader :eval_weight

  def initialize
    # make one edge
    unless @table_init
      line = Array.new(Board::BOARD_SIZE)
      generate_edge(line, 0)
      @@table_init = true
    end

    # set Weight
    @eval_weight = Weight.new
    @eval_weight.mobility_w = 67 
    @eval_weight.liberty_w = -13 
    @eval_weight.stable_w = 101 
    @eval_weight.wing_w = -308 
    @eval_weight.xmove_w = -449 
    @eval_weight.cmove_w = -552 
  end

  #
  # evaluate
  #
  def evaluate(board)
    edge_stat = nil
    corner_stat = nil
    result = nil

    # set edge stat
    edge_stat = @@edge_table[idx_top(board)]
    edge_stat.add(@@edge_table[idx_bottom(board)])
    edge_stat.add(@@edge_table[idx_right(board)])
    edge_stat.add(@@edge_table[idx_left(board)])

    corner_stat = eval_corner(board)  # set cornor stat

    # collect 2 count of stable disc on the cornor
    edge_stat.get(Disc::BLACK).stable \
      -= corner_stat.get(Disc::BLACK).corner
    edge_stat.get(Disc::WHITE).stable \
      -= corner_stat.get(Disc::WHITE).corner

    # combine parameters
    result = \
      edge_stat.get(Disc::BLACK).stable * @eval_weight.stable_w \
      - edge_stat.get(Disc::WHITE).stable * @eval_weight.stable_w \
      + edge_stat.get(Disc::BLACK).wing * @eval_weight.wing_w \
      - edge_stat.get(Disc::WHITE).wing * @eval_weight.wing_w \
      + corner_stat.get(Disc::BLACK).xmove * @eval_weight.xmove_w \
      - corner_stat.get(Disc::WHITE).xmove * @eval_weight.xmove_w \
      + edge_stat.get(Disc::BLACK).cmove * @eval_weight.cmove_w \
      - edge_stat.get(Disc::WHITE).cmove * @eval_weight.cmove_w

    # set liberty
    unless @eval_weight.liberty_w == 0
      liberty = count_liberty(board)
      result += liberty.get(Disc::BLACK) * @eval_weight.liberty_w
      result -= liberty.get(Disc::WHITE) * @eval_weight.liberty_w
    end

    # count mobility of current color
    result += \
      board.get_current_color \
      * board.get_movable_pos.size \
      * @eval_weight.mobility_w

    return board.get_current_color * result
  end

  #
  # generate @@edge_table
  #
  def generate_edge(edge, count)
    if count == Board::BOARD_SIZE   # end of edge
      stat = EdgeStat.new
      stat.get(Disc::BLACK).set(eval_edge(edge, Disc::BLACK))
      stat.get(Disc::WHITE).set(eval_edge(edge, Disc::WHITE))
      @@edge_table[idx_line(edge)] = stat

      return
    end

    #
    edge[count] = Disc::EMPTY
    generate_edge(edge, count + 1)

    edge[count] = Disc::BLACK
    generate_edge(edge, count + 1)

    edge[count] = Disc::WHITE
    generate_edge(edge, count + 1)

    return
  end

  def eval_edge(line, color)
    edge_param = EdgeParam.new

    # count wing etc..
    if line[0] == Disc::EMPTY and line[7] == Disc::EMPTY
      x = 2
      while x <= 5
        unless line[x] == color
          break
        end
        x += 1
      end
      if x == 6   # already made block
        if line[1] == color and line[6] == Disc::EMPTY
          edge_param.wing = 1
        elsif line[1] == Disc::EMPTY and line[6] == color
          edge_param.wing = 1
        elsif line[1] == color and line[6] == color
          edge_param.mountain = 1
        end
      else 
        if line[1] == color
          edge_param.cmove += 1
        end
        if line[6] == color
          edge_param.cmove += 1
        end
      end
    end

    # count stable discs
    # search left -> right
    for x in 0..7
      unless line[x] == color
        break
      end
      edge_param.stable += 1
    end

    if edge_param.stable < 8
      # search right -> left
      7.downto(0) do |x|
        unless line[x] == color
          break
        end
        edge_param.stable += 1
      end
    end

    return edge_param
  end

  #
  # eval cornor
  #
  def eval_corner(board)
    corner_stat = CornerStat.new

    corner_stat.get(Disc::BLACK).corner = 0
    corner_stat.get(Disc::BLACK).xmove = 0
    corner_stat.get(Disc::WHITE).corner = 0
    corner_stat.get(Disc::WHITE).xmove = 0

    point = Point.new

    # upper left
    point.y = 1
    point.x = 1
    corner_stat.get(board.get_color(point)).corner += 1
    if board.get_color(point) == Disc::EMPTY
      point.y = 2
      point.x = 2
      corner_stat.get(board.get_color(point)).xmove += 1
    end

    # lowoer left
    point.y = 8
    point.x = 1
    corner_stat.get(board.get_color(point)).corner += 1
    if board.get_color(point) == Disc::EMPTY
      point.y = 7
      point.x = 2
      corner_stat.get(board.get_color(point)).xmove += 1
    end

    # lower right
    point.y = 8
    point.x = 8
    corner_stat.get(board.get_color(point)).corner += 1
    if board.get_color(point) == Disc::EMPTY
      point.y = 7
      point.x = 7
      corner_stat.get(board.get_color(point)).xmove += 1
    end

    # upper right
    point.y = 1
    point.x = 8
    corner_stat.get(board.get_color(point)).corner += 1
    if board.get_color(point) == Disc::EMPTY
      point.y = 2
      point.x = 7
      corner_stat.get(board.get_color(point)).xmove += 1
    end

    return corner_stat
  end

  #
  # get index by edge
  #

  # index top
  def idx_top(board)
    index = 0
    m = 1
    point = Point.new(1, 8)
    Board::BOARD_SIZE.downto(1) do |i|
      point.x = i
      index += m * (board.get_color(point) + 1)
      m *= 3
    end

    return index
  end

  # index bottom
  def idx_bottom(board)
    index = 0
    m = 1
    point = Point.new(8, 8)
    Board::BOARD_SIZE.downto(1) do |i|
      point.x = i
      index += m * (board.get_color(point) + 1)
      m *= 3
    end

    return index
  end

  # index right
  def idx_right(board)
    index = 0
    m = 1
    point = Point.new(8, 8)
    Board::BOARD_SIZE.downto(1) do |i|
      point.y = i
      index += m * (board.get_color(point) + 1)
      m *= 3
    end

    return index
  end

  # index left
  def idx_left(board)
    index = 0
    m = 1
    point = Point.new(8, 1)
    Board::BOARD_SIZE.downto(1) do |i|
      point.y = i
      index += m * (board.get_color(point) + 1)
      m *= 3
    end

    return index
  end

  #
  # count liberty
  #
  def count_liberty(board)
    liberty = ColorStorage.new
    liberty.set(Disc::BLACK, 0)
    liberty.set(Disc::WHITE, 0)
    liberty.set(Disc::EMPTY, 0)

    point = Point.new

    for y in 1..Board::BOARD_SIZE
      point.y = y
      for x in 1..Board::BOARD_SIZE
        point.x = x
        l = liberty.get(board.get_color(point))
        l += board.get_liberty(point)
        liberty.set(board.get_color(point), l)
      end
    end

    return liberty
  end

  #
  # index line
  #
  # [-1, -1, -1, -1, -1, -1, -1, -1] => 0
  # [-1, -1, -1, -1, -1, -1, -1, 0] => 1
  # [1, 1, 1, 1, 1, 1, 1, 1] => 6560
  def idx_line(line)
    return 3 * (3 * (3 * (3 * (3 * (3 * (3 * (line[0] + 1) + line[1] + 1) + line[2] + 1) + line[3] + 1) + line[4] + 1) + line[5] + 1) + line[6] + 1)+ line[7] + 1
  end
end
