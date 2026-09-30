'use client';

import { useRouter } from 'next/navigation';
import { 
  Bell, 
  FileDown, 
  ShieldCheck, 
  Search,
  ExternalLink,
  Sparkles
} from 'lucide-react';
import { 
  DropdownMenu, 
  DropdownMenuContent, 
  DropdownMenuItem, 
  DropdownMenuLabel, 
  DropdownMenuSeparator, 
  DropdownMenuTrigger 
} from '@/components/ui/dropdown-menu';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { auth } from '@/lib/firebase/client';
import { signOut } from 'firebase/auth';

export function Header() {
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
    <header className="h-16 bg-white border-b border-[#E8EFF9] px-6 flex items-center justify-between z-20 figma-card-shadow">
      {/* Left: Platform Status & Breadcrumb */}
      <div className="flex items-center gap-3">
        <div className="flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-50 border border-emerald-200/60 text-emerald-700 text-xs font-semibold">
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
          Live Sync
        </div>
        <div className="hidden sm:flex items-center gap-1.5 text-xs text-slate-400 font-medium">
          <span>SkillBridge</span>
          <span>/</span>
          <span className="text-slate-700 font-semibold">Super Admin Hub</span>
        </div>
      </div>

      {/* Right: Actions & Profile Menu */}
      <div className="flex items-center gap-2.5">
        {/* Quick Export Button (Figma Style) */}
        <button 
          onClick={() => alert('Exporting platform report snapshot (CSV)...')}
          className="hidden md:flex items-center gap-1.5 h-9 px-3.5 rounded-xl bg-[#F4F7FE] hover:bg-[#EBF3FF] text-slate-600 hover:text-[#2F80ED] text-xs font-semibold transition duration-150"
        >
          <FileDown className="h-4 w-4" />
          <span>Export Summary</span>
        </button>

        {/* Notification Bell with Badge (Figma Style) */}
        <div className="relative">
          <button 
            className="w-9 h-9 rounded-xl bg-[#F4F7FE] hover:bg-[#EBF3FF] flex items-center justify-center text-slate-600 hover:text-[#2F80ED] transition duration-150"
            title="Notifications"
          >
            <Bell className="h-4 w-4" />
            <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-red-500 ring-2 ring-white"></span>
          </button>
        </div>

        {/* Profile Dropdown */}
        <DropdownMenu>
          <DropdownMenuTrigger className="flex items-center gap-2 pl-2 pr-1 py-1 rounded-xl hover:bg-[#F4F7FE] transition outline-none cursor-pointer">
            <Avatar className="h-8 w-8 ring-2 ring-[#2F80ED]/20">
              <AvatarFallback className="bg-gradient-to-br from-[#2F80ED] to-[#6366F1] text-white font-bold text-xs">
                AQ
              </AvatarFallback>
            </Avatar>
            <div className="hidden lg:flex flex-col text-left">
              <span className="text-xs font-bold text-slate-800 leading-none">Aqib</span>
              <span className="text-[10px] text-slate-400 font-medium mt-0.5">Super Admin</span>
            </div>
          </DropdownMenuTrigger>
          <DropdownMenuContent className="w-56 mt-2" align="end">
            <DropdownMenuLabel className="font-normal">
              <div className="flex flex-col space-y-1">
                <p className="text-sm font-bold text-slate-800">Muhammad Aqib</p>
                <p className="text-xs text-slate-400 truncate">ak9024706@gmail.com</p>
              </div>
            </DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={() => router.push('/settings')} className="cursor-pointer">
              <span>Platform Settings</span>
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => router.push('/audit-logs')} className="cursor-pointer">
              <span>Security & Audit</span>
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={handleLogout} className="text-red-600 focus:text-red-600 cursor-pointer">
              <span>Sign out</span>
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  );
}
