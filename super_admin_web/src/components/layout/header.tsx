'use client';

import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Bell, FileDown, LogOut, Menu, ShieldCheck } from 'lucide-react';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { auth } from '@/lib/firebase/client';
import { signOut } from 'firebase/auth';
import type { AdminIdentity } from '@/lib/auth/admin-session';
import { ThemeToggle } from '@/components/sb/theme-toggle';

export function Header({
  admin,
  onMenuClick,
}: {
  admin: AdminIdentity;
  onMenuClick: () => void;
}) {
  const router = useRouter();
  const displayName = admin.name || admin.email || 'Administrator';

  const handleLogout = async () => {
    try {
      await fetch('/api/auth/session', { method: 'DELETE' });
      await signOut(auth);
      router.replace('/admin-login');
      router.refresh();
    } catch (error) {
      console.error('Error logging out:', error);
    }
  };

  return (
    <header data-sb className="sticky top-0 z-20 flex h-16 items-center justify-between border-b border-sb-border bg-sb-surface/95 px-4 backdrop-blur md:px-6">
      <div className="flex min-w-0 items-center gap-3">
        <button
          onClick={onMenuClick}
          className="sb-focus flex size-10 items-center justify-center rounded-sb-control text-sb-text-secondary hover:bg-sb-surface-sunken md:hidden"
          aria-label="Open navigation"
        >
          <Menu className="h-5 w-5" />
        </button>
        <div className="hidden items-center gap-2 text-xs font-medium text-sb-text-secondary sm:flex">
          <span>SkillBridge</span>
          <span>/</span>
          <span className="font-semibold text-sb-text">Administration</span>
        </div>
        <div className="flex items-center gap-1.5 rounded-full bg-sb-success-subtle px-2.5 py-1 text-xs font-semibold text-sb-on-success-subtle">
          <ShieldCheck className="h-3.5 w-3.5" />
          Secure session
        </div>
      </div>

      <div className="flex items-center gap-2">
        <a
          href="/api/admin/export/summary"
          className="sb-focus hidden h-9 items-center gap-2 rounded-sb-control border border-sb-border-strong bg-sb-surface px-3 text-sm font-semibold text-sb-primary transition-colors hover:bg-sb-primary-subtle sm:flex"
        >
          <FileDown className="h-4 w-4" />
          Export summary
        </a>
        <ThemeToggle className="hidden sm:flex" />
        <Link
          href="/adminpanel/reports"
          aria-label="Open moderation reports"
          className="sb-focus relative flex size-9 items-center justify-center rounded-sb-control text-sb-text-secondary transition-colors hover:bg-sb-surface-sunken hover:text-sb-text"
        >
          <Bell className="h-4 w-4" />
        </Link>

        <DropdownMenu>
          <DropdownMenuTrigger className="sb-focus flex cursor-pointer items-center gap-2 rounded-sb-control p-1.5 transition-colors hover:bg-sb-surface-sunken">
            <span className="flex size-8 items-center justify-center rounded-full bg-sb-primary-subtle text-xs font-semibold text-sb-on-primary-subtle">
              {displayName.slice(0, 2).toUpperCase()}
            </span>
            <span className="hidden max-w-40 flex-col text-left lg:flex">
              <span className="truncate text-xs font-bold text-sb-text">{displayName}</span>
              <span className="text-[10px] font-medium text-sb-text-secondary">
                {admin.role === 'admin' ? 'Administrator' : 'Super administrator'}
              </span>
            </span>
          </DropdownMenuTrigger>
          <DropdownMenuContent className="mt-2 w-64" align="end">
            <DropdownMenuLabel className="font-normal">
              <span className="block truncate text-sm font-semibold text-sb-text">{displayName}</span>
              <span className="block truncate text-xs text-sb-text-secondary">{admin.email}</span>
            </DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={() => router.push('/adminpanel/settings')} className="cursor-pointer">
              Account & security
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => router.push('/adminpanel/audit-logs')} className="cursor-pointer">
              Security audit
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={handleLogout} className="cursor-pointer text-sb-error focus:text-sb-error">
              <LogOut className="mr-2 h-4 w-4" /> Sign out
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  );
}
