# = rubyknight.rb - Ruby Chess Library
#
# == Example
#	board = RubyKnight::Board.new
#
#	puts board.to_s
#	print "Enter move: "
#	$stdin.each do |move|
#		move.strip!
#		begin
#			board.cnotation_move move
#		rescue RubyKnight::IllegalMoveException
#			print "Enter a real move! #{$!.to_s}\n"
#		end
#		puts board.to_s
#		print "Enter move: "
#	end

module RubyKnight
	class IllegalMoveException < RuntimeError
	end
	
	# A Chess Board and State
	class Board
		attr_reader :history, :WHITE, :BLACK, :to_play
		
		WHITE, BLACK = 0, 1
		QUEENSIDE, KINGSIDE = 0, 1
		WPAWN, WROOK, WBISHOP, WKNIGHT, WQUEEN, WKING = 0,1,2,3,4,5
		BPAWN, BROOK, BBISHOP, BKNIGHT, BQUEEN, BKING = 6,7,8,9,10,11
		WALL, BALL = 12, 13
		ENPASSANT = 14
		LAST_BOARD = CAN_CASTLE = 15

		SYMBOLS = [ 'P','R','B','N','Q','K',
		            'p','r','b','n','q','k']


		def initialize
			setup_start
		end

		# Is it white's turn?
		def white_to_play?
			@to_play == WHITE	
		end

		# Dump the board state to a string
		def dump
			@bitboards[@bitboards.size] = @history
			@bitboards[@bitboards.size] = @to_play
			ret = Marshal.dump(@bitboards)
			@bitboards.delete_at(@bitboards.size-1)
			@bitboards.delete_at(@bitboards.size-1)
			ret
		end

		# Load the board state from a string
		def load dmp
			@bitboards = Marshal.load( dmp)
			@to_play = @bitboards.pop
			@history = @bitboards.pop
		end

		def _undo
			evt = @history.pop
			return unless evt
			place_piece evt.piece, evt.orig

			if evt.promotion then unplace_piece evt.promotion, evt.dest
			else unplace_piece evt.piece, evt.dest end

			if evt.capture then place_piece evt.capture, evt.dest end

			if last = @history.last
				mark_enpassant last.piece, last.orig, last.dest
			else
				mark_enpassant nil,  nil, nil
			end

			# handle castling
			@bitboards[CAN_CASTLE] = evt.can_castle
			# are we castling?
			if (evt.piece == WKING or evt.piece == BKING) and
			   (evt.dest - evt.orig).abs == 2
				# yes, we are
				case evt.dest
					when 62
						move_piece WROOK, 61, 63	
					when 58
						move_piece WROOK, 59, 56	
					when 2
						move_piece BROOK, 3, 0	
					when 6
						move_piece BROOK, 5, 7
				end
			end

			@to_play = if @to_play==WHITE then BLACK
			           else WHITE end
		end

		# Roll back the last move, specify two to roll back a whole player
		def undo num = 1
			num.times { _undo}
		end

		# Set the boards to the initial state
		def setup_start
			@to_play = WHITE
			@bitboards = Array.new LAST_BOARD+1, 0
			@bitboards[CAN_CASTLE] = 0x000F # 1111

			@history = History.new
			
			place_piece WPAWN, *(48..55).to_a
			place_piece WROOK, 56, 63
			place_piece WKNIGHT, 57, 62
			place_piece WBISHOP, 58, 61
			place_piece WQUEEN, 59
			place_piece WKING, 60

			place_piece BPAWN, *(8..15).to_a
			place_piece BROOK, 0, 7
			place_piece BKNIGHT, 1, 6
			place_piece BBISHOP, 2, 5
			place_piece BQUEEN, 3
			place_piece BKING, 4

		end

		def Board.coord_to_position coord
			a, zero = 'a0'.unpack('cc')

			file = coord[0].getbyte(0)
			rank = coord[1].getbyte(0)

			pos = ((8 - (rank - zero)) * 8) +\
			      (file - a)

		end

		def Board.position_to_coord position
			file = position % 8
			rank = (8 - (position - file) / 8)
			"#{(file + 97).chr}#{rank}"
		end

		# Make a move in coordinate notation, ex. e2e4
		def cnotation_move cnot
			start, dest, promotion = cnotation_to_bits cnot
			raise IllegalMoveException, "Unreadable move" unless start
			move start, dest, promotion
		end

		def cnotation_to_bits cnot
			if cnot =~ /([a-h][1-8])([a-h][1-8])([qrbnkp]{0,1})/
				unless $3 == "" 
					promotion = if @to_play == WHITE then 0
					            else 6 end
					promotion += 
						case $3
							when 'q' then WQUEEN
							when 'p' then WPAWN
							when 'r' then WROOK
							when 'b' then WBISHOP
							when 'n' then WKNIGHT
							else
								return false
						end
				else promotion = false end
				[ Board.coord_to_position( $1), Board.coord_to_position( $2),
				  promotion]		
			else
				false
			end
		end

		# find out the piece at a given location
		def whats_at position
			positionbit = (1 << position)
			if @bitboards[WALL] & positionbit > 0
				range = WPAWN..WKING
			elsif @bitboards[BALL] & positionbit > 0
				range = BPAWN..BKING
			else 
				return false
			end

			somethingthere = false
			range.each do |piece|		
				if (@bitboards[piece] & positionbit) > 0
					somethingthere = piece
					break 
				end
			end
			somethingthere
		end

		# get a simple board notation
		def	to_s
			out = ""
			(0..63).each do |position|
				somethingthere = whats_at position
				if somethingthere then out << SYMBOLS[somethingthere]
				else out << '.' end
				out << "\n" if (position+1) % 8 == 0
			end
			out
		end

		def all_board_for piece
			12 + (is_white(piece) ? 0 : 1)
		end

		def place_piece piece, *positions
			positions.each do |position|
				position = (1 << position)
				@bitboards[piece] |= position
				@bitboards[all_board_for(piece)] |= position
			end
		end

		def unplace_piece piece, *positions
			positions.each do |position|
				position = ~(1 << position)
				@bitboards[piece] &= position
				@bitboards[all_board_for(piece)] &= position
			end
		end

		def move_piece piece, orig, dest
			unplace_piece piece, orig	
			place_piece piece, dest
		end

		def is_white piece
			piece <= WKING
		end

		def move orig, dest, promotion=nil, verify_legality = true
			piece = whats_at(orig)

			# Check Legality
			 # Your piece?
			unless piece and 
				   ((is_white(piece) and @to_play == WHITE) or
				    (!is_white(piece) and @to_play == BLACK))
				raise IllegalMoveException, "Not your piece"
			end

			if verify_legality
				legal_moves = gen_legal_moves
				unless legal_moves.include? [orig, dest] or
			       	   legal_moves.include? [orig, dest, promotion]
					raise IllegalMoveException, "Invalid move"
				end
			end
			
			captured = whats_at(dest)
			unplace_piece captured, dest if captured
			move_piece piece, orig, dest

			# handle castling
			# are we castling?
			if (piece == WKING or piece == BKING) and
			   (dest - orig).abs == 2
				# yes, we are
				case dest
					when 62
						move_piece WROOK, 63, 61	
					when 58
						move_piece WROOK, 56, 59	
					when 2
						move_piece BROOK, 0, 3	
					when 6
						move_piece BROOK, 7, 5
				end
			end


			# mark no-longer-possible castles
			can_castle_was = @bitboards[CAN_CASTLE]
			if piece == WKING 
				@bitboards[CAN_CASTLE] &= ~(1|2)
			elsif piece == WROOK and orig == 56
				@bitboards[CAN_CASTLE] &= ~(1)
			elsif piece == WROOK and orig == 63
				@bitboards[CAN_CASTLE] &= ~(2)
			elsif piece == BKING
				@bitboards[CAN_CASTLE] &= ~(4|8)
			elsif piece == BROOK and orig == 0
				@bitboards[CAN_CASTLE] &= ~(4)
			elsif piece == BROOK and orig == 7
				@bitboards[CAN_CASTLE] &= ~(8)
			end

			if promotion
				unplace_piece piece, dest	
				place_piece promotion, dest
			end	

			mark_enpassant piece, orig, dest

			@history << Event.new(piece, orig, dest, captured, 
			                      promotion, can_castle_was)
			@to_play = if @to_play==WHITE then BLACK
			           else WHITE end
		end

		def mark_enpassant last_piece, last_orig, last_dest
			if last_piece == WPAWN and last_orig > 47 and last_orig < 56 and
				@bitboards[ENPASSANT] = ( 1 << last_orig-8)
			elsif last_piece == BPAWN and last_orig > 7 and last_orig < 16 and
				@bitboards[ENPASSANT] = ( 1 << last_orig+8)
			else
				@bitboards[ENPASSANT] = 0
			end
		end

		def bits_to_positions bits
			(0..63).select {|i| 1<<i & bits !=0}
		end

		def piece_positions piece
			bits_to_positions(@bitboards[piece])
		end

		def num_pieces piece
			bits_to_positions(@bitboards[piece]).size
		end

		def can_castle color, side
			@bitboards[CAN_CASTLE] & (1 << ((color * 2)+side)) > 0
		end
	
		class History < Array
		end

		class Event
			attr_reader :piece, :orig, :dest, :capture, :promotion, :can_castle
			def initialize piece, orig, dest, capture, 
		 	               promotion=false, can_castle=0
				@piece = piece
				@orig = orig
				@dest = dest
				@capture = capture
				@promotion = promotion
				@can_castle = can_castle
			end

			def to_s
				Board.position_to_coord(@orig) +\
					Board.position_to_coord(@dest) +\
					(@promotion ? Board.SYMBOLS[@promotion] : "")

			end
		end
		
	end
end

require "rubyknight/generator"
require "rubyknight/evaluator"
