function connect() {
	socket = new WebSocket(getBaseURL() + "/ws");

	socket.onmessage = function(msg) {
      var msgVal = JSON.parse(msg.data);

      var counter = document.getElementById("counter");
      counter.innerHTML = msgVal.counter;

      var name = document.getElementById("name");
      name.innerHTML = msgVal.name;

      var temp = document.getElementById("temperature");
      temp.innerHTML = msgVal.temperature;

      var stat = document.getElementById("status");
      console.log(msgVal.status);
      switch (msgVal.status) {
         case 0:
            stat.innerHTML = "ID";
            stat.className = "idle";
            break;
         case 1:
            stat.innerHTML = "RUN";
            stat.className = "run";
            break;
         default:
            stat.innerHTML = "DEF";
            stat.className = "boh";
            break;

      }

      console.log("on mesg");
   }

   socket.onclose = function() {
      console.log("socket closed - reconnecting...");
      connect();
   }
}

function getBaseURL() {
   var href = window.location.href.substring(7); // strip "http://"
   var idx = href.indexOf("/");
   return "ws://" + href.substring(0, idx);
}
