module RubyKnight
	class Board
		def gen_moral_moves player
			(gen_moral_pawn_moves player).each do |m|
				puts m.join(',')
			end
		end

		def gen_moral_pawn_moves player
			pawns = @bitboards[WPAWN + (player==WHITE ? 0 : 6)]
			if @to_play == WHITE
				check = Proc.new do |p|
					possible = []
					in_front = whats_at( p - 8)
					if  !in_front
						possible << ( p - 8)
					end
					if p < 56 and p > 47 and !in_front and
					   !whats_at( p - 16)
						possible << ( p - 16)
					end
					unless p % 8 == 0 # we're in the a file
						ptarget = whats_at( p - 7)
						if ptarget and !is_white(ptarget)
							possible << ( p - 7)
						end
					end
					unless p % 8 == 7 # we're in the h file
						ptarget = whats_at( p - 9)
						if ptarget and !is_white(ptarget)
							possible << ( p - 9)
						end
					end
					# todo check en passany
					possible.collect {|i| [p, i]}
				end
			else
				check = Proc.new do |p|
					possible = []
					in_front = whats_at( p + 8)
					if !in_front
						possible << ( p + 8)
					end
					if p < 16 and p > 7 and !in_front and
					   !whats_at( p + 16)
						possible << ( p + 16)
					end
					unless p % 8 == 0 # we're in the a file
						ptarget = whats_at( p + 7)
						if ptarget and !is_white(ptarget)
							possible << ( p + 7)
						end
					end
					unless p % 8 == 7 # we're in the h file
						ptarget = whats_at( p + 9)
						if ptarget and !is_white(ptarget)
							possible << ( p + 9)
						end
					end
					# todo check en passany
					possible.collect {|i| [p, i]}
				end
			end
			moves = []
			bits_to_positions(pawns).each do |p|
				moves += check.call(p)	
			end
			moves
		end
	end
end
