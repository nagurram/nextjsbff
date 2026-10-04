import { createServer } from "node:http";
import next from "next";

const hostname = process.env.HOSTNAME ?? "0.0.0.0";
const port = Number.parseInt(process.env.PORT ?? "3000", 10);

const app = next({ dev: false, hostname, port });
const handle = app.getRequestHandler();

await app.prepare();

const server = createServer((request, response) => {
  handle(request, response).catch((error) => {
    console.error("Failed to handle request:", error);
    if (!response.headersSent) {
      response.statusCode = 500;
    }
    response.end("Internal Server Error");
  });
});

server.on("error", (error) => {
  console.error("HTTP server failed:", error);
  process.exitCode = 1;
});

server.listen(port, hostname, () => {
  console.log(`> BFF server listening on http://${hostname}:${port}`);
});
