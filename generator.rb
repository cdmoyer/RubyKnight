module RubyKnight
	class Board
		def gen_moral_moves player
			start = Time.now
			moves = gen_moral_pawn_moves(player) +
			gen_moral_knight_moves(player) +
			gen_moral_rook_moves(player) +
			gen_moral_bishop_moves(player) +
			gen_moral_king_moves(player) +
			gen_moral_queen_moves(player)
			puts "Generation took: #{Time.now - start} microseconds"
			moves
		end

		def different_colors player, piece
			(player==WHITE and !is_white piece) or
			(player!=WHITE and is_white piece)
		end

		def gen_rook_type_moves player, piece, limit = 7
			moves = []
			rank = piece / 8
			file = piece % 8
			[-8,-1,1,8].each do |inc|
				trying = piece + inc
				while limit > 0 and
			          trying >= 0 and trying <= 63 and
				      (rank == (trying / 8) or
					   file == (trying % 8)) do
					target = whats_at trying
					if !target
						moves << [piece, trying]
					elsif different_colors( player, target)
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
		
		def gen_moral_rook_moves player
			moves = []
			rooks = @bitboards[WROOK + (player==WHITE ? 0 : 6)]
			bits_to_positions(rooks).each do |r|
				moves += gen_rook_type_moves( player, r)
			end
			moves
		end

		def gen_bishop_type_moves player, piece, limit = 7
			moves = []
			[-9,-7,7,9].each do |inc|
				trying = piece + inc
				rank = trying / 8
				lastrank = piece / 8
				while limit > 0 and
				      trying >= 0 and trying <= 63 and
				      (lastrank - rank).abs == 1 do
					target = whats_at trying
					if !target
						moves << [piece, trying]
					elsif different_colors( player, target)
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

		def gen_moral_bishop_moves player
			moves = []
			bishops = @bitboards[WBISHOP + (player==WHITE ? 0 : 6)]
			bits_to_positions(bishops).each do |r|
				moves += gen_bishop_type_moves( player, r)
			end
			moves
		end

		def gen_moral_queen_moves player
			moves = []
			queens = @bitboards[WQUEEN + (player==WHITE ? 0 : 6)]
			bits_to_positions(queens).each do |r|
				moves += gen_rook_type_moves( player, r)
				moves += gen_bishop_type_moves( player, r)
			end
			moves
		end

		def gen_moral_king_moves player
			moves = []
			kings = @bitboards[WKING + (player==WHITE ? 0 : 6)]
			bits_to_positions(kings).each do |r|
				moves += gen_rook_type_moves( player, r, 1)
				moves += gen_bishop_type_moves( player, r, 1)
			end
			moves
		end

		def gen_moral_knight_moves player
			moves = []
			knights = @bitboards[WKNIGHT + (player==WHITE ? 0 : 6)]
			bits_to_positions(knights).each do |k|
				[-17, -15, -10, -6, 6, 10, 15, 17].each do |m|
					target = k+m
					if target >= 0 and target <= 63 and
					   ((target % 8) - (k % 8)).abs < 3
						capture = whats_at target
						if !capture or different_colors(player, capture)
						   moves << [k, target]
						end
					end
				end
			end
			moves
		end
		
		def gen_moral_pawn_moves player
			pawns = @bitboards[WPAWN + (player==WHITE ? 0 : 6)]
			if @to_play == WHITE
				in_front_int = -8
				second_rank_high = 56
				second_rank_low = 47
				two_away_int = -16
				attack_left = -7
				attack_right = -9
			else
				in_front_int = 8
				second_rank_high = 16
				second_rank_low = 7
				two_away_int = 16
				attack_left = 7
				attack_right = 9
			end
			check = Proc.new do |p|
				possible = []
				in_front = whats_at( p + in_front_int)
				#single step
				if  !in_front
					possible << ( p + in_front_int)
				end
				#double jump
				if p < second_rank_high and p > second_rank_low and !in_front and
				   !whats_at( p + two_away_int)
					possible << ( p + two_away_int)
				end
				#captures
				unless p % 8 == 0 # we're in the a file
					ptarget = whats_at( p + attack_left)
					if ptarget and !is_white(ptarget)
						possible << ( p + attack_left)
					end
				end
				unless p % 8 == 7 # we're in the h file
					ptarget = whats_at( p + attack_right)
					if ptarget and !is_white(ptarget)
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
				possible.collect {|i| [p, i]}
			end
			moves = []
			bits_to_positions(pawns).each do |p|
				moves += check.call(p)	
			end
			moves
		end
	end
end
