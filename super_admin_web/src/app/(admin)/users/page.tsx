import { UsersService } from '@/lib/services/users.service';
import Link from 'next/link';
import { 
  Users as UsersIcon, 
  Search, 
  Filter, 
  Eye, 
  CheckCircle2, 
  UserX,
  Shield
} from 'lucide-react';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';

export const dynamic = 'force-dynamic';

export default async function UsersPage() {
  const mergedUsers = await UsersService.getUsers(100);

  const clientCount = mergedUsers.filter((u: any) => u.role === 'client').length;
  const workerCount = mergedUsers.filter((u: any) => u.role === 'worker').length;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl lg:text-3xl font-extrabold text-slate-800 tracking-tight">
            User Directory
          </h1>
          <p className="text-xs text-slate-500 mt-0.5">
            View all authenticated clients, service workers, and administrator accounts.
          </p>
        </div>

        {/* Quick Summary Badges */}
        <div className="flex items-center gap-2">
          <div className="px-3.5 py-1.5 rounded-xl bg-white border border-[#E8EFF9] figma-card-shadow flex items-center gap-2 text-xs font-semibold text-slate-700">
            <span className="w-2 h-2 rounded-full bg-[#2F80ED]"></span>
            <span>{clientCount} Clients</span>
          </div>
          <div className="px-3.5 py-1.5 rounded-xl bg-white border border-[#E8EFF9] figma-card-shadow flex items-center gap-2 text-xs font-semibold text-slate-700">
            <span className="w-2 h-2 rounded-full bg-purple-500"></span>
            <span>{workerCount} Workers</span>
          </div>
        </div>
      </div>

      {/* Main Table Card (Figma Style) */}
      <div className="bg-white rounded-2xl border border-[#E8EFF9] figma-card-shadow overflow-hidden">
        
        {/* Table Filter / Search Header */}
        <div className="p-4 border-b border-[#F0F4FA] flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div className="relative flex-1 max-w-sm">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
            <input 
              type="text"
              placeholder="Search by name, email, or role..."
              className="w-full h-9 pl-9 pr-3 rounded-xl bg-[#F4F7FE] border-none text-xs text-slate-700 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-[#2F80ED]/30 transition"
            />
          </div>
          
          <div className="flex items-center gap-2">
            <button className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-slate-200 text-xs font-semibold text-slate-600 hover:bg-slate-50 transition">
              <Filter className="w-3.5 h-3.5 text-slate-400" />
              <span>Filter Role</span>
            </button>
          </div>
        </div>

        {/* Table Content */}
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#F8FAFD] text-slate-400 font-semibold uppercase tracking-wider text-[11px] border-b border-[#E8EFF9]">
              <tr>
                <th className="px-6 py-3.5">User Profile</th>
                <th className="px-6 py-3.5">Platform Role</th>
                <th className="px-6 py-3.5">Account Status</th>
                <th className="px-6 py-3.5">Registered</th>
                <th className="px-6 py-3.5 text-right">Details</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#F0F4FA] text-slate-700 font-medium">
              {mergedUsers.map((user: any) => (
                <tr key={user.uid} className="hover:bg-[#F8FAFD] transition duration-150">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <Avatar className="h-9 w-9 rounded-full ring-1 ring-slate-200">
                        <AvatarFallback className="bg-gradient-to-br from-slate-700 to-slate-900 text-white font-bold text-xs">
                          {user.displayName ? user.displayName.slice(0, 2).toUpperCase() : 'U'}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <span className="font-bold text-slate-800 text-sm block">{user.displayName || 'Unnamed User'}</span>
                        <span className="text-slate-400 text-[11px] block">{user.email || 'No email associated'}</span>
                      </div>
                    </div>
                  </td>

                  <td className="px-6 py-4">
                    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider ${
                      user.role === 'admin' || user.role === 'SUPER_ADMIN'
                        ? 'bg-purple-50 text-purple-600 border border-purple-200/60'
                        : user.role === 'worker'
                          ? 'bg-amber-50 text-amber-600 border border-amber-200/60'
                          : 'bg-blue-50 text-blue-600 border border-blue-200/60'
                    }`}>
                      {user.role}
                    </span>
                  </td>

                  <td className="px-6 py-4">
                    {user.disabled ? (
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold bg-rose-50 text-rose-600 border border-rose-200/60">
                        <UserX className="w-3.5 h-3.5" />
                        Suspended
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold bg-emerald-50 text-emerald-600 border border-emerald-200/60">
                        <CheckCircle2 className="w-3.5 h-3.5" />
                        Active
                      </span>
                    )}
                  </td>

                  <td className="px-6 py-4 text-slate-400 text-[11px]">
                    {new Date(user.createdAt).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })}
                  </td>

                  <td className="px-6 py-4 text-right">
                    <Link href={`/users/${user.uid}`}>
                      <button className="p-2 rounded-xl bg-[#F4F7FE] hover:bg-[#EBF3FF] text-slate-500 hover:text-[#2F80ED] transition">
                        <Eye className="h-4 w-4" />
                      </button>
                    </Link>
                  </td>
                </tr>
              ))}

              {mergedUsers.length === 0 && (
                <tr>
                  <td colSpan={5} className="text-center py-12 text-slate-400">
                    No users found in directory.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
