import { AnalyticsService } from '@/lib/services/analytics.service';
import { OverviewChart } from '@/components/dashboard/overview-chart';
import { ModerationSummary } from '@/components/dashboard/moderation-summary';
import { CategoryDonutChart } from '@/components/dashboard/category-donut-chart';
import { 
  DollarSign, 
  Receipt, 
  ShoppingBag,
  Clock,
  ArrowUpRight,
  MapPin,
} from 'lucide-react';
import Link from 'next/link';

export const dynamic = 'force-dynamic';

const ranges = {
  '24h': { days: 1, label: 'Last 24 hours' },
  '7d': { days: 7, label: 'Last 7 days' },
  '30d': { days: 30, label: 'Last 30 days' },
  '365d': { days: 365, label: 'Last 12 months' },
} as const;

export default async function DashboardPage({
  searchParams,
}: {
  searchParams: Promise<{ range?: string }>;
}) {
  const params = await searchParams;
  const selectedRange = params.range && params.range in ranges ? params.range as keyof typeof ranges : '7d';
  const range = ranges[selectedRange];

  const [
    stats, 
    financials, 
    userGrowthData, 
    cityBreakdown, 
    categoryBreakdown, 
    recentActivities
  ] = await Promise.all([
    AnalyticsService.getOverviewStats(),
    AnalyticsService.getFinancialMetrics(range.days),
    AnalyticsService.getUserGrowth(range.days),
    AnalyticsService.getCityBreakdown(),
    AnalyticsService.getCategoryBreakdown(),
    AnalyticsService.getRecentJobActivities(),
  ]);

  return (
    <div className="space-y-6">
      {/* Top Header & Time Filter Segmented Tabs (Figma Style) */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl lg:text-3xl font-extrabold text-sb-text tracking-tight">
            Dashboard
          </h1>
          <p className="text-xs text-sb-text-secondary mt-0.5">
            Platform operations and completed-contract metrics from Firestore.
          </p>
        </div>

        {/* Time range controls update the server-side Firestore queries. */}
        <div className="flex items-center gap-1 bg-sb-surface p-1 rounded-xl border border-sb-border figma-card-shadow text-xs font-semibold text-sb-text-secondary self-start md:self-auto">
          {(Object.entries(ranges) as [keyof typeof ranges, typeof ranges[keyof typeof ranges]][]).map(([key, item]) => (
            <Link
              key={key}
              href={`/adminpanel/dashboard?range=${key}`}
              aria-current={selectedRange === key ? 'page' : undefined}
              className={`rounded-lg px-2.5 py-1.5 transition sm:px-3.5 ${selectedRange === key ? 'bg-sb-primary font-bold text-sb-on-primary shadow-xs' : 'text-sb-text-secondary hover:text-sb-text'}`}
            >
              {item.label}
            </Link>
          ))}
        </div>
      </div>

      {/* Main Grid: 2 Columns on Desktop + Right Column */}
      <div className="grid grid-cols-1 xl:grid-cols-12 gap-6">
        
        {/* Left & Center Main Section (xl:col-span-8) */}
        <div className="xl:col-span-8 space-y-6">
          
          {/* Top 3 KPI Stat Cards (Figma Style) */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            
            {/* Period-filtered completed contract value */}
            <div className="bg-sb-surface rounded-2xl p-5 border border-sb-border figma-card-shadow figma-card-hover flex flex-col justify-between space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-lg bg-sb-primary-subtle flex items-center justify-center text-sb-primary">
                    <DollarSign className="w-4 h-4" />
                  </div>
                  <span className="text-xs font-bold text-sb-text-secondary">Contract Value · {range.label}</span>
                </div>
              </div>

              <div>
                <h3 className="text-2xl font-extrabold text-sb-text tracking-tight">
                  Rs. {financials.totalVolume.toLocaleString()}
                </h3>
                <p className="text-[11px] text-sb-text-secondary font-medium mt-2">Completed in this period</p>
              </div>
            </div>

            {/* Card 2: Average Job Ticket */}
            <div className="bg-sb-surface rounded-2xl p-5 border border-sb-border figma-card-shadow figma-card-hover flex flex-col justify-between space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-lg bg-sb-warning-subtle flex items-center justify-center text-sb-on-warning-subtle">
                    <Receipt className="w-4 h-4" />
                  </div>
                  <span className="text-xs font-bold text-sb-text-secondary">Average Contract · {range.label}</span>
                </div>
              </div>

              <div>
                <h3 className="text-2xl font-extrabold text-sb-text tracking-tight">
                  Rs. {financials.avgOrderValue.toLocaleString()}
                </h3>
                <p className="text-[11px] text-sb-text-secondary font-medium mt-2">Completed contract average</p>
              </div>
            </div>

            {/* Card 3: Orders & Jobs */}
            <div className="bg-sb-surface rounded-2xl p-5 border border-sb-border figma-card-shadow figma-card-hover flex flex-col justify-between space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-lg bg-sb-primary-subtle flex items-center justify-center text-sb-on-primary-subtle">
                    <ShoppingBag className="w-4 h-4" />
                  </div>
                  <span className="text-xs font-bold text-sb-text-secondary">Total Jobs</span>
                </div>
              </div>

              <div>
                <h3 className="text-2xl font-extrabold text-sb-text tracking-tight">
                  {stats.totalJobs}
                </h3>
                <p className="text-[11px] text-sb-text-secondary font-medium mt-2">All recorded jobs</p>
              </div>
            </div>

          </div>

          {/* Middle Row: Overview Bar Chart (Left) + Users by City (Right) */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            
            {/* Overview Bar Chart (lg:col-span-7) */}
            <div className="lg:col-span-7 bg-sb-surface rounded-2xl p-5 border border-sb-border figma-card-shadow">
              <OverviewChart data={userGrowthData} dataKey="users" rangeLabel={range.label} />
            </div>

            {/* Customer by City / Region (lg:col-span-5) */}
            <div className="lg:col-span-5 bg-sb-surface rounded-2xl p-5 border border-sb-border figma-card-shadow flex flex-col justify-between space-y-3">
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="text-sm font-bold text-sb-text">Users by Region</h4>
                  <p className="text-xs text-sb-text-secondary">Hub concentration across Pakistan</p>
                </div>
                <span className="text-xs font-semibold text-sb-primary bg-sb-primary-subtle px-2.5 py-1 rounded-full">
                  PK
                </span>
              </div>

              {/* Map Illustration / Visual Banner */}
              <div className="h-24 bg-gradient-to-r from-sb-primary/10 via-sb-primary/10 to-sb-primary/10 rounded-xl p-3 flex items-center justify-between border border-sb-border/50">
                <div className="space-y-1">
                  <span className="text-xs font-bold text-sb-text flex items-center gap-1.5">
                    <MapPin className="w-3.5 h-3.5 text-sb-primary" />
                    Top City by User Count
                  </span>
                  <p className="text-[11px] text-sb-text-secondary">
                    {cityBreakdown[0]
                      ? `${cityBreakdown[0].city} has ${cityBreakdown[0].percentage}% of users`
                      : 'No region data yet.'}
                  </p>
                </div>
                <div className="w-10 h-10 rounded-full bg-sb-surface flex items-center justify-center text-xl shadow-xs">
                  <MapPin className="w-5 h-5 text-sb-primary" />
                </div>
              </div>

              {/* City Progress Bars */}
              <div className="space-y-2.5 pt-1">
                {cityBreakdown.length === 0 ? (
                  <p className="text-sm text-sb-text-secondary">No city data available.</p>
                ) : cityBreakdown.map((item, idx) => (
                  <div key={idx} className="space-y-1">
                    <div className="flex items-center justify-between text-xs font-medium">
                      <span className="text-sb-text flex items-center gap-1.5">
                        <span>{item.city}</span>
                      </span>
                      <span className="font-bold text-sb-text">{item.percentage}%</span>
                    </div>
                    <div className="w-full h-2 bg-sb-surface-sunken rounded-full overflow-hidden">
                      <div 
                        className={`h-full rounded-full ${
                          idx === 0 ? 'bg-sb-primary' : idx === 1 ? 'bg-sb-chart-5' : idx === 2 ? 'bg-sb-success' : 'bg-sb-accent'
                        }`}
                        style={{ width: `${item.percentage}%` }}
                      ></div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

          </div>

          {/* Bottom Row: Live Operation & Job Cards (Red, Blue, Green in Figma) */}
          <div className="bg-sb-surface rounded-2xl p-5 border border-sb-border figma-card-shadow space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h4 className="text-sm font-bold text-sb-text">Recent Service Requests</h4>
                <p className="text-xs text-sb-text-secondary">Latest job records from Firestore</p>
              </div>
              <Link href="/adminpanel/jobs" className="text-xs font-bold text-sb-primary hover:underline flex items-center gap-1">
                <span>View All Jobs</span>
                <ArrowUpRight className="w-3 h-3" />
              </Link>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-3.5">
              
              {recentActivities.length === 0 ? (
                <p className="col-span-full rounded-xl border border-dashed border-sb-border px-4 py-8 text-center text-sm text-sb-text-secondary">
                  No service requests have been recorded yet.
                </p>
              ) : recentActivities.map((activity) => (
                <article key={activity.id} className="rounded-2xl p-4 bg-sb-canvas border border-sb-border flex flex-col justify-between min-h-[140px]">
                  <div className="space-y-2">
                    <div className="flex items-start justify-between gap-2">
                      <span className="text-[10px] font-bold uppercase tracking-wider bg-sb-surface px-2 py-1 rounded-md text-sb-text-secondary">
                        {activity.status}
                      </span>
                      {activity.budget !== null && (
                        <span className="text-xs font-bold text-sb-text">Rs. {activity.budget.toLocaleString()}</span>
                      )}
                    </div>
                    <h5 className="text-sm font-bold line-clamp-2 text-sb-text">{activity.title}</h5>
                    <p className="text-xs text-sb-text-secondary flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      {activity.timeStr}
                    </p>
                  </div>
                  <div className="flex items-center justify-between gap-2 pt-3 mt-3 border-t border-sb-border text-xs">
                    <span className="truncate text-sb-text-secondary">{activity.clientName}</span>
                    <span className="truncate text-sb-text-secondary">{activity.workerName}</span>
                  </div>
                </article>
              ))}
            </div>
          </div>

        </div>

        {/* Right Panel (xl:col-span-4) - Mini Calendar & Category Donut Chart */}
        <div className="xl:col-span-4 space-y-6">
          <ModerationSummary />

          {/* Category / Role Donut Chart (Figma Bottom Right) */}
          <CategoryDonutChart 
            data={categoryBreakdown} 
            totalLabel="Total Jobs"
            totalValue={stats.totalJobs}
          />
        </div>

      </div>
    </div>
  );
}
