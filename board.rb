# -*- coding: utf-8 -*-
# board.rb
 
require 'point'
require 'disc'
require 'colorstorage'
#
# Game Board
#
class Board
  BOARD_SIZE = 8
  MAX_TURNS = 60
 
  # direction
  NONE = 0
  UPPER = 1
  UPPER_LEFT = 2
  LEFT = 4
  LOWER_LEFT = 8
  LOWER = 16
  LOWER_RIGHT = 32
  RIGHT = 64
  UPPER_RIGHT = 128
 
  def initialize
    init
  end
 
  #
  # Set Board for Starting Game
  #
  def init
    # Set All Points to EMPTY
    @raw_board = Array.new(BOARD_SIZE + 2){
      Array.new(BOARD_SIZE + 2, Disc::EMPTY)
    }
 
    # Set Walls
    @raw_board[0].fill(Disc::WALL)
    @raw_board[BOARD_SIZE + 1].fill(Disc::WALL)
    @raw_board.each do |row|
      row[0] = Disc::WALL
      row[-1] = Disc::WALL
    end
 
    # Set Discs
    @raw_board[4][4] = Disc::WHITE
    @raw_board[5][5] = Disc::WHITE
    @raw_board[4][5] = Disc::BLACK
    @raw_board[5][4] = Disc::BLACK
 
    # Set Count of Colors
    @discs = ColorStorage.new
 
    @discs.set(Disc::BLACK, 2)
    @discs.set(Disc::WHITE, 2)
    @discs.set(Disc::EMPTY, BOARD_SIZE * BOARD_SIZE - 4)
 
    # turns (count from 0)
    @turns = 0
 
    # first turn is BLACK
    @current_color = Disc::BLACK 
 
    # initialize update log
    @update_log = []
 
    # settable Discs by turns
    @movable_pos = Array.new(MAX_TURNS + 1){[]}
 
    # check_mobility results by settable discs by turns
    @movable_dir = Array.new(MAX_TURNS + 1){
      Array.new(BOARD_SIZE + 2){
        Array.new(BOARD_SIZE + 2)
      }
    }
 
    # set @movable_pos[@turns], @movable_dir[@turns]
    init_movable
  end

  attr_reader :movable_pos

  #
  # Set Disc at point
  # return true when success
  # return false when failure
  #
  def move(point)
    if (point.x <= 0 or point.x > BOARD_SIZE or \
        point.y <= 0 or point.y > BOARD_SIZE or \
        @movable_dir[@turns][point.x][point.y] == NONE)
      return false
    end
 
    flip_discs(point) # set discs revers
    @turns += 1
    @current_color = -@current_color
    init_movable  # set @movable_pos[@turns], @movable_dir[@turns]
    return true
  end
 
  #
  # undo 1 turn
  #
  def undo
    return false if @turns == 0
    @current_color = -@current_color
    update = @update_log.pop
 
    if update.empty?  # previous turn is pass?
      # initialize @movable_pos, @movable_dir
      @movable_pos[@turns].clear
      for x in 1..BOARD_SIZE
        for y in 1..BOARD_SIZE
          @movable_dir[@turns][x][y] = NONE
        end
      end
    else  # previous turn is not pass?
      @turns -= 1
 
      p = update[0]
      @raw_board[p.x][p.y] = Disc::EMPTY  # erase disc
      for i in 1...update.size  # fliped disc of previous turn
        p = update[i]
        @raw_board[p.x][p.y] = -@current_color  # reverse disc
      end
 
      # reset count of colors
      disc_diff = update.size
      @discs.set(@current_color, @discs.get(@current_color) - disc_diff)
      @discs.set(-@current_color, @discs.get(-@current_color) + (disc_diff - 1))
      @discs.set(Disc::EMPTY, @discs.get(Disc::EMPTY) + 1)
    end
 
    return true
  end
 
  #
  # do pass
  # return true when success
  # return false when failure
  #
  def pass
    unless @movable_pos[@turns].size == 0
      return false
    end
 
    if is_gameover
      return false
    end
 
    @current_color = - @current_color
    @update_log << []
    init_movable
    return true
  end
 
  #
  # get color of point
  #
  def get_color(point)
    @raw_board[point.x][point.y]
  end
 
  #
  # get current color
  #
  def get_current_color
    @current_color
  end
 
  #
  # get turns
  #
  def get_turns
    @turns
  end
 
  #
  # judge Gameover
  #
  def is_gameover
    # turn is over
    if @turns == MAX_TURNS
      return true
    end
    
    unless @movable_pos[@turns].size == 0
      return false  # has settable point
    end
 
    disc = Disc.new
    disc.color = -@current_color  # another color
    for x in 1..BOARD_SIZE
      disc.x = x
      for y in 1..BOARD_SIZE
        disc.y = y
        unless check_mobility(disc) == NONE
          return false  # has settable point
        end
      end
    end
 
    return true
 
  end
 
  #
  # get count of color
  #
  def count_disc(color)
    @discs.get(color)
  end
 
  #
  # get movable point
  #
  def get_movable_pos
    @movable_pos[@turns]
  end
 
  #
  # put and fliped disc of previous turn
  #
  def get_update
    if @update_log.empty?
      return []
    else
      return @update_log.last
    end
  end
 
  private
 
  #
  # check disc settable
  #
  # return direction of flipable disc
  # return NONE when no flipable disc
  def check_mobility(disc)
    # point had disc
    unless @raw_board[disc.x][disc.y] == Disc::EMPTY
      return NONE
    end
    dir = NONE
 
    # upper disc is another color
    if check_dir(0, -1, disc)
      dir |= UPPER
    end
 
    # lower disc is another color
    if check_dir(0, 1, disc)
      dir |= LOWER
    end
 
    # left disc is another color
    if check_dir(-1, 0, disc)
      dir |= LEFT
    end
 
    # right disc is another color
    if check_dir(1, 0, disc)
      dir |= RIGHT
    end
 
    # upper right disc is another color
    if check_dir(1, -1, disc)
      dir |= UPPER_RIGHT
    end
 
    # upper left disc is another color
    if check_dir(-1, -1, disc)
      dir |= UPPER_LEFT
    end
 
    # lower left is another color
    if check_dir(-1, 1, disc)
      dir |= LOWER_LEFT
    end
 
    # lower right is another color
    if check_dir(1, 1, disc)
      dir |= LOWER_RIGHT
    end
 
    return dir
  end
 
  def check_dir(x, y, disc)
    flag = false
    while @raw_board[disc.x + x][disc.y + y] == -disc.color
      flag = true # this direction has another color
      x += x
      y += y
    end
    if flag && @raw_board[disc.x + x][disc.y + y] == disc.color
      true
    else
      false
    end
  end

  #
  # set @movable_pos[@turns], @movable_dir[@turns]
  def init_movable
    @movable_pos[@turns].clear
    for x in 1..BOARD_SIZE
      for y in 1..BOARD_SIZE
        disc = Disc.new(x, y, @current_color)
        dir = check_mobility(disc)
        unless dir == NONE
          @movable_pos[@turns] << disc
        end
        @movable_dir[@turns][x][y] = dir
      end
    end
  end
 
  #
  # flip discs
  #
  def flip_discs(point)
    dir = @movable_dir[@turns][point.x][point.y]
    update = []
    @raw_board[point.x][point.y] = @current_color
    update << Disc.new(point.x, point.y, @current_color)
 
    # upper
    unless (dir & UPPER) == NONE 
      y = point.y
      until @raw_board[point.x][y - 1] == @current_color
        y -= 1
        @raw_board[point.x][y] = @current_color
        update << Disc.new(point.x, y, @current_color)
      end
    end
 
    # lower
    unless (dir & LOWER) == NONE
      y = point.y
      until @raw_board[point.x][y + 1] == @current_color
        y += 1
        @raw_board[point.x][y] = @current_color
        update << Disc.new(point.x, y, @current_color)
      end
    end
 
    # left
    unless (dir & LEFT) == NONE
      x = point.x
      until @raw_board[x - 1][point.y] == @current_color
        x -= 1
        @raw_board[x][point.y] = @current_color
        update << Disc.new(x, point.y, @current_color)
      end
    end
 
    # right
    unless (dir & RIGHT) == NONE
      x = point.x
      until @raw_board[x + 1][point.y] == @current_color
        x += 1
        @raw_board[x][point.y] = @current_color
        update << Disc.new(x, point.y, @current_color)
      end
    end
 
    # upper right
    unless (dir & UPPER_RIGHT) == NONE
      x = point.x
      y = point.y
      until @raw_board[x + 1][y - 1] == @current_color
        x += 1
        y -= 1
        @raw_board[x][y] = @current_color
        update << Disc.new(x, y, @current_color)
      end
    end
 
    # upper left
    unless (dir & UPPER_LEFT) == NONE
      x = point.x
      y = point.y
      until @raw_board[x - 1][y - 1] == @current_color
        x -= 1
        y -= 1
        @raw_board[x][y] = @current_color
        update << Disc.new(x, y, @current_color)
      end
    end
 
    # lower left
    unless (dir & LOWER_LEFT) == NONE
      x = point.x
      y = point.y
      until @raw_board[x - 1][y + 1] == @current_color
        x -= 1
        y +=1
        @raw_board[x][y] = @current_color
        update << Disc.new(x, y, @current_color)
      end
    end
 
    # lower right
    unless (dir & LOWER_RIGHT) == NONE
      x = point.x
      y = point.y
      until @raw_board[x + 1][y + 1] == @current_color
        x += 1
        y += 1
        @raw_board[x][y] = @current_color
        update << Disc.new(x, y, @current_color)
      end
    end
 
    disc_diff = update.size
    @discs.set(@current_color, @discs.get(@current_color) + disc_diff)
    @discs.set(-@current_color, @discs.get(-@current_color) - (disc_diff - 1))
    @discs.set(Disc::EMPTY, @discs.get(Disc::EMPTY) - 1)
    @update_log << update
  end
end
