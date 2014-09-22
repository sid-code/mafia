CONFIG = {
  setup: { Cop => 1, Mafia => 2, Villager => :excess },
  time: 30, # How long days and nights are 
  host: 'localhost', # To play over LAN, need to specify local IP address 
  port: 8081, # Port for the TCP server to listen on
  wsport: 8000 # Port for the WebSocket server to listen on
}
