# This file serves as an example of role-creation
# it's included in server.rb right after game.rb is included

# Initialize the data structure
class Doctor < Villager
  include Visiter

  @color="G"

  def save(night, who, more = nil)
    night.act([self, :save, who])
  end

  def brief_night(players = [])
    send("It is time for you to save somebody. Type '@Gvisit <name>@d' to save them, and '@Gwho@d' to see a list of players."); 
  end

  alias_method :visit, :save 
end

# What happens when the action is performed
Night::ACTIONS[:save] = proc do |saver, savee|
  @player_status[saver] ||= {}

  unless @player_status[saver][:who_to_save] # This should only be activated once
    at_death do |player, cause|
      if player == @player_status[saver][:who_to_save]
        next :override # this player has been saved!
      end
    end
  end
  
  saver.send("You direct your attempts at saving the life of #{savee}.")
  @player_status[saver][:who_to_save] = savee
end

# Note that we don't have to create a new command - the visit command will handle all of this
# for us
