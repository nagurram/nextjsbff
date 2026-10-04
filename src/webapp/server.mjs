import { createServer } from "node:http";
import next from "next";
import { logger } from "./lib/logger.mjs";

const hostname = process.env.HOSTNAME ?? "0.0.0.0";
const port = Number.parseInt(process.env.PORT ?? "3000", 10);

const app = next({ dev: false, hostname, port });
const handle = app.getRequestHandler();

await app.prepare();

const server = createServer((request, response) => {
  const startedAt = performance.now();

  response.once("finish", () => {
    const pathname = new URL(request.url ?? "/", "http://localhost").pathname;
    logger.info(
      {
        method: request.method,
        path: pathname,
        statusCode: response.statusCode,
        durationMs: Math.round(performance.now() - startedAt),
      },
      "HTTP request",
    );
  });

  handle(request, response).catch((error) => {
    logger.error({ err: error }, "Failed to handle request");
    if (!response.headersSent) {
      response.statusCode = 500;
    }
    response.end("Internal Server Error");
  });
});

server.on("error", (error) => {
  logger.fatal({ err: error }, "HTTP server failed");
  process.exitCode = 1;
});

server.listen(port, hostname, () => {
  logger.info({ hostname, port }, "BFF server listening");
});
