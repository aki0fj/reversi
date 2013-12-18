# -*- coding: utf-8 -*-
# bookmanager.rb
 
require 'point'
require 'coordinatestransformer'
 
class BookManager
 
  BOOK_FILE_NAME = "reversi.book"
 
  class Node
    attr_accessor :child, :sibling, :point
 
    def initialize
      @child = nil
      @sibling = nil
      @point = Point.new
    end
  end
 
  attr_accessor :root
 
  def initialize
    @root = Node.new
    @root.point = Point["f5"]
 
    File.open(BOOK_FILE_NAME) {|f|
      while line = f.gets
        book = []
        line.chomp!
 
        0.step(line.size - 1, 2) do |i|
          point = Point[line[i, 2]]
          book << point
        end
 
        add(book)
      end
    }
  end
 
  #
  # find pattern from book
  #
  def find(board)
    node = @root
    history = board.get_history
 
    if history.empty?
      return board.get_movable_pos
    end
    first = history.first
    transformer = CoordinatesTransformer.new(first)
 
    # transform coordinate for start "f5"
    normalized = []
    for i in 0...history.size
      point = history[i]
      point = transformer.normalize(point)
      normalized << point
    end
 
    # match history and book
    for i in 1...normalized.size
      node = node.child
      point = normalized[i]
 
      until node.nil?
        break if node.point.equals(point)
        node = node.sibling
      end
 
      if node.nil?  # not match
        return board.get_movable_pos
      end
    end
 
    # 
    if node.child.nil?
      return board.get_movable_pos
    end
    next_move = get_next_move(node)
 
    # restore coordinate
    next_move = transformer.denormalize(next_move)
    v = []
    v << next_move
 
    return v
  end
 
   private
 
  #
  # add book to tree of book
  # book[0] node = f5
  #
  def add(book)
    node = @root
 
    for i in 1...book.size
      new_point = book[i]
 
      if node.child.nil?  # new book
        node.child = Node.new
        node = node.child
        node.point.y = new_point.y
        node.point.x = new_point.x
      else  # search brother node
        node = node.child
        while true
          # find node in database
          break if node.point.equals(new_point)
 
          if node.sibling.nil?  # new node
            node.sibling = Node.new
            node = node.sibling
            node.point.y = new_point.y
            node.point.x = new_point.x
            break
          end
 
          node = node.sibling
        end
      end
    end
  end
 
  #
  # get next by the book
  #
  def get_next_move(node)
    candidates = []
 
    target = node.child
    until target.nil?
      candidates << target.point
      target = target.sibling
    end
 
    index = rand * candidates.size
    point = candidates[index]
 
    return Point.new(point.y, point.x)
  end
end
 
if __FILE__ == $0
  require 'board'
  bm = BookManager.new
  b = Board.new
  b.move(Point["f5"])
  b.move(Point["f6"])
  b.move(Point["e6"])
  b.move(Point["f4"])
  b.move(Point["e3"])
  puts bm.find(b).to_s
end
