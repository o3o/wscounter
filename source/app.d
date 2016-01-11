import vibe.d;
import std.conv;

import std.random;

enum Status {
   idle,
   run,
   stop
}
struct Data {
   int counter;
   string name;
   Status status;
   double temperature;
   bool enabled;
}

final class Controller {
   ManualEvent messageEvent;
   this() {
      messageEvent = createManualEvent();
   }

   Data data;
   Data getData() {
      return data;
   }

   void update() {
      data.counter++;
      data.name = "name " ~ to!string(uniform(1, 10));
      data.status = uniform!Status;
      data.temperature = uniform(0, 100);
      messageEvent.emit();
   }

   void waitForMessage() {
      logInfo("wait");
      messageEvent.wait();
   }
}

final class Web {
   private Controller ctrl;
   this(Controller ctrl) {
      this.ctrl = ctrl;
   }

   // GET /
   void get() {
      int counter = ctrl.getData().counter;
      logInfo("Web.get counter: %d", counter);
      render!("index.dt", counter);
   }

   // GET /ws?room=...&name=...
   void getWS(scope WebSocket socket) {
      logInfo("WebChat.getWS \t\tstart getWS");
      while (true) {
			if (!socket.connected) break;
         string json = serializeToJsonString(ctrl.getData);
         logInfo(json);
         socket.send(json);
         ctrl.waitForMessage();
         logInfo("WebChat.end wait");
      }
      logInfo("Client disconnected.");
   }
}

shared static this() {
   // the router will match incoming HTTP requests to the proper routes
   auto router = new URLRouter;
   // registers each method of WebChat in the router
   Controller ctrl = new Controller();
   router.registerWebInterface(new Web(ctrl));
   // match incoming requests to files in the public/ folder
   router.get("*", serveStaticFiles("public/"));

   auto settings = new HTTPServerSettings;
   settings.port = 8080;
   settings.bindAddresses = ["::1", "127.0.0.1"];
   listenHTTP(settings, router);
   auto reader = runTask(() {
         logInfo("Start tasks");
         while (true) {
         ctrl.update();
         sleep(4000.msecs);
         }
         });
   logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}
