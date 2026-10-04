import { readFileSync } from "node:fs";
import { createServer } from "node:https";
import next from "next";

const hostname = process.env.HOSTNAME ?? "0.0.0.0";
const port = Number.parseInt(process.env.PORT ?? "3000", 10);
const certificatePath = process.env.HTTPS_CERT_FILE;
const privateKeyPath = process.env.HTTPS_KEY_FILE;

if (!certificatePath || !privateKeyPath) {
  throw new Error("HTTPS_CERT_FILE and HTTPS_KEY_FILE must point to the TLS certificate and private key.");
}

const app = next({ dev: false, hostname, port });
const handle = app.getRequestHandler();

await app.prepare();

const server = createServer(
  {
    cert: readFileSync(certificatePath),
    key: readFileSync(privateKeyPath),
  },
  (request, response) => {
    handle(request, response).catch((error) => {
      console.error("Failed to handle HTTPS request:", error);
      if (!response.headersSent) {
        response.statusCode = 500;
      }
      response.end("Internal Server Error");
    });
  },
);

server.on("error", (error) => {
  console.error("HTTPS server failed:", error);
  process.exitCode = 1;
});

server.listen(port, hostname, () => {
  console.log(`> HTTPS server listening on https://${hostname}:${port}`);
});
