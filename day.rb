require 'eventmachine'

require_relative 'player.rb'

class Day < Phase
  
  def start
    send_all("@YThe day begins.@d")
    
    @players.each do |player|
      player.brief_day(@players) unless player.dead
    end

    EM.add_timer(@game.time) do
      
      send_all("@cThe sun sinks below the horizon.@d")
      @end_callbacks.each(&:call)
      
      # tell the game that the night is over
      @game.day_over
    end

    
    @actions = ACTIONS.dup
    
    core_callbacks
  end
  
  def core_callbacks
    
    at_end do
      votes = {}
      
      @players.each do |player| # tally up the votes
        @player_status[player] ||= { lynch_vote: :none }
        
        votes[@player_status[player][:lynch_vote]] ||= 0
        votes[@player_status[player][:lynch_vote]] += 1
      end
      
      next if votes == {}
      
      most_votes = votes.max_by { |(player, number)| number }.first
      
      if most_votes == :none
        send_all("The town decides to not lynch anybody.")
      else
        kill(most_votes, :lynch, "The town decides to lynch %s.")
      end
    end
  end
end

require_relative 'day_actions.rb'
