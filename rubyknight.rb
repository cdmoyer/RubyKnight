#!/usr/local/bin/ruby

load 'board.rb'
load 'generator.rb'

b = RubyKnight::Board.new

puts "#{b.to_s}\n"
#['e2e4' , 'e7e5' , 'd2d3'].each do |move|
[].each do |move|
	b.cnotation_move move
	b.display
	puts b.history.last.to_s
	puts
end

b.gen_moral_moves 0
