module RubyKnight

	class IllegalMoveException < RuntimeError
	end
	
	class Board
		attr_reader :history, :WHITE, :BLACK, :to_play
		
		WHITE, BLACK = 0, 1
		QUEENSIDE, KINGSIDE = 0, 1
		WPAWN, WROOK, WBISHOP, WKNIGHT, WQUEEN, WKING = 0,1,2,3,4,5
		BPAWN, BROOK, BBISHOP, BKNIGHT, BQUEEN, BKING = 6,7,8,9,10,11
		WALL, BALL = 12, 13
		ENPASSANT = 14

		SYMBOLS = [ 'P','R','B','N','Q','K',
		            'p','r','b','n','q','k']


		def initialize
			setup_start
		end

		def setup_start
			@to_play = WHITE
			@bitboards = Array.new 15, 0
			@can_castle = [ [true, true], [true, true] ]

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

			file = coord[0]
			rank = coord[1]

			pos = ((8 - (rank.to_i - zero)) * 8) +\
			      (file - a)

		end

		def Board.position_to_coord position
			file = position % 8
			rank = (8 - (position - file) / 8)
			"#{(file + 97).chr}#{rank}"
		end

		def cnotation_move cnot
			start, dest, promotion = cnotation_to_bits cnot
			raise IllegalMoveException, "Unreadable move" unless start
			move start, dest, promotion
		end

		def cnotation_to_bits cnot
			if cnot =~ /([a-h][1-8])([a-h][1-8])([qrbnkp]{0,1})/
				unless $3 == "" 
					promotion = if @to_play = WHITE then 0
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

		def whats_at position
			positionbit = (1 << position)
			somethingthere = false
			unless (@bitboards[WALL]|@bitboards[BALL]) & positionbit > 0
				return false
			end
			(0..11).each do |piece|		
				if (@bitboards[piece] & positionbit) > 0
					somethingthere = piece
					break 
				end
			end
			somethingthere
		end

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

		def move orig, dest, promotion
			piece = whats_at(orig)

			# Check Legality
			 # Your piece?
			unless piece and 
				   ((is_white(piece) and @to_play == WHITE) or
				    (!is_white(piece) and @to_play == BLACK))
				raise IllegalMoveException, "Not your piece"
			end

			legal_moves = gen_moral_moves @to_play
			unless legal_moves.include? [orig, dest]
				raise IllegalMoveException, "Invalid move"
			end
			
			captured = whats_at(dest)
			move_piece piece, orig, dest

			#mark en-passant
			if piece == WPAWN and orig > 47 and orig < 56 and
				@bitboards[ENPASSANT] = ( 1 << orig+8)
			elsif piece == BPAWN and orig > 7 and orig < 16 and			
				@bitboards[ENPASSANT] = ( 1 << orig+8)
			else
				@bitboards[ENPASSANT] = 0
			end

			@history <<Event.new(piece, orig, dest, captured, promotion)
			@to_play = if @to_play==WHITE then BLACK
			           else WHITE end
		end

		def bits_to_positions bits
			(0..63).select {|i| 1<<i & bits !=0}
		end
	
		class History < Array
		end

		class Event
			attr_reader :piece, :origi, :dest, :captured, :promotion
			def initialize piece, orig, dest, captured, promotion=false
				@piece = piece
				@orig = orig
				@dest = dest
				@captured = captured
				@promotion = promotion
			end

			def to_s
				Board.position_to_coord(@orig) +\
					Board.position_to_coord(@dest) +\
					(@promotion ? Board.SYMBOLS[@promotion] : "")

			end
		end
		
	end
end
