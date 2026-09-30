import { SettingsClient } from './SettingsClient';

export const dynamic = 'force-dynamic';

export default function SettingsPage() {
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl lg:text-3xl font-extrabold text-slate-800 tracking-tight">
            Platform Settings & Governance
          </h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Configure platform commission rules, service coverage areas, and administrative security parameters.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <div className="px-3.5 py-1.5 rounded-xl bg-white border border-[#E8EFF9] figma-card-shadow flex items-center gap-2 text-xs font-semibold text-slate-700">
            <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
            <span>Config Active</span>
          </div>
        </div>
      </div>

      {/* Settings Client Component */}
      <SettingsClient />
    </div>
  );
}
