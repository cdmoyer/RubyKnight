module RubyKnight
	class BoardEvaluator
		attr_reader :bestmoves, :donethinking
		def initialize board
			@b = board
			@bestmoves, @bestscore, @donethinking = nil, 0, false
		end

		def bestmove
			if @bestmoves
				return @bestmoves[Kernel.rand(@bestmoves.size)]
			end
			nil
		end

		def think for_white
			@bestmoves, @bestscore, @donethinking = nil, 0, false
			@b.gen_legal_moves.each do |move|
				newb = Marshal.load(Marshal.dump( @b))
				newb.move move[0], move[1], move[2]
				result = eval_position newb
				if (for_white and result > @bestscore) or
					   result < @bestscore or @bestmoves == nil
					  @bestscore = result 
					  @bestmoves = [move]
				elsif result == @bestscore
					@bestmoves << move	
				end
			end
			@donethinking = true
		end

		# Return an int
		# being the pawn advantage of white
		def eval_position board=@b
			material = time_it("eval_material") { eval_material(board)}
			material
		end

		def eval_material board
			q, r, b, n, p = 9, 5, 3, 3, 1
			white = p * board.num_pieces(RubyKnight::Board::WPAWN) +
	        		q * board.num_pieces(RubyKnight::Board::WQUEEN) +
	        		r * board.num_pieces(RubyKnight::Board::WROOK) +
	        		b * board.num_pieces(RubyKnight::Board::WBISHOP) +
	        		n * board.num_pieces(RubyKnight::Board::WKNIGHT)
			black = p * board.num_pieces(RubyKnight::Board::BPAWN) +
	        		q * board.num_pieces(RubyKnight::Board::BQUEEN) +
	        		r * board.num_pieces(RubyKnight::Board::BROOK) +
	        		b * board.num_pieces(RubyKnight::Board::BBISHOP) +
	        		n * board.num_pieces(RubyKnight::Board::BKNIGHT)
		
			white - black		
		end

		def time_it label
			start = Time.now
			res = yield
			puts "TIMING( '#{label}'): #{Time.now - start} seconds"
			res
		end
	end
end
