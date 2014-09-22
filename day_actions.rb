class Day < Phase
  ACTIONS = {
    lynch_vote: proc do |voter, voted|
      voted = :none if voted.nil?
      @player_status[voter] ||= {}
      @player_status[voter][:lynch_vote] = voted
      
      if voted == :none
        send_all("@r#{voter} votes to lynch nobody.")
      else
        send_all("@r#{voter} has voted to lynch #{voted}.@d")
      end
    end
  }
  
  
end
