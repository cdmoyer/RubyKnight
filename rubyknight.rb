#!/usr/bin/env ruby

load './board.rb'
load './generator.rb'

module Enumerable
	def rand
		self[Kernel.rand(self.size)]
	end
end

def displayb b
	puts "#{b.to_s}\n"
	moves = b.gen_legal_moves
	puts "Moves: #{moves.size}"
	i=1
	moves.each do |m|
		print m.join(',')
		if i % 13 == 0 then print "\n"
		else print ' ' end
		i+=1
	end
	print "\n"
	if moves.size == 0
		puts "Checkmate, you lose."
		Kernel.exit 0
	end
	print "Enter move [#{b.white_to_play? ? 'White' : 'Black'}]> "
end

def play b
	moves = b.gen_legal_moves
	if moves.size == 0
		puts "Checkmate, you win!"	
		Kernel.exit(0)
	end
	move = moves.rand
	b.cnotation_move "#{RubyKnight::Board.position_to_coord move[0]}#{RubyKnight::Board.position_to_coord move[1]}"
end

cplay = false
b = RubyKnight::Board.new
displayb b
#['e2e4' , 'e7e5' , 'd2d3'].each do |move|
#['e2e4','d7d5','e4e5','f7f5'].each do |move|
$stdin.each do |move|
	move.strip!
	if move =~ /!([^ ]*)[ ]*(.*)/
		case $1
			when "quit" then Kernel.exit 
			when "undo" then b.undo 2
			when "play" 
				cplay = !cplay
				play(b) if cplay
			when "dump" 
				File.open( $2, "w") { |f| f.write( b.dump) }
				puts "dumped."
			when "load" 
				File.open( $2, "r") { |f| b.load( f.readlines.join) }
				puts "loaded."
			when "reset" 
				b = RubyKnight::Board.new
		end
		displayb b
	else
		begin
			b.cnotation_move move
			if cplay then play(b) end
			displayb b
		rescue RubyKnight::IllegalMoveException
			print "Enter a real move! #{$!.to_s}\n"
			print "Enter move> "
		end
	end
end


