class Night < Phase
  ACTIONS = {
    investigate: proc do |investigator, investigated|
      @player_status[investigator] ||= {}
      
      unless @player_status[investigator][:investigating]
        at_end do
          if @player_status[investigator][:investigating].is_a? Mafia
            investigator.send("#{investigated} is a Mafia!")
          else
            investigator.send("#{investigated} is not a Mafia!")
          end
        end
      end
      
      @player_status[investigator][:investigating] = investigated
      
      investigator.send("You aim your efforts at finding out more about #{investigated}.")
    end,
  
  
    mafia_kill: proc do |killer, killee|
      @player_status[killer] ||= {}
      @player_status[killer][:mafia_kill_vote] = killee
      killer.send("@RYou are plotting to kill #{killee}.@d")
      
      send_all(Mafia, "@R<Mafia>@d #{killer} votes to kill #{killee}")
    end,
  
    mafia_chat: proc do |speaker, message|
      send_all(Mafia, "@R<Mafia chat> @c#{speaker}@d: #{message}")
    end
  }
  
  
end
