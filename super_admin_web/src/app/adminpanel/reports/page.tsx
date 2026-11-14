import { ReportsClient } from './ReportsClient';
import { ReportsService } from '@/lib/services/reports.service';

export const dynamic = 'force-dynamic';

export default async function ReportsPage() {
  const reports = await ReportsService.getReports();

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl lg:text-3xl font-extrabold text-sb-text tracking-tight">
            Reports & Moderation
          </h1>
          <p className="text-xs text-sb-text-secondary mt-0.5">
            Resolve customer disputes, oversee worker conduct complaints, and safeguard platform trust.
          </p>
        </div>

      </div>

      {/* Interactive Reports Table & Inspection */}
      <ReportsClient initialReports={reports} />
    </div>
  );
}
