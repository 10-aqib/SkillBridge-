import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

// This cookie check only provides fast redirects. The protected server layout
// and every privileged API independently verify the Firebase session token.
export function proxy(request: NextRequest) {
  const session = request.cookies.get('session')?.value;
  const isAdminRoute = request.nextUrl.pathname.startsWith('/adminpanel');

  if (isAdminRoute && !session) {
    return NextResponse.redirect(new URL('/admin-login', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|api).*)'],
};
