
# encoding: utf-8

require './game.rb'
require './doctor.rb'
require './color.rb'

require './config.rb'

class MafiaServer < EM::Connection
  
  @@config = {
    setup: CONFIG[:setup] || { Cop => 1, Mafia => 2, Villager => :excess },
    time: CONFIG[:time] || 30
  }
  
  def minplayers
    @@config[:setup].map { |(role, count)| count == :excess ? 1 : count }.reduce(:+)
  end
  
  @@clients = []
  @@host = nil
  @@host_spot_open = true
  
  module Telnet
    ESC = "\x1B"
    IAC = "\xFF"
    WILL = "\xFB"
    WONT = "\xFC"
    DO = "\xFD"
    DONT = "\xFE"
    
    # Why this has to be like this is beyond me
    C_REGEX = /\u00FF.{2}/
    
  end
  
  def post_init
    puts 'Someone has connected'
    
    @client = MafiaClient.new(send: proc do |msg| send_data(Color::cformat("#{msg}\r\n")) end).setscreen(:name)
    #@client.send("#{Telnet::IAC}#{Telnet::DO}\x2D")
    
    @client.send(" @W---------------@d ")
    @client.send(" @W- @G M A F I A  @d- ")
    @client.send(" @W---------------@d ")
    ask_for_name
    
    
    
  end
  
  def receive_data(data)
    @command ||= ""
    data = strip_subch(data)
    data.each_byte do |byte|
      cb = byte.chr
      
      if cb == "\b"
        if @command.size > 0
          @command = @command[0..-2]
        end
      elsif (cb == "\n" || data == "\r\n")
        if @command.size > 0
          handle_command(@command.strip)
          @command = ''
        end
      elsif !(@command == '' && (cb == ' '))
        @command += cb
      end
    end
  end
  
  def get_needed
    need = minplayers - @@clients.size
    
    if need < 0 then 0 else need end
  end
  
  def ask_for_name
    @client.send("What is your name?")
  end
  
  def chosen_name
    @client.send("You have joined the game under the name: @C#{@client.player.name}@d.")
    @client.send("Please wait until the game begins.")
    @@clients << @client
    @client.send("During the day and while waiting for the game, you can '@Gsay <message>@d' to chat with the other players.")
    @client.send("Use the '@Gsetup@d' command to see how many players will be assigned to each role.")
    @client.send("Use the '@Gwho@d' command to see who is playing.")
    @client.send("")

    send_to_all("A player under the name '@C#{@client.player.name}@d' has joined.")
    send_to_all("  Connected: @Y#{@@clients.size}@d - Needed: @Y#{get_needed}@d")
    
    
    if @@host_spot_open
      handle_host
    end
    
    @client.setscreen(:waiting)
  end
  
  def send_to_all(msg)
    @@clients.each do |client|
      client.send(msg)
    end
  end
  
  def handle_host
    set_host(@client)
  end
  
  def set_host(client)
    @@host = client
    @@host_spot_open = false
    client.send("@R ** @dNOTE: You're the host. When enough players join, you can type '@Gstart@d' and begin the game.")
    client.send("          You may also use the '@Gset@d' command to alter the amount of players that will be assigned to each role.")
  end
  
  def self.find_player(name)
    @@game.players.find { |player| player.name.downcase == name.downcase}
  end
  
  
  
  
  class Command
    attr_reader :name, :screens, :callback
    
    def initialize name, screens, &callback
      @name = name
      @screens = screens
      @callback = callback
    end
    
    def invoke(args, cl, server)
      @callback.call(args, cl, server)
    end
  end
  
  def parse_command(command)
    result = {name: '', args: []}
    split = command.split(' ')
    
    if split.size > 0
      result[:name] = split.shift
      result[:args] = split
    end

    result
  end
  
  @@commands = []
  
  def self.command(name, *phases, &cb)
    @@commands << Command.new(name.to_s, phases, &cb)
  end
  
  
  
  def handle_command(command)
    sc = @client.screen
    
    if sc == :name
      
      name = command.strip.downcase.gsub(/[^A-Za-z0-9]/i, '').capitalize
      
      if name.size < 3 || name.size > 14
        return @client.send("Names must be between 3 and 14 characters long.")
      end
      
      if @@clients.find { |cl| cl.player.name == name }
        return @client.send("That name is already taken.")
      end
      
      @client.player.name = name
      chosen_name
      return
      
    end
    
    parse = parse_command(command)
    
    command_o = @@commands.find { |c| c.name == parse[:name] && c.screens.index(sc) }
    
    if command_o
      command_o.invoke(parse[:args], @client, self)
    else
      @client.send("That is not a command you can use right now.")
    end
    
  end
  
  STRINGS = {
    not_host: "Nice try, but you aren't the host!",
    no_role:  "That role doesn't exist! Type @Groles@d or @Gsetup@d to see a list of roles",
  } 
  
  command(:start, :waiting) do |args, cl, server|
  
    next cl.send(STRINGS[:not_host]) if cl != @@host
    
    if @@clients.size < server.minplayers
      cl.send("There aren't enough players to start the game.")
    else
      server.start_game
    end
  end
  
  command(:roles, :waiting, :dead) do |args, cl, server|
  
    next cl.send(STRINGS[:not_host]) if cl != @@host
    
    rstr = Player.get_roles.map { |r| '@C' << r << '@d' }.join(', ')
    cl.send("Available roles: #{rstr}")
  end
  
  command(:who, :waiting, :playing, :dead) do |args, cl, server|
    
    wstr = @@clients.map { |c| "@d - #{c.player.dead ? '@R' : '@C'}#{c.player.name}" }.join("\r\n")
    
    cl.send("Players (red means dead):\r\n#{wstr}@d")
  end
  
  command(:quit, :waiting, :playing, :dead) do |args, cl, server|
    cl.send("Good bye!")
    server.close_connection_after_writing
  end
  
  
  command(:setup, :waiting, :playing, :dead) do |args, cl, server|
    
    if args.size == 0
      sstr =  "\r\n@C+------------+--------------+@d\r\n" << 
              @@config[:setup].select { |_, count| count != 0 }.map { |role, count|
                "@C| @d%-10s @C| @d%-12s @C|@d" % [role, count == :excess ? 'any extra' : count ]
              }.join("\r\n") << 
              "\r\n@C+------------+--------------+@d"
      
      cl.send("The setup of this game: #{sstr}@d")
      cl.send("As a result of this setup, the game will require @C#{server.get_needed}@d more players to start.\r\n")
      server.handle_command('roles')
      cl.send("You can use '@Gset@d' (type it with no arguments to see how) to change these values")
    elsif args.size == 1
      roles = Player.get_roles
      
      if roles.include?(args[0])
        count = @config[:setup][Player.get_role_by_name(args[0])]
        unless count == :excess
          cl.send("There will be @C#{count}@d players with the role @C#{args[0]}@d.")
        else
          cl.send("The role #{args[0]} can have any amount of players, but will only be filled after all of the other roles are.")
        end
      else
        cl.send(STRINGS[:no_role])
      end
    else
      cl.send("Usage: @Gsetup@d to see the full setup or @Gsetup <role>@d to see how many players will have <role>.")
    end
  end
  
  command(:set, :waiting) do |args, cl, server|
    next cl.send(STRINGS[:not_host]) if cl != @@host
    
    if args.size == 2
      roles = Player.get_roles

      if roles.include?(args[0])
        role = Player.get_role_by_name(args[0])

        val = (args[1] == "excess" ? :excess : args[1].to_i)
        oldval = @@config[:setup][role]
        
        @@config[:setup][role] = val

        server.send_to_all("#{cl.player.name} changed the amount of #{args[0]} from #{oldval || 0} to #{val}")

      else
        cl.send(STRINGS[:no_role])
      end

    else
      next cl.send("Usage: @Gset <role> <number or 'excess'>@d to set the amount of players needed for @G<role>@d. @G'excess'@d means any extra players will be assigned to @G<role>@d.") 
    end
    
  end
  
  
  def say(message)
    send_to_all("@Y#{@client.player.name} says: #{message}@d")
  end
  
  command(:say, :waiting, :playing) do |args, cl, server|
    if cl.screen == :playing && @@game.is_night?
      next cl.send("You would wake people up!")
    else
      server.say(args.join(' '))
    end
  end
  
  command(:mchat, :playing) do |args, cl, server|
    pl = cl.player
    
    if !pl.is_a?(Mafia)
      next cl.send("You cannot talk with the Mafia, because you are not one.")
    end
    
    if !@@game.is_night?
      next cl.send("It would be too suspicious to plot during the day.")
    end
    
    pl.mafia_chat(@@game.phase, args.join(' '))
  end
  
  command(:visit, :playing) do |args, cl, server|
    pl = cl.player
    
      
    name = args[0]
    who = find_player(name)
    
    if !@@game.is_night?
      next cl.send("You can only visit people at night.")
    end
    
    if !who
      next cl.send("You search for #{name} but cannot find them.")
    end
    
    if pl.is_a? Visiter
      more = nil
      pl.visit(@@game.phase, who, more)
    else
      cl.send("You do not visit people at night.")
    end
  end
  
  command(:vote, :playing) do |args, cl, server|
    
    name = args[0]
    
    if !@@game.is_day?
      next cl.send("You should be sleeping right now!")
    end
    
    if !name
      next cl.send("You vote to lynch nobody.")
    end
    
    who = find_player(name)
    
    if !who
      next cl.send("To your surprise, you find that #{name} doesn't exist.")
    end
    
    msg = 
     ["Proud of the democratic system, you cast your vote for #{who}.",
      "You cast your vote for #{who}.",
      "You tell the town that #{who} should be lynched."].sample
    cl.send(msg)
    cl.player.lynch_vote(@@game.phase, who)
  end
  
  def o_handle_command(command)
    case @client.screen
    when :name
      
      
    when :waiting
      
    when :playing
      pl = @client.player
      
      
      
      if (m = command.match(/\Avote(?: (.*?))?\z/))
        who = m[1]
        
        if !@@game.is_day?
          return @client.send("You should be sleeping right now!")
        end
        
        if !m[1]
          return @client.send("You vote to lynch nobody.")
        end
        
        who = find_player(who)
        
        if !who
          return @client.send("The town laughs and allows you to cast your vote for #{m[1]}, who doesn't really exist.")
        end
        
        msg = ["Proud of the democratic system, you cast your vote for #{who}.", "You cast your vote for #{who}.", "You tell the town that #{who} should be lynched."].sample
        @client.send(msg)
        pl.lynch_vote(@@game.phase, who)
      end
    end
  end
  
  def strip_subch(data)
    data.gsub(Telnet::C_REGEX, '')
  end
  
  def unbind
    puts 'Disconnection'
    send_to_all("#{@client.player.name} has disconnected.")
    @@clients.delete(@client)
    send_to_all("@Y#{get_needed}@d needed now.")
    
    if @client == @@host
      send_to_all("The host disconnected! Assigning next player as host")
      
      if h = @@clients.first 
        set_host(h)
        send_to_all("#{@@host.player.name} is now the host.")
      else
        puts 'There are no players left.'
        @@host_spot_open = true
      end
    end
  end
  
  def start_game
    @@game = Game.new(name: "game", setup: @@config[:setup], time: @@config[:time],
                      end_cb: proc { EM.add_timer(1) { EM.stop } } )
    @@clients.each do |client|
      
      @@game.add_players(client.player)
      
      client.setscreen(:playing)
      
    end

    @@game.start
    
    @@game.players.each do |player|
      @@clients.find { |cl| cl.player.name == player.name }.player = player
    end
  end
  
  
  
