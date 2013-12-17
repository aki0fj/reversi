﻿# -*- coding: utf-8 -*-
class AI
  def move(board)
  end
 
  PRESEARCH_DEPTH = 3
  NORMAL_DEPTH = 15
  WLD_DEPTH = 15
  PERFECT_DEPTH = 13
 
end
 
require 'point'
require 'disc'
require 'board'
require 'evaluator'
 
class AlphaBetaAI < AI
  MAX_VALUE = 2 ** 30 - 1
  MIN_VALUE = -(2 ** 30)
 
  class Move < Point
    attr_reader :e
    def initialize(x = 0, y = 0, e = 0)
      super(x, y)
      @e = e
    end
  end
 
  def move(board)
    movables = board.get_movable_pos
 
    if movables.empty?  # no settable position
      board.pass
      return
    end
 
    if movables.size == 1 # 1 settable position
      board.move(movables[0])
      return
    end
 
    sort(board, movables, PRESEARCH_DEPTH)  # sort before search
 
    if Board::MAX_TURNS - board.get_turns <= WLD_DEPTH
      limit = MAX_VALUE
    else
      limit = NORMAL_DEPTH
    end
 
    eval_max = MIN_VALUE
    for i in 0...movables.size
      board.move(movables[i])
      eval_tmp = -alphabeta(board, limit - 1, -MAX_VALUE, -MIN_VALUE)
      board.undo
 
      if eval_tmp > eval_max
        eval_max = eval_tmp
        point = movables[i]
      end
    end
 
    board.move(point)
  end
 
  # search game node by alphabeta method
  def alphabeta(board, limit, alpha, beta)
    if board.is_gameover or limit == 0
      return evaluate(board)
    end
 
    pos = board.get_movable_pos
 
    if pos.size == 0  # no settable position
      board.pass
      eval_tmp = -alphabeta(board, limit, -beta, -alpha)
      board.undo
      return eval_tmp
    end
 
    for i in 0...pos.size
      board.move(pos[i])
      eval_tmp = -alphabeta(board, limit - 1, -beta, -alpha)
      board.undo
      alpha = [alpha, eval_tmp].max
      if alpha >= beta  # beta node cut
        return alpha
      end
    end
 
    return alpha
  end
 
  def sort(board, movables, limit)
    moves = []
    for i in 0...movables.size
      point = movables[i]
      board.move(point)
      eval_tmp = -alphabeta(board, limit - 1, MIN_VALUE, MAX_VALUE)
      board.undo
      move = Move.new(point.x, point.y, eval_tmp)
      moves.push(move)
    end
    moves_sorted = moves.sort do |a, b|   # sort by evaluate
      b.e <=> a.e
    end
    movables.clear
    moves_sorted.each do |move|
      movables << move
    end
 
    return
  end
 
end
