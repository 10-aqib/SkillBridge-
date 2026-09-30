import { UsersService } from '@/lib/services/users.service';
import { WorkerClientActions } from './WorkerClientActions';
import { 
  Briefcase, 
  MapPin, 
  Star, 
  CheckCircle2, 
  Clock, 
  Search,
  Filter,
  ShieldCheck
} from 'lucide-react';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';

export const dynamic = 'force-dynamic';

export default async function WorkersPage() {
  const workers = await UsersService.getWorkers(100);

  const verifiedCount = workers.filter(w => w.isVerified).length;
  const pendingCount = workers.length - verifiedCount;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl lg:text-3xl font-extrabold text-slate-800 tracking-tight">
            Worker Management
          </h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Verify CNIC, review service provider skills, and oversee worker ratings.
          </p>
        </div>

        {/* Quick Summary Badges */}
        <div className="flex items-center gap-2">
          <div className="px-3.5 py-1.5 rounded-xl bg-white border border-[#E8EFF9] figma-card-shadow flex items-center gap-2 text-xs font-semibold text-slate-700">
            <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
            <span>{verifiedCount} Verified</span>
          </div>
          <div className="px-3.5 py-1.5 rounded-xl bg-white border border-[#E8EFF9] figma-card-shadow flex items-center gap-2 text-xs font-semibold text-slate-700">
            <span className="w-2 h-2 rounded-full bg-amber-500"></span>
            <span>{pendingCount} Pending Review</span>
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
              placeholder="Filter workers by name or city..."
              className="w-full h-9 pl-9 pr-3 rounded-xl bg-[#F4F7FE] border-none text-xs text-slate-700 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-[#2F80ED]/30 transition"
            />
          </div>
          
          <div className="flex items-center gap-2">
            <button className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-slate-200 text-xs font-semibold text-slate-600 hover:bg-slate-50 transition">
              <Filter className="w-3.5 h-3.5 text-slate-400" />
              <span>All Specialties</span>
            </button>
          </div>
        </div>

        {/* Table Content */}
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#F8FAFD] text-slate-400 font-semibold uppercase tracking-wider text-[11px] border-b border-[#E8EFF9]">
              <tr>
                <th className="px-6 py-3.5">Worker Profile</th>
                <th className="px-6 py-3.5">Location</th>
                <th className="px-6 py-3.5">Skills</th>
                <th className="px-6 py-3.5">Rating & Jobs</th>
                <th className="px-6 py-3.5">Verification</th>
                <th className="px-6 py-3.5">Registered</th>
                <th className="px-6 py-3.5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#F0F4FA] text-slate-700 font-medium">
              {workers.map((worker) => (
                <tr key={worker.uid} className="hover:bg-[#F8FAFD] transition duration-150">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <Avatar className="h-9 w-9 rounded-full ring-1 ring-slate-200">
                        <AvatarFallback className="bg-gradient-to-br from-blue-500 to-indigo-600 text-white font-bold text-xs">
                          {worker.displayName.slice(0, 2).toUpperCase()}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <span className="font-bold text-slate-800 text-sm block">{worker.displayName}</span>
                        <span className="text-slate-400 text-[11px] block">{worker.email || 'No email provided'}</span>
                      </div>
                    </div>
                  </td>

                  <td className="px-6 py-4">
                    <div className="flex items-center gap-1 text-slate-600">
                      <MapPin className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                      <span>{worker.city || 'Islamabad, PK'}</span>
                    </div>
                  </td>

                  <td className="px-6 py-4">
                    <div className="flex flex-wrap gap-1 max-w-[180px]">
                      {worker.skills.length > 0 ? (
                        worker.skills.slice(0, 2).map((skill: string, i: number) => (
                          <span key={i} className="bg-[#EBF3FF] text-[#2F80ED] text-[10px] font-semibold px-2 py-0.5 rounded-full">
                            {skill}
                          </span>
                        ))
                      ) : (
                        <span className="text-slate-400 italic">General Technician</span>
                      )}
                      {worker.skills.length > 2 && (
                        <span className="bg-slate-100 text-slate-500 text-[10px] font-semibold px-1.5 py-0.5 rounded-full">
                          +{worker.skills.length - 2}
                        </span>
                      )}
                    </div>
                  </td>

                  <td className="px-6 py-4">
                    <div className="flex items-center gap-1.5">
                      <div className="flex items-center gap-0.5 text-amber-500 font-bold">
                        <Star className="w-3.5 h-3.5 fill-current" />
                        <span>{Number(worker.rating || 5.0).toFixed(1)}</span>
                      </div>
                      <span className="text-slate-300">•</span>
                      <span className="text-slate-500 font-medium">{worker.completedJobs || 0} jobs</span>
                    </div>
                  </td>

                  <td className="px-6 py-4">
                    {worker.isVerified ? (
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold bg-emerald-50 text-emerald-600 border border-emerald-200/60">
                        <ShieldCheck className="w-3.5 h-3.5" />
                        CNIC Verified
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold bg-amber-50 text-amber-600 border border-amber-200/60">
                        <Clock className="w-3.5 h-3.5" />
                        Pending Review
                      </span>
                    )}
                  </td>

                  <td className="px-6 py-4 text-slate-400 text-[11px]">
                    {new Date(worker.createdAt).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })}
                  </td>

                  <td className="px-6 py-4 text-right">
                    <WorkerClientActions workerId={worker.uid} isVerified={worker.isVerified} />
                  </td>
                </tr>
              ))}

              {workers.length === 0 && (
                <tr>
                  <td colSpan={7} className="text-center py-12 text-slate-400">
                    No workers registered in the platform yet.
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
