'use client';

import { useState } from 'react';
import { X } from 'lucide-react';
import { Sidebar } from '@/components/layout/sidebar';
import { Header } from '@/components/layout/header';
import type { AdminIdentity } from '@/lib/auth/admin-session';

export function AdminShell({
  admin,
  children,
}: {
  admin: AdminIdentity;
  children: React.ReactNode;
}) {
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  return (
    <div data-sb className="min-h-screen bg-sb-canvas text-sb-text">
      <aside className="fixed inset-y-0 left-0 z-40 hidden w-64 md:block">
        <Sidebar admin={admin} />
      </aside>

      {mobileNavOpen && (
        <div className="fixed inset-0 z-50 md:hidden">
          <button
            aria-label="Close navigation"
            className="absolute inset-0 bg-black/45"
            onClick={() => setMobileNavOpen(false)}
          />
          <aside className="relative h-full w-[min(19rem,86vw)] shadow-sb-overlay">
            <button
              aria-label="Close navigation"
              onClick={() => setMobileNavOpen(false)}
              className="sb-focus absolute right-3 top-3 z-10 flex size-10 items-center justify-center rounded-sb-control text-sb-text-secondary hover:bg-sb-surface-sunken"
            >
              <X className="h-4 w-4" />
            </button>
            <Sidebar admin={admin} onNavigate={() => setMobileNavOpen(false)} />
          </aside>
        </div>
      )}

      <div className="flex min-h-screen flex-col md:pl-64">
        <Header admin={admin} onMenuClick={() => setMobileNavOpen(true)} />
        <main className="mx-auto w-full max-w-[1600px] flex-1 p-4 md:p-6 lg:p-8">
          {children}
        </main>
      </div>
    </div>
  );
}
