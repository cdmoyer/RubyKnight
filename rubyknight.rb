#!/usr/bin/ruby

load 'board.rb'
load 'generator.rb'

b = RubyKnight::Board.new

puts "#{b.to_s}\n"
#['e2e4' , 'e7e5' , 'd2d3'].each do |move|
['e2e4','d7d5'].each do |move|
	b.cnotation_move move
	b.display
	#puts b.history.last.to_s
	puts
end

b.gen_moral_moves b.to_play
