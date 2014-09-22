require 'eventmachine'

class Phase
  attr_accessor :end_callbacks, :player_status, :players
  
  
  def initialize game, players
    @game = game
    @end_callbacks = []
    @death_callbacks = []
    @player_status = {}
    @players = players
  end
  
  # ------
  # These two methods are meant to be overriden
  
  def start
    raise NotImplementedError
  end
  
  def core_callbacks # These are the ones that are essential to EVERY mafia game
    raise NotImplementedError
  end
  
  # ------
  
  def act what
    who, action, args = what.shift, what.shift, what
    if @actions[action]
      self.instance_exec(who, *args, &@actions[action])
    end
  end
  
  def at_end &what
    @end_callbacks << what if !@end_callbacks.index(what)
  end
  
  def at_death &what
    @death_callbacks << what if !@death_callbacks.index(what)
  end
  
  def send_to player, msg
    player.send(msg)
  end
  
  def send_all type, msg = nil
    if type.is_a? String
      msg = type
      type = Player
    end
    
    @players.each do |player|
      send_to(player, msg) if player.is_a? type
    end
  end
  
  def kill player, cause, glmsg = '%s has died.', msg = "@RYou have died.@d"
    override = false
    @death_callbacks.each do |cb|
      override = cb.call(player, cause) == :override
    end

    return if override

    player.die
    player.send(msg)
    send_all(glmsg % player) 
  end
end

require './night.rb'
require './day.rb'
require './player.rb'

class Game
  attr_accessor :players, :name, :phase, :time
  
  def initialize opts
    @name = opts[:name]
    @setup = opts[:setup]
    @time = opts[:time]
    @end_cb = opts[:end_cb] || proc { raise 'no :end_cb specified' }
    @phase = :preparing
    @players = []
  end
  
  def add_players *players
    @players.push(*players)
  end
  
  alias_method :<<, :add_players
  
  def assign_roles
    
    newplayers = []
    @players.shuffle!
    
    excess = nil
    @setup.each do |role, count|
      if count.respond_to? :times
        count.times do
          newplayers << assign(@players.shift, role)
        end
      elsif count == :excess
        excess = role
      end
    end
    if excess
      newplayers.push(*@players.map { |p| assign(p, excess) })
    end
    @players = newplayers
  end
  
  def assign(player, role)
    player.send("You are a @#{role.color}#{role}@d!")
    role.new(player.name, send: player.send_cb, die: player.die_cb)
  end
  
  def start
    assign_roles
    day_over
  end
  
  def day_over
    if w = winner?
      win(w)
    else
      @players = @phase.respond_to?(:players) ? @phase.players : @players
      @phase = Night.new(self, @players)
      @phase.start
    end
  end
  
  def night_over
    if w = winner?
      win(w)
    else
      @players = @phase.respond_to?(:players) ? @phase.players : @players
      @phase = Day.new(self, @players)
      @phase.start
    end
  end
  
  # Check if the game is over
  # If there are more Mafia than villagers or one Mafia and one villager, then Mafia win
  # If there are no more Mafia, then villagers win
  def winner?
    howmany = { villagers: 0, mafia: 0 }
    
    @players.each do |player|
      next if player.dead
      if player.is_a? Villager
        howmany[:villagers] += 1
      elsif player.is_a? Mafia
        howmany[:mafia] += 1
      end
    end
    
    if howmany[:mafia] > howmany[:villagers] || (howmany[:mafia] == 1 && howmany[:villagers] == 1)
      return :mafia
    end
    
    if howmany[:mafia] == 0
      return :village
    end
    
    false
    
  end
  
  def win who # either :mafia or :village
    messages = {
      mafia: 'The Mafia have won!',
      village: 'The village has won!',
    }
    
    @players.each do |player|
      player.send('Game over.')
      player.send(messages[who])
    end

    @end_cb.call
  end
  
  def is_night?
    @phase.is_a?(Night)
  end
  
  def is_day?
    @phase.is_a?(Day)
  end
  
end

if __FILE__ == $0
  
  EM.run do
    
    g = Game.new(name: "Game 1")
    g.add_players(p1 = Player.new("p1"),
     p2 = Player.new("p2"),
     p3 = Player.new("p3"),
     p4 = Player.new("p4"),
     p5 = Player.new("p5"),
     p6 = Player.new("p6"))
    g.start
    p g.players.map(&:class)
  end
  
end
