import { readFileSync } from "node:fs";
import IdentityServer4Provider from "next-auth/providers/identity-server4";
import type { NextAuthOptions } from "next-auth";
import { logger } from "@/lib/logger.mjs";

const identityServerCa = process.env.IDENTITY_SERVER_CA_CERT
  ? readFileSync(process.env.IDENTITY_SERVER_CA_CERT, "utf8")
  : undefined;

export const authOptions: NextAuthOptions = {
  providers: [
    IdentityServer4Provider({
      issuer: process.env.IDENTITY_SERVER_ISSUER ?? "https://localhost:5001",
      clientId: process.env.IDENTITY_SERVER_CLIENT_ID ?? "interactive",
      clientSecret: process.env.IDENTITY_SERVER_CLIENT_SECRET ?? "",
      authorization: {
        params: {
          scope: "openid profile scope2",
        },
      },
      httpOptions: {
        ...(identityServerCa ? { ca: identityServerCa } : {}),
        timeout: 15000,
      },
    }),
  ],
  secret: process.env.NEXTAUTH_SECRET,
  session: {
    strategy: "jwt",
  },
  logger: {
    error(code, metadata) {
      logger.error(
        {
          component: "next-auth",
          code,
          err: metadata instanceof Error ? metadata : metadata.error,
        },
        "NextAuth error",
      );
    },
    warn(code) {
      logger.warn({ component: "next-auth", code }, "NextAuth warning");
    },
    debug(code) {
      logger.debug({ component: "next-auth", code }, "NextAuth debug");
    },
  },
  events: {
    async signIn({ account, isNewUser }) {
      logger.info(
        {
          component: "next-auth",
          provider: account?.provider,
          isNewUser,
        },
        "User signed in",
      );
    },
    async signOut() {
      logger.info({ component: "next-auth" }, "User signed out");
    },
  },
};
