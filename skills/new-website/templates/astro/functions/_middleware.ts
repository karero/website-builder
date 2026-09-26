// Cloudflare Pages middleware. Two jobs, both on Cloudflare's *.pages.dev hosts only —
// the live custom domain is always served unchanged:
//
// 1. Preview hosts (<branch>.<project>.pages.dev, <hash>.<project>.pages.dev) get
//    `X-Robots-Tag: noindex` so Google never indexes a staging copy.
// 2. The project's production alias <project>.pages.dev 301-redirects to the live
//    domain — but ONLY once the CANONICAL_URL environment variable is set (Cloudflare
//    dashboard → the project → Settings → Variables and Secrets → Production, e.g.
//    https://example.com, then redeploy). Why: noindex alone did not keep the alias out
//    of AI answers — AI search engines were seen citing <project>.pages.dev instead of
//    the real domain (2026-09). A 301 at least sends every visitor who follows such a
//    link to the real domain, and tells crawlers which host is canonical.
//    Why a variable instead of SITE.url: SITE.url is set before launch, when the domain
//    may not serve this site yet (not attached, or still the old site), and a redirect
//    then would send visitors nowhere useful. Unset, the alias is noindexed like any
//    preview, exactly as before.
//
// Project names cannot contain dots, so the production alias is the only three-label
// *.pages.dev host; every preview has four. (If that ever changed, a dotted alias would
// simply stay noindexed — the safe side.)
//
// Typed with a minimal local interface so it compiles under the project's strict
// tsconfig WITHOUT depending on @cloudflare/workers-types. (Cloudflare provides
// the real `PagesFunction`/`EventContext` globals at deploy time; this is a
// structural subset of what this handler actually uses.)
interface MiddlewareContext {
  request: Request;
  env: { CANONICAL_URL?: string };
  next: () => Promise<Response>;
}

// Hostnames may carry trailing dots (example.com.) and still be the same host.
function bareHost(url: URL): string {
  return url.hostname.replace(/\.+$/, '');
}

function isPagesDev(host: string): boolean {
  return host === 'pages.dev' || host.endsWith('.pages.dev');
}

// The live origin from CANONICAL_URL, or null when unset or unusable. A pages.dev value
// would redirect the alias to itself or to a preview, so it counts as unusable too.
function liveOrigin(value: string | undefined): string | null {
  if (!value) return null;
  let url: URL | null = null;
  try {
    url = new URL(value);
  } catch {
    // not a URL at all — reported below with the other unusable values
  }
  const host = url ? bareHost(url) : '';
  const emptyLabel = host.split('.').some((label) => !label); // '', '.x', 'x..y'
  if (!url || url.protocol !== 'https:' || emptyLabel || isPagesDev(host)) {
    console.error(`CANONICAL_URL is not an https live-domain URL, not redirecting: ${value}`);
    return null;
  }
  return `https://${host}${url.port ? `:${url.port}` : ''}`;
}

export const onRequest = async (context: MiddlewareContext): Promise<Response> => {
  const url = new URL(context.request.url);
  const host = bareHost(url);
  if (!isPagesDev(host)) return context.next();

  const live = liveOrigin(context.env.CANONICAL_URL);
  if (live && host.split('.').length === 3) {
    return Response.redirect(live + url.pathname + url.search, 301);
  }

  const res = await context.next();
  const headers = new Headers(res.headers);
  headers.set('X-Robots-Tag', 'noindex, nofollow');
  return new Response(res.body, { status: res.status, statusText: res.statusText, headers });
};
