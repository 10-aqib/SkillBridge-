import { NextRequest, NextResponse } from 'next/server';
import { getAdminRequestIdentity } from '@/lib/auth/admin-session';
import { AnalyticsService } from '@/lib/services/analytics.service';

function csvCell(value: string | number): string {
  let safe = String(value);
  if (/^[=+\-@\t\r]/.test(safe)) safe = `'${safe}`;
  return `"${safe.replaceAll('"', '""')}"`;
}

export async function GET(request: NextRequest) {
  const admin = await getAdminRequestIdentity(request);
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  try {
    const [stats, financials] = await Promise.all([
      AnalyticsService.getOverviewStats(),
      AnalyticsService.getFinancialMetrics(365),
    ]);
    const rows = [
      ['Metric', 'Value'],
      ['Exported at', new Date().toISOString()],
      ['Exported by', admin.email || admin.uid],
      ['Registered users', stats.totalUsers],
      ['Workers', stats.totalWorkers],
      ['Clients', stats.totalCustomers],
      ['Total jobs', stats.totalJobs],
      ['Active jobs', stats.activeJobs],
      ['Completed jobs', stats.completedJobs],
      ['Completed contract value, last 12 months (PKR)', financials.totalVolume],
      ['Average completed contract, last 12 months (PKR)', financials.avgOrderValue],
    ];
    const csv = rows.map((row) => row.map(csvCell).join(',')).join('\r\n');

    return new NextResponse(csv, {
      headers: {
        'Content-Type': 'text/csv; charset=utf-8',
        'Content-Disposition': 'attachment; filename="skillbridge-admin-summary.csv"',
        'Cache-Control': 'no-store',
      },
    });
  } catch (error) {
    console.error('Admin summary export failed:', error);
    return NextResponse.json({ error: 'Could not create the summary export' }, { status: 500 });
  }
}
