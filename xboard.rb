#!/usr/bin/env ruby

#load './board.rb'
#load './generator.rb'
load '/Users/cmoyer/Devel/rubyknight/board.rb'
load '/Users/cmoyer/Devel/rubyknight/generator.rb'

confirm = false
$stdout.sync=true
$stderr.sync=true

def time_it label
	yield
end

def logout msg
	$stderr.print "Out:#{msg}\n"		
	print "#{msg}\n"		
end

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
		puts "RESULT 0-1 {Black Mates}"
	end
end

def tocnote move
	"#{RubyKnight::Board.position_to_coord move[0]}#{RubyKnight::Board.position_to_coord move[1]}"
end

def play b
	moves = b.gen_legal_moves
	if moves.size == 0
		puts "RESULT 1-0 {White Mates}"
	end
	move = moves.rand
	cnotation = tocnote move
	logout "move #{cnotation}"
	b.cnotation_move cnotation
end

cplay = true
b = RubyKnight::Board.new
$stdin.each do |move|
	move.strip!
	$stderr.print "In :#{move}\n"
	case move	
		when "xboard" then 
			logout ""
			logout "tellics set f5 1=1"
		when "confirm_moves"
			confirm = true	
			logout "Will now confirm moves."	
		when /.{0,1}new/
			b = RubyKnight::Board.new
			logout "tellics set 1 RubyKnight"
		when /^protover/ then 
			logout "feature sigint=0 sigterm=0 ping=1 done=1"	
		when /^ping\s+(.*)/ then 
			logout "pong #{$1}"	
		when /^st/ then 
		when /^level/ then 
		when /^time/ then 
		when /^otim/ then 
		when "hard" then 
		when "random" then 
		when /^accepted/ then 
			# ignore	
		else		
			move.gsub!(/\?/, '')	
			begin
				b.cnotation_move move
				logout "Legal move: #{move}" if confirm
				if cplay then play(b) end
				# displayb b
			rescue RubyKnight::IllegalMoveException
				logout "Illegal move: #{move}"
			end
	end
end


