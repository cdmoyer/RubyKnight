require 'profile'

load './board.rb'
load "./#{ARGV[0]}"

b = RubyKnight::Board.new

b.gen_legal_moves
