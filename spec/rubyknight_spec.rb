require 'spec_helper'

describe RubyKnight do
	it "should be executing with Ruby 1.8.7" do
	  RUBY_VERSION.should == '1.8.7'
	end
end


describe RubyKnight::Board do
	
		before(:each) do
		  @board = RubyKnight::Board.new
		end
	
		it "generates an empty board" do
			@board.to_s.should == "rnbqkbnr\npppppppp\n........\n........\n........\n........\nPPPPPPPP\nRNBQKBNR\n"
		end	

		it "opens the game to player White" do
			@board.white_to_play?.should == true
		end
  
		it "prompts player to propose a move" do
			pending
		end

end
