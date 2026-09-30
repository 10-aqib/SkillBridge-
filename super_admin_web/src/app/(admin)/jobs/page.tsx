import { JobsService } from '@/lib/services/jobs.service';
import { JobsTableClient } from './JobsTableClient';
import { Briefcase, ArrowUpRight } from 'lucide-react';

export const dynamic = 'force-dynamic';

export default async function JobsPage() {
  const jobs = await JobsService.getJobs(100);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl lg:text-3xl font-extrabold text-slate-800 tracking-tight">
            Jobs & Contracts
          </h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Monitor real-time job postings, contract milestones, and worker bidding activity across Pakistan.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <div className="px-3.5 py-1.5 rounded-xl bg-white border border-[#E8EFF9] figma-card-shadow flex items-center gap-2 text-xs font-semibold text-slate-700">
            <span className="w-2 h-2 rounded-full bg-[#2F80ED] animate-pulse"></span>
            <span>Live Feed</span>
          </div>
        </div>
      </div>

      {/* Main Client Table with Filters & Stats */}
      <JobsTableClient initialJobs={jobs} />
    </div>
  );
}
