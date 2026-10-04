import pino from "pino";
import { createStream } from "pino-seq";

const streams = [{ stream: process.stdout }];

if (process.env.SEQ_URL) {
  const seqStream = createStream({
    serverUrl: process.env.SEQ_URL,
    additionalProperties: {
      service: "nextjs-bff",
      environment: process.env.NODE_ENV ?? "development",
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
    },
  },
  pino.multistream(streams),
);
