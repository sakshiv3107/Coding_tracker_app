/**
 * Vercel Edge Function — LeetCode GraphQL Proxy
 * Deploy this to Vercel. It forwards GraphQL requests to leetcode.com
 * server-side, bypassing the browser's CORS restriction entirely.
 *
 * Endpoint: POST /api/leetcode
 * Body: { query: string, variables: object }
 */

export const config = {
  runtime: "edge",
};

const LEETCODE_GRAPHQL = "https://leetcode.com/graphql";

// ── Allowed origins ──────────────────────────────────────────────────────────
// Add your Flutter Web deployment URL here, e.g. "https://codesphere.vercel.app"
// Use "*" during development only — restrict in production.
const ALLOWED_ORIGIN = process.env.ALLOWED_ORIGIN ?? "*";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Max-Age": "86400",
};

export default async function handler(req) {
  // ── Preflight ──────────────────────────────────────────────────────────────
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });
  }

  // ── Parse & validate body ──────────────────────────────────────────────────
  let body;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });
  }

  if (!body?.query) {
    return new Response(JSON.stringify({ error: "Missing 'query' field" }), {
      status: 400,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });
  }

  // ── Block introspection queries (basic abuse protection) ───────────────────
  if (body.query.includes("__schema") || body.query.includes("__type")) {
    return new Response(JSON.stringify({ error: "Introspection not allowed" }), {
      status: 403,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });
  }

  // ── Forward to LeetCode ────────────────────────────────────────────────────
  try {
    const upstream = await fetch(LEETCODE_GRAPHQL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        Referer: "https://leetcode.com",
        Origin: "https://leetcode.com",
      },
      body: JSON.stringify({
        query: body.query,
        variables: body.variables ?? {},
      }),
    });

    const data = await upstream.json();

    return new Response(JSON.stringify(data), {
      status: upstream.status,
      headers: {
        ...CORS_HEADERS,
        "Content-Type": "application/json",
        // Cache successful responses for 5 minutes at the CDN edge
        "Cache-Control": upstream.ok
          ? "public, s-maxage=300, stale-while-revalidate=60"
          : "no-store",
      },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Upstream fetch failed", detail: err.message }),
      {
        status: 502,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      }
    );
  }
}