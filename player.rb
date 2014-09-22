class Player # This should be used for players who don't have an assigned role
  attr_reader :send_cb, :die_cb, :dead
  attr_accessor :name
  
  def initialize(name, cbs = {})
    @name = name
    @send_cb = (cbs[:send] || proc do |msg| puts msg end)
    @die_cb = (cbs[:die] || proc do puts 'You have died' end)
    @dead = false
  end
  
  def send(msg)
    @send_cb.call(msg)
  end
  
  def die
    @dead = true
    @die_cb.call
  end
  
  def to_s
    @name
  end
  
  def lynch_vote(day, who)
    day.act([self, :lynch_vote, who])
  end
  
  def brief_night(players = [])
  end

  def brief_day(players = [])
    send("It is time for you to be heard. Use the '@Gsay@d' command to speak and the '@Gvote@d' command to vote for who you think should be lynched. You may abstain from voting.")
    send("(note: if you don't want to lynch anybody, either don't vote or type '@Gvote@d' by itself)")
  end

  @color = 'd'
  
  def self.color
    @color
  end
  
  def self.get_role_by_name(name)
    if get_roles.index(name.downcase)
      const_get(name.capitalize)
    end
  end
  
  def self.get_roles
    ObjectSpace.each_object(Class).select { |klass| klass < self }.map { |klass| klass.name.downcase }
  end
end

module Visiter
  def visit(night, who, more = nil)
    raise NotImplementedError
  end
end

# The two fundamental types of players

class Villager < Player
  @color = 'G'
end

class Mafia < Player
  include Visiter
  @color = 'R'
  
  def kill(night, who, more = nil)
    night.act([self, :mafia_kill, who])
  end
  
  def mafia_chat(night, message)
    night.act([self, :mafia_chat, message])
  end

  def brief_night(players = [])
    send("It is your time to act. You may choose to kill someone by typing '@Gvisit <name>@d'")
    send(" @R*@d Who you can kill: @r#{players.select { |pl| !pl.is_a?(Mafia) }.map(&:name).join('@d, @r') }@d")         
    send(" @R*@d The mafia in this game: @c#{players.select { |pl| pl.is_a? Mafia }.map(&:name).join('@d, @c') }@d")   
    send(" @R*@d You can chat with the aformentioned with '@Gmchat <message>@d'")
  end


  alias_method :visit, :kill
end

# Special subcategory of Villager

class Cop < Villager
  include Visiter
  @color = 'G'
  
  def investigate(night, who, more = nil)
    night.act([self, :investigate, who])
  end

  def brief_night(players = [])
    send("It is your time to act. You may choose to kill someone by typing '@Gvisit <name>'@d")
    send(" @R*@d Who you can investigate: #{players.map(&:name).join(', ')}")
  end
  
  alias_method :visit, :investigate
end
