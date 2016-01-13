function start() {
   var msg = '{"action":"start"}';
   socket.send(msg);
   return false;
}

function setTray(i) {
   var msg = '{"action":"setTray", "tray": '+ i + '}';
   socket.send(msg);
   return false;
}

function setDgt(i) {
	//var socket = new WebSocket(getBaseURL() + "/dgt");
   console.log("dgt: " + i);
   var msg = '{"action":"setDgtOut", "out": '+ i + '}';
   console.log(msg);
   socket.send(msg);
   return false;
}

function connect() {
	socket = new WebSocket(getBaseURL() + "/ws");

	socket.onmessage = function(msg) {
      var msgVal = JSON.parse(msg.data);
      for (f in msgVal) {
         var el = document.getElementById(f);
         if (el != null) {
            el.innerHTML = msgVal[f];
         }
      }

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
