---------
- MAFIA -
---------

This program simulates a simple version of the party game "Mafia" (see
http://en.wikipedia.org/wiki/Mafia_(party_game) for more information).
This game is strictly multiplayer and needs at least 5-6 players to have
a meaningful game.

The game is played through sockets. You can connect to the server with
the 'telnet' command or the WebSocket layer with the HTML5 client included
with the server. When the terminal opens in the browser, type "connect <ip>
<port>" to connect to the server.

To test the program, specify the ip as 'localhost' in config.rb and run it
with "ruby server.rb"

Even though this game is very simple, it can be extended easily. For example,
the "Doctor" role isn't included in the original but is provided in doctor.rb
as an example of an extension. To play with it, insert "include './doctor.rb'"
into server.rb after "player.rb" is included.

Explanation of roles:
 - Villager: sleeps throughout the night
 - Mafia: collectively kill one player each night
 - Cop: investigates one person during the night
 - Doctor: can "save" one person during the night. If this person was
   targetted by the Mafia, he will not die.


