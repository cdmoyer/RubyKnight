module RubyKnight
	class Board
		def gen_moral_moves player
			gen_moral_pawn_moves(player) +
			gen_moral_knight_moves(player)
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
						if !capture or (player==WHITE and !is_white capture) or
						   (player!=WHITE and is_white capture)
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
