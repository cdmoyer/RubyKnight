module RubyKnight
	class BoardEvaluator
		attr_reader :bestmoves, :donethinking
		def initialize board
			@b = board
			@bestmoves, @bestscore, @donethinking = nil, 0, false
		end

		# Pick a random move from equal options
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
			pawn_struct = time_it("eval_pawn_struct") { eval_pawn_struct(board)}
			material + pawn_struct
		end

		def eval_pawn_struct board
			advant = board.num_pieces(RubyKnight::Board::WPAWN) - 
			         board.num_pieces(RubyKnight::Board::BPAWN)

			wpawns, bpawns = get_pawn_array board
			passed, isolated, doubled, chained = 0,0,0,0
			(1..8).each do |rank|
				w,wl,wr = wpawns[rank],wpawns[rank-1],wpawns[rank+1]
				b,bl,br = bpawns[rank],bpawns[rank+1],bpawns[rank-1]

				w.each {|c|passed+=1 if (b.size==0||c<b.min)&&(bl.size==0||c<=bl.min)&&(br.size==0||c<=br.min)}
				b.each {|c|passed-=1 if (w.size==0||c>w.max)&&(wl.size==0||c>=wl.max)&&(wr.size==0||c>=wr.max)}

				wchain = false
				w.each { |c|
					wl.each {|i| wchain = true if (c-i).abs <=1 }
					wr.each {|i| wchain = true if (c-i).abs <=1 } unless wchain
				}
				bchain = false
				b.each { |c|
					bl.each {|i| bchain = true if (c-i).abs <= 1 }
					br.each {|i| bchain = true if (c-i).abs <= 1 } unless bchain
				}
				puts "rank=#{rank} wchain=#{wchain} bchain=#{bchain}"

				isolated +=1 unless wchain
				isolated -=1 unless bchain

				chained +=1 if wchain
				chained -=1 if bchain
	
				doubled -= 1 if w.size > 1
				doubled += 1 if b.size > 1
			end
			
			chained = if chained==0 then 0
			          elsif chained > 0 then 1
			          else -1 end
			doubled = if doubled==0 then 0
			          elsif doubled > 0 then 1
			          else -1 end
			#puts "#{advant} + #{passed} + #{doubled} + #{chained} - #{isolated}"
			return advant + passed + doubled + chained - isolated
		end

		# make array of pawns[file][rank]
		def get_pawn_array board
			wpawns = Array.new(10)
			bpawns = Array.new(10)
			(0..9).each { |i| wpawns[i] = Array.new 0, 0}
			(0..9).each { |i| bpawns[i] = Array.new 0, 0}
			board.piece_positions(RubyKnight::Board::WPAWN).each \
				{ |p| wpawns[(p%8)+1] << (p/8) }
			board.piece_positions(RubyKnight::Board::BPAWN).each \
				{ |p| bpawns[(p%8)+1] << (p/8) }
			return wpawns, bpawns
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
			puts "TIMING( '#{label}=>#{res}'): #{Time.now - start} seconds"
			res
		end
	end
end
