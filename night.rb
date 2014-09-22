require_relative 'player.rb'

class Night < Phase
  
  def start
    send_all("@bThe night begins.@d")
    
    @players.each do |player|
      player.brief_night(@players) unless player.dead
    end

    
    EM.add_timer(@game.time) do
      # Night is over. Call all of the end callbacks.
      send_all("@YThe sun comes up.@d")
      @end_callbacks.each(&:call)
      
      # tell the game that the night is over
      @game.night_over
    end

    
    @actions = ACTIONS.dup
    
    core_callbacks
  end
  
  def core_callbacks # These are the ones that are essential to EVERY mafia game
    # deaths of players killed by mafia at end of night:
    at_end do
      
      votes = {}
      
      @players.each do |player| # tally up the votes
        if player.is_a?(Mafia) && @player_status[player]
          votes[@player_status[player][:mafia_kill_vote]] ||= 0
          votes[@player_status[player][:mafia_kill_vote]] += 1
        end
      end
      
      next if votes == {}
      
      most_votes = votes.max_by { |(player, number)| number }.first

      
      kill(most_votes, :mafia, 'During the night, %s died')
          
    end
    
  end
end

require_relative 'night_actions.rb'
