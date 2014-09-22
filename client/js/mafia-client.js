
$(function() {

  var term = $("#term_demo").terminal(function(command, term) {
    var split = command.trim().split(/ /g);
    var cmd = split.shift(), args = split;
    if (cmd === "connect") {
      var host = args[0], port = args[1];
      
      if (!term.socket) {
        if (!host || !port) {
          return term.echo("Usage: " + cmd + " <host> <port>");
        }
        
        term.socket = connect(host, port, term);
      } else {
        term.echo("Ignoring arguments, using existing connection.");
        term.echo("Press Ctrl-D and type disconnect to end the connection.");
          term.socket.onopen();
      }
    }
    
    if (cmd === "disconnect") {
      if (!term.socket) {
        term.echo("Not connected.");
      } else {
        term.socket.close();
        delete term.socket;
      }
    }
  }, {
    greetings: "Mafia WebSocket client",
    name: "mafia",
    height: 500,
    prompt: "prompt> "
  });
  term.echo("Type 'connect <host> <port>' to connect");
});

function connect(host, port, term) {
  var url = "ws://" + host + ":" + port;
  var socket = new WebSocket(url);
  term.echo("Attempting to connect to " + url + "...");
  socket.onmessage = function(msg) {
    term.echo(msg.data);
  };

  socket.onopen = function() {
    term.push(function(command, term) {
      socket.send(command);
    }, {
      name: "mafiagame",
      prompt: "mafia> "
    });

    socket.onclose = function() {
      delete term.socket;
      term.echo("Connection lost.");
      term.pop();
    };
    
  };

  socket.onerror = function(err) {
    delete term.socket;
    console.log(err);
    term.error("WebSocket error - Check host/port");
  };

  return socket;
}
