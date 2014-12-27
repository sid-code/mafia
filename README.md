## Mafia

### Description

This program simulates a simple version of the party game [Mafia](http://en.wikipedia.org/wiki/mafia_(party_game))
This game is strictly multiplayer and needs at least 5-6 players to have
a meaningful game.

The game is played through sockets. You can connect to the server with
the `telnet` command or the WebSocket layer with the HTML5 client included
with the server. When the terminal opens in the browser, type `connect <ip>
<port>` to connect to the server. This client can be found in the `client`
directory.

### Dependencies, configuration, and running

This game requires the gems `eventmachine` and `em-websocket` to run.

Once these gems are installed, open `config.rb` to configure the server.
(see section on setup if the `setup` key doesn't make sense)

```
ruby server.rb
```

Now connect to the server using telnet or the HTML5 client.

### Explanation of roles

 * Villager: sleeps throughout the night
 * Mafia: collectively kill one player each night
 * Cop: investigates one person during the night
 * Doctor: can "save" one person during the night. If this person was
   targetted by the Mafia, he will not die.

### Setups

The setup tells the game what roles to assign to people. For example, if
the setup is configured as the hash

```ruby
{ Mafia => 2, 
  Cop => 1,
  Villager => :excess }
```

then the game will assign 2 players the Mafia role, 1 player the Cop role, and
any more players that join the Villager role. Note that you can have multiple
`:excess` roles. Extra players will be assigned to them randomly.

The setup can be changed by the host before the game starts with the `set` command
and can be viewed by anyone with the `setup` command.

### doctor.rb

`doctor.rb` is a file containing the doctor role in its entirety. It serves as
an example of an added role - if the role is simple enough, no internal 
modification is necessary to add it.

### HTML5 client

The HTML5 client uses the WebSocket API to connect to the server. The only
requirement is a modern browser.

It uses [jQuery](http://jquery.com/) and [jQuery terminal emulator](http://terminal.jcubic.pl/).
