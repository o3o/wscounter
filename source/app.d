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

struct Data2 {
   int x;
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
   Data2 data2;
   Data2 getData2() {
      return data2;
   }

   void update() {
      data.counter++;
      data.name = "name " ~ to!string(uniform(1, 10));
      data.status = uniform!Status;
      data.temperature = uniform(0, 100);
      data2.x = uniform(0, 1000);
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

   void getCount() {
      int counter = ctrl.getData().counter;
      logInfo("Web.get counter: %d", counter);
      render!("count.dt", counter);
   }

   void getWS(scope WebSocket socket) {
      logInfo("getWS \t\tconnected");
      while (socket.connected) {
         //logInfo("%s\tWebChat.start wait", Clock.currTime.toSimpleString());
         ctrl.waitForMessage();
         logInfo("%s\tWeb.end wait", Clock.currTime.toSimpleString());
         string json = serializeToJsonString(ctrl.getData);
         socket.send(json);
      }

      logInfo("getWS disconnected.");
   }

   void getCul(scope WebSocket socket) {
      logInfo("getWS2 \t\tconnected");
      while (socket.connected) {
         //logInfo("%s\tWebChat.start wait", Clock.currTime.toSimpleString());
         ctrl.waitForMessage();
         string json = serializeToJsonString(ctrl.getData2);
         socket.send(json);
      }

      logInfo("getWS2 disconnected.");
   }

   void getAction(scope WebSocket socket) {
      logInfo("\tgetAction connected ");
      while (socket.waitForData()) {
         auto message = socket.receiveText();
         logInfo("\t%s\treceiveText %s", Clock.currTime.toSimpleString(), message);
      }
      logInfo("\tgetAction disconnected.");
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
