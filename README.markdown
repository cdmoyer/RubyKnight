RubyKnight
==========

RubyKnight is a very naive implementation of a chess library and engine.

Installation
------------

gem install rubyknight


Usage
-----

### Play Chess

`> rubyknight`

### Write Chess Code

	require 'rubygems'
	require 'rubyknight'
	board = RubyKnight::Board.new

	puts board.to_s
	print "Enter move: "
	$stdin.each do |move|
		move.strip!
		begin
			board.cnotation_move move
		rescue RubyKnight::IllegalMoveException
			print "Enter a real move! #{$!.to_s}\n"
		end
		puts board.to_s
		print "Enter move: "
	end
