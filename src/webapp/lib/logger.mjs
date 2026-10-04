import { hostname as getHostname } from "node:os";
import pino from "pino";
import { createStream } from "pino-seq";

const instanceHostname = getHostname();
const streams = [{ stream: process.stdout }];

if (process.env.SEQ_URL) {
  const seqStream = createStream({
    serverUrl: process.env.SEQ_URL,
    additionalProperties: {
      service: "nextjs-bff",
      environment: process.env.NODE_ENV ?? "development",
      hostname: instanceHostname,
    },
    onError(error) {
      console.error("[seq-logging] Failed to send logs to Seq:", error);
    },
  });

  streams.push({ stream: seqStream });
}

export const logger = pino(
  {
    name: "nextjs-bff",
    level: process.env.LOG_LEVEL ?? "info",
    base: {
      service: "nextjs-bff",
      environment: process.env.NODE_ENV ?? "development",
      hostname: instanceHostname,
    },
  },
  pino.multistream(streams),
);
