'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { 
  LayoutDashboard, 
  Users, 
  Briefcase, 
  ClipboardList,
  AlertTriangle, 
  ShieldAlert,
  Settings, 
  LogOut,
  Search,
  CheckCircle2
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { auth } from '@/lib/firebase/client';
import { signOut } from 'firebase/auth';

const routes = [
  {
    label: 'Dashboard',
    icon: LayoutDashboard,
    href: '/dashboard',
  },
  {
    label: 'Users',
    icon: Users,
    href: '/users',
  },
  {
    label: 'Workers',
    icon: Briefcase,
    href: '/workers',
  },
  {
    label: 'Jobs & Contracts',
    icon: ClipboardList,
    href: '/jobs',
  },
  {
    label: 'Reports & Disputes',
    icon: AlertTriangle,
    href: '/reports',
  },
  {
    label: 'Audit Logs',
    icon: ShieldAlert,
    href: '/audit-logs',
  },
];

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();

  const handleLogout = async () => {
    try {
      await signOut(auth);
      await fetch('/api/auth/session', { method: 'DELETE' });
      router.push('/login');
      router.refresh();
    } catch (error) {
      console.error('Error logging out:', error);
    }
  };

  return (
    <aside className="w-64 bg-white border-r border-[#E8EFF9] flex flex-col h-full select-none figma-card-shadow z-30">
      {/* Top Profile Card (Figma Style) */}
      <div className="p-5 pb-4 border-b border-[#F0F4FA]">
        <div className="flex items-center gap-3">
          <div className="relative">
            <Avatar className="h-11 w-11 rounded-full ring-2 ring-[#2F80ED]/20">
              <AvatarImage src="/avatar-admin.png" alt="Admin" />
              <AvatarFallback className="bg-gradient-to-br from-[#2F80ED] to-[#6366F1] text-white font-bold text-sm">
                AQ
              </AvatarFallback>
            </Avatar>
            <span className="absolute bottom-0 right-0 w-3 h-3 bg-emerald-500 border-2 border-white rounded-full"></span>
          </div>
          <div className="flex flex-col min-w-0 flex-1">
            <div className="flex items-center gap-1.5">
              <span className="text-sm font-bold text-slate-800 truncate">Aqib (Admin)</span>
              <CheckCircle2 className="w-3.5 h-3.5 text-[#2F80ED] shrink-0" />
            </div>
            <span className="text-xs text-slate-400 font-medium">Super Administrator</span>
          </div>
        </div>

        {/* Search Bar (Figma Style) */}
        <div className="mt-4 relative">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
          <input 
            type="text"
            placeholder="Search here..."
            className="w-full h-9 pl-9 pr-3 rounded-full bg-[#F4F7FE] border-none text-xs text-slate-700 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-[#2F80ED]/30 transition"
          />
        </div>
      </div>

      {/* Navigation List */}
      <div className="flex-1 px-3 py-4 space-y-1.5 overflow-y-auto">
        <div className="px-3 pb-1 text-[11px] font-semibold uppercase tracking-wider text-slate-400">
          Main Menu
        </div>
        {routes.map((route) => {
          const isActive = pathname === route.href || pathname.startsWith(`${route.href}/`);
          const Icon = route.icon;

          return (
            <Link
              key={route.href}
              href={route.href}
              className={cn(
                'group flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm font-medium transition-all duration-150',
                isActive 
                  ? 'bg-[#EBF3FF] text-[#2F80ED] font-semibold shadow-xs' 
                  : 'text-slate-500 hover:text-slate-900 hover:bg-[#F8FAFD]'
              )}
            >
              <Icon className={cn(
                'h-4 w-4 transition-colors',
                isActive ? 'text-[#2F80ED]' : 'text-slate-400 group-hover:text-slate-700'
              )} />
              <span className="truncate">{route.label}</span>
              {isActive && (
                <div className="ml-auto w-1.5 h-1.5 rounded-full bg-[#2F80ED]"></div>
              )}
            </Link>
          );
        })}
      </div>

      {/* Pinned Bottom Settings & Logout */}
      <div className="p-3 border-t border-[#F0F4FA] space-y-1 bg-[#FAFCFF]">
        <Link
          href="/settings"
          className={cn(
            'flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm font-medium transition-all duration-150',
            pathname === '/settings' 
              ? 'bg-[#EBF3FF] text-[#2F80ED] font-semibold' 
              : 'text-slate-500 hover:text-slate-900 hover:bg-white'
          )}
        >
          <Settings className="h-4 w-4 text-slate-400" />
          <span>Settings</span>
        </Link>
        <button
          onClick={handleLogout}
          className="w-full flex items-center gap-3 px-4 py-2.5 rounded-xl text-sm font-medium text-red-500 hover:text-red-700 hover:bg-red-50/70 transition-all duration-150 text-left"
        >
          <LogOut className="h-4 w-4 text-red-400" />
          <span>Sign Out</span>
        </button>
      </div>
    </aside>
  );
}
