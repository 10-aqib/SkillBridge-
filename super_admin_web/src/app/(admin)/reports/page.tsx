import { ReportsClient } from './ReportsClient';

export const dynamic = 'force-dynamic';

export default function ReportsPage() {
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl lg:text-3xl font-extrabold text-slate-800 tracking-tight">
            Reports & Moderation
          </h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Resolve customer disputes, oversee worker conduct complaints, and safeguard platform trust.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <div className="px-3.5 py-1.5 rounded-xl bg-white border border-[#E8EFF9] figma-card-shadow flex items-center gap-2 text-xs font-semibold text-slate-700">
            <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
            <span>Support Shield Active</span>
          </div>
        </div>
      </div>

      {/* Interactive Reports Table & Inspection */}
      <ReportsClient />
    </div>
  );
}
