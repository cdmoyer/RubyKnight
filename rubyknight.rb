#!/usr/bin/ruby

load 'board.rb'
load 'generator.rb'

module Enumerable
	def rand
		self[Kernel.rand self.size ]
	end
end

def displayb b
	puts "#{b.to_s}\n"
	moves = b.gen_moral_moves(b.to_play)
	puts "Moves: #{moves.size}"
	i=1
	moves.each do |m|
		print m.join(',')
		if i % 13 == 0 then print "\n"
		else print ' ' end
		i+=1
	end
	print "\n"
	print "Enter move> "
end

b = RubyKnight::Board.new
displayb b
#['e2e4' , 'e7e5' , 'd2d3'].each do |move|
#['e2e4','d7d5','e4e5','f7f5'].each do |move|
$stdin.each do |move|
	move.strip!
	begin
		b.cnotation_move move
		move = b.gen_moral_moves(b.to_play).rand
		b.cnotation_move "#{RubyKnight::Board.position_to_coord move[0]}#{RubyKnight::Board.position_to_coord move[1]}"
		displayb b
	rescue RubyKnight::IllegalMoveException
		print "Enter a real move!\n"
		print "Enter move> "
	end
end