end

        

class MafiaClient
  
  attr_accessor :player
  attr_reader :screen, :commands
  
  def initialize(cbs)
    @player = Player.new('placeholder', 
      send: proc do |msg| cbs[:send].call(msg) end,
      die:  proc do
        setscreen(:dead)
      end
    )
  end
  
  def send(msg)
    @player.send(msg)
  end
  
  def setscreen(name)
    @screen = name
    self
  end
  
  
end

class MafiaConnection < EM::Connection
  def initialize(opts)
    @send = opts[:send]
    @close = opts[:close] 
  end
  
  
  def receive_data(data)
    @send.call(data)
  end

  def unbind
    @close.call()
  end
end


require 'em-websocket'

EM.run do
  ip = CONFIG[:host] || '192.168.0.8'
  port = CONFIG[:port] || 8081
  wsport = CONFIG[:wsport] || 8000
  
  EM.start_server(ip, port, MafiaServer)
  puts "Server started at #{ip}:#{port}"
  
  EM::WebSocket.start(:host => ip, :port => 8000) do |ws|
    connection = nil
    
    ws.onopen {
      puts 'Someone has connected to the WebSocket'
      
      
      c_proxy = EM.connect(ip, port, MafiaConnection, 
                           send: proc do |msg| ws.send(msg) end,
                           close: proc do ws.close end)
        
      ws.define_singleton_method(:proxy) { c_proxy }
       
    }
    
    ws.onmessage { |msg|
      ws.proxy.send_data(msg << "\r\n")
    }
    
    ws.onclose {
      puts 'WebSocket disconnection'
      ws.proxy.close_connection
    }
    
      
  end
  puts "WebSocket server started at #{ip}:#{wsport}"
  
end
