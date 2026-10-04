"use client";

import { signIn, signOut, useSession } from "next-auth/react";

export default function Home() {
  const { data: session, status } = useSession();

  return (
    <main className="flex flex-1 items-center justify-center bg-zinc-50 px-6 dark:bg-black">
      <section className="flex w-full max-w-md flex-col items-center gap-6 rounded-2xl border border-zinc-200 bg-white p-8 text-center shadow-sm dark:border-zinc-800 dark:bg-zinc-950">
        <div>
          <h1 className="text-2xl font-semibold">BFF Next.js App</h1>
          <p className="mt-2 text-zinc-600 dark:text-zinc-400">
            Sign in with your local IdentityServer account.
          </p>
        </div>

        {status === "loading" ? (
          <p role="status">Checking your session...</p>
        ) : session ? (
          <>
            <p>
              Signed in as{" "}
              <span className="font-medium">
                {session.user?.name ?? session.user?.email ?? "user"}
              </span>
            </p>
            <button
              className="rounded-md bg-zinc-900 px-4 py-2 font-medium text-white hover:bg-zinc-700 dark:bg-white dark:text-zinc-900 dark:hover:bg-zinc-200"
              onClick={() => signOut()}
              type="button"
            >
              Sign out
            </button>
          </>
        ) : (
          <button
            className="rounded-md bg-zinc-900 px-4 py-2 font-medium text-white hover:bg-zinc-700 dark:bg-white dark:text-zinc-900 dark:hover:bg-zinc-200"
            onClick={() => signIn("identity-server4")}
            type="button"
          >
            Sign in
          </button>
        )}
      </section>
    </main>
  );
}
