import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// Ava: the GRC tenant "complyverse" was renamed to "ava". Any stale
// complyverse/compliverse subdomain 308-redirects to the live "ava" workspace,
// so the old address no longer serves a dead login page.
export function middleware(req: NextRequest) {
  const host = req.headers.get('host') || '';
  if (/^compl[iy]verse\./i.test(host)) {
    const url = new URL(req.url);
    url.host = host.replace(/^compl[iy]verse\./i, 'ava.');
    return NextResponse.redirect(url, 308);
  }
  return NextResponse.next();
}

export const config = {
  // Pages only — leave the API proxy, Next internals and static icons alone.
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico|favicon.svg|icon.svg).*)'],
};
