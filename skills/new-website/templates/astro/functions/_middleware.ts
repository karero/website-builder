// Cloudflare Pages middleware. Adds `X-Robots-Tag: noindex` on every preview
// deployment so Google never indexes a staging copy. Previews always live on
// *.pages.dev — including the project's own <project>.pages.dev alias, which is
// correctly noindexed as a duplicate of the custom domain. Zero configuration:
// the launched custom domain is served unchanged, with no placeholder to forget.
//
// Typed with a minimal local interface so it compiles under the project's strict
// tsconfig WITHOUT depending on @cloudflare/workers-types. (Cloudflare provides
// the real `PagesFunction`/`EventContext` globals at deploy time; this is a
// structural subset of what this handler actually uses.)
interface MiddlewareContext {
  request: Request;
  next: () => Promise<Response>;
}

export const onRequest = async (context: MiddlewareContext): Promise<Response> => {
  const res = await context.next();
  const host = new URL(context.request.url).hostname;
  if (host.endsWith('.pages.dev')) {
    const headers = new Headers(res.headers);
    headers.set('X-Robots-Tag', 'noindex, nofollow');
    return new Response(res.body, { status: res.status, statusText: res.statusText, headers });
  }
  return res;
};
