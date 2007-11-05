def time_it label
	start = Time.now
	res = yield
	puts "TIMING( '#{label}'): #{Time.now - start} seconds"
	res
end


class RubyKnight::Board
	def gen_legal_moves
		moves = nil
		time_it("gen_moves"){ moves = gen_moves(@to_play)}	
		time_it("legal filtering"){ moves = prune_king_revealers(@to_play,moves)}
		moves
	end

	# TODO: I am so slow, that I should die, probably in gen_moves
	def prune_king_revealers_old player, moves
		kpiece = player==WHITE ? WKING : BKING
		moves.select do |to_try|
			move to_try[0], to_try[1], to_try[2], false
			next_moves = gen_moves @to_play
			king, = bits_to_positions(@bitboards[kpiece])
			ret = true
			next_moves.each do |m|
				if m[1] == king
					ret = false		
					break
				end
			end
			undo 1
			ret
		end
	end

	def prune_king_revealers player, moves
		kpiece = player==WHITE ? WKING : BKING
		piecemod = player==WHITE ? BPAWN : 0
		moves.select do |to_try|
			move to_try[0], to_try[1], to_try[2], false
			king, = bits_to_positions(@bitboards[kpiece])
			dead_king = false
			rank = king / 8
			file = king % 8
			#check up and down for R or Q
			[-8,-1,1,8].each do |inc|
				limit = 8
				trying = king + inc
				while !dead_king and limit > 0 and
		          	trying >= 0 and trying <= 63 and
			      	(rank == (trying / 8) or
				   	file == (trying % 8)) do
					target = whats_at trying
					if target
					   if (target == (WROOK+piecemod) or
					       target == (WQUEEN+piecemod))
							dead_king = true
					   end
					   limit = 0
					else
						trying += inc
						limit -= 1
					end
				end
			end unless dead_king
			#check diagonals for Q, B
			[-9,-7,7,9].each do |inc|
				limit = 8
				trying = king + inc
				rank = trying / 8
				lastrank = king / 8
				while !dead_king and limit > 0 and
			      	trying >= 0 and trying <= 63 and
			      	(lastrank - rank).abs == 1 do
					target = whats_at trying
					if target
						if (target == (WBISHOP+piecemod) or
						    target == (WQUEEN+piecemod))
							dead_king = true
						end
						limit = 0
					else
						lastrank = rank
						trying += inc
						rank = trying / 8
						limit -= 1
					end
				end
			end unless dead_king
			#check 2 P launch zones
			#check 8 N attack spots
			undo 1
			!dead_king
		end
	end
		
	def gen_moves player
		white = player==WHITE
		if 1 
		gen_pawn_moves(white) +
	    gen_knight_moves(white) +
		gen_rook_moves(white) +
		gen_bishop_moves(white) +
		gen_king_moves(white) +
		gen_queen_moves(white)
		else
		time_it("gen_pawn") { gen_pawn_moves(white)} +
		time_it("gen_knight") { gen_knight_moves(white)} +
		time_it("gen_rook") { gen_rook_moves(white)} +
		time_it("gen_bishop") { gen_bishop_moves(white)} +
		time_it("gen_king") { gen_king_moves(white)} +
		time_it("gen_queen") {gen_queen_moves(white)}
		end
	end

	def different_colors white, piece
		(white and !is_white piece) or
		(!white and is_white piece)
	end

	def gen_rook_type_moves white, piece, start_limit = 8
		moves = []
		rank = piece / 8
		file = piece % 8
		[-8,-1,1,8].each do |inc|
			limit = start_limit	
			trying = piece + inc
			while limit > 0 and
		          trying >= 0 and trying <= 63 and
			      (rank == (trying / 8) or
				   file == (trying % 8)) do
				target = whats_at trying
				if !target
					moves << [piece, trying]
				elsif different_colors( white, target)
					moves << [piece, trying]
					break
				else
					break
				end
				trying += inc
				limit -= 1
			end
		end
		moves
	end
	
	def gen_rook_moves white
		moves = []
		rooks = @bitboards[ white ? WROOK : BROOK]
		bits_to_positions(rooks).each do |r|
			moves += gen_rook_type_moves( white, r)
		end
		moves
	end

	def gen_bishop_type_moves white, piece, start_limit = 8
		moves = []
		[-9,-7,7,9].each do |inc|
			limit = start_limit	
			trying = piece + inc
			rank = trying / 8
			lastrank = piece / 8
			while limit > 0 and
			      trying >= 0 and trying <= 63 and
			      (lastrank - rank).abs == 1 do
				target = whats_at trying
				if !target
					moves << [piece, trying]
				elsif different_colors( white, target)
					moves << [piece, trying]
					break
				else
					break
				end
				lastrank = rank
				trying += inc
				rank = trying / 8
				limit -= 1
			end
		end
		moves
	end

	def gen_bishop_moves white
		moves = []
		bishops = @bitboards[white ? WBISHOP : BBISHOP]
		bits_to_positions(bishops).each do |r|
			moves += gen_bishop_type_moves( white, r)
		end
		moves
	end

	def gen_queen_moves white
		moves = []
		queens = @bitboards[white ? WQUEEN : BQUEEN]
		bits_to_positions(queens).each do |r|
			moves += gen_rook_type_moves(white, r)
			moves += gen_bishop_type_moves( white, r)
		end
		moves
	end

	# TODO: how much time is wasted with the each?  We'll never have
	#  multiple kings, will we?
	def gen_king_moves white
		moves = []
		kings = @bitboards[white ? WKING : BKING]
		bits_to_positions(kings).each do |king|
			moves += gen_rook_type_moves( white, king, 1)
			moves += gen_bishop_type_moves( white, king, 1)
			moves += gen_castle_moves( white, king)
		end
		moves
	end

	def gen_castle_moves white, king
		color = white ? WHITE : BLACK
		goodcastles = []
		# kingside
		if can_castle color, KINGSIDE
			test = if white then [60,61,62]
			       else [4,5,6] end
			if !whats_at(test[1]) and !whats_at(test[2])
				left = prune_king_revealers(@to_play,
				           test.map {|dest| [test[0], dest]})
				if left.size == 3 
					goodcastles << [test[0],test[2]] 
				end
			end
		end
		# queenside
		if can_castle color, QUEENSIDE
			test = if white then [60,59,58]
			       else [4,3,2] end
			if !whats_at(test[1]) and !whats_at(test[2])
				left = prune_king_revealers(@to_play,
				           test.map {|dest| [test[0], dest]})
				if left.size == 3 
					goodcastles << [test[0],test[2]] 
				end
			end
		end
		goodcastles
	end

	def gen_knight_moves white
		moves = []
		knights = @bitboards[white ? WKNIGHT : BKNIGHT]
		bits_to_positions(knights).each do |k|
			[-17, -15, -10, -6, 6, 10, 15, 17].each do |m|
				target = k+m
				if target >= 0 and target <= 63 and
				   ((target % 8) - (k % 8)).abs < 3
					capture = whats_at target
					if !capture or different_colors(white, capture)
					   moves << [k, target]
					end
				end
			end
		end
		moves
	end
	
	def gen_pawn_moves white
		pawns = @bitboards[white ? WPAWN : BPAWN]
		if white
			in_front_int = -8
			second_rank_high = 56
			second_rank_low = 47
			two_away_int = -16
			attack_left = -9
			attack_right = -7
			promote_low = -1
			promote_high = 8
			promotes = [WROOK, WQUEEN, WKNIGHT, WBISHOP]
		else
			in_front_int = 8
			second_rank_high = 16
			second_rank_low = 7
			two_away_int = 16
			attack_left = 7
			attack_right = 9
			promote_low = 55
			promote_high = 64
			promotes = [BROOK, BQUEEN, BKNIGHT, BBISHOP]
		end
		do_pawn = Proc.new do |p|
			possible = []
			in_front = whats_at( p + in_front_int)
			#single step
			if  !in_front
				in_front_pos = p + in_front_int
				possible << in_front_pos
				if in_front_pos > promote_low and in_front_pos < promote_high
					promotes.each { |piece| possible << [in_front_pos, piece] }
				end
			end
			#double jump
			if p < second_rank_high and p > second_rank_low and !in_front and
			   !whats_at( p + two_away_int)
				possible << ( p + two_away_int)
			end
			#captures
			unless p % 8 == 0 # we're in the a file
				ptarget = whats_at( p + attack_left)
				if ptarget and different_colors(white, ptarget)
					possible << ( p + attack_left)
				end
			end
			unless p % 8 == 7 # we're in the h file
				ptarget = whats_at( p + attack_right)
				if ptarget and different_colors(white, ptarget)
					possible << ( p + attack_right)
				end
			end
			#check en-passat
			if @bitboards[ENPASSANT] != 0 
				passant = bits_to_positions( @bitboards[ENPASSANT]).first 
				if (p + attack_right) == passant or (p + attack_left) == passant
					possible << passant
				end
			end
			possible.collect {|i| [p, *i]}
		end
		moves = []
		bits_to_positions(pawns).each do |p|
			moves += do_pawn.call(p)
		end
		moves
	end
end
