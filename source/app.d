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
      logDiagnostic("Controller.waitForMessage");
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

   //http://dlang.org/spec/function.html#parameters
   // scope:	references in the parameter cannot be escaped (e.g. assigned to a global variable)

   void getWS(scope WebSocket socket) {
      logInfo("getWS");
      auto t = runTask({
       while (socket.connected) {
         logInfo("\tserialize");
         string json = serializeToJsonString(ctrl.getData);
         logDiagnostic(json);
         if (!socket.connected) break;
         try {
            logInfo("s0");
            socket.send(json);
            logInfo("s1");
            ctrl.waitForMessage();
            logInfo("s2");
         } catch (Exception e) {
            logError(e.msg);
         }
       }
         logInfo("WebChat.end WHILE");
      });

      logInfo("wait for data");
      if (socket.connected) {
         logInfo("connected");
         while (socket.waitForData) {
            logInfo("wait");
            if (!socket.connected) break;
            auto message = socket.receiveText();
            if (message.length) {
               logInfo("Web.waitForData \t\t%s", message);
            } else {
               logInfo("no data");
            }
         }
      }
      logInfo("Web.getWS \t\tdisconnected.");
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
         sleep(2000.msecs);
      }
   });
   logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}
