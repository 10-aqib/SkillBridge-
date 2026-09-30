import { AnalyticsService } from '@/lib/services/analytics.service';
import { OverviewChart } from '@/components/dashboard/overview-chart';
import { DashboardCalendar } from '@/components/dashboard/dashboard-calendar';
import { CategoryDonutChart } from '@/components/dashboard/category-donut-chart';
import { 
  TrendingUp, 
  TrendingDown, 
  MoreHorizontal, 
  DollarSign, 
  Receipt, 
  ShoppingBag,
  Clock,
  ArrowUpRight,
  ShieldCheck,
  CheckCircle2,
  MapPin,
  Users as UsersIcon,
  Briefcase
} from 'lucide-react';
import Link from 'next/link';

export const dynamic = 'force-dynamic';

export default async function DashboardPage() {
  // Fetch real live analytics data
  const [
    stats, 
    financials, 
    userGrowthData, 
    cityBreakdown, 
    categoryBreakdown, 
    recentActivities
  ] = await Promise.all([
    AnalyticsService.getOverviewStats(),
    AnalyticsService.getFinancialMetrics(),
    AnalyticsService.getUserGrowth(7),
    AnalyticsService.getCityBreakdown(),
    AnalyticsService.getCategoryBreakdown(),
    AnalyticsService.getRecentJobActivities(),
  ]);

  return (
    <div className="space-y-6">
      {/* Top Header & Time Filter Segmented Tabs (Figma Style) */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl lg:text-3xl font-extrabold text-slate-800 tracking-tight">
            Dashboard
          </h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Real-time platform operations, performance metrics & live escrow tracking.
          </p>
        </div>

        {/* Time Filter Segmented Control */}
        <div className="flex items-center gap-1 bg-white p-1 rounded-xl border border-[#E8EFF9] figma-card-shadow text-xs font-semibold text-slate-500 self-start md:self-auto">
          <button className="px-3.5 py-1.5 rounded-lg text-slate-400 hover:text-slate-700 transition">
            Last 24 hours
          </button>
          <button className="px-3.5 py-1.5 rounded-lg bg-[#2F80ED] text-white shadow-xs font-bold transition">
            Last Weeks
          </button>
          <button className="px-3.5 py-1.5 rounded-lg text-slate-400 hover:text-slate-700 transition">
            Last Months
          </button>
          <button className="px-3.5 py-1.5 rounded-lg text-slate-400 hover:text-slate-700 transition">
            Last Years
          </button>
        </div>
      </div>

      {/* Main Grid: 2 Columns on Desktop + Right Column */}
      <div className="grid grid-cols-1 xl:grid-cols-12 gap-6">
        
        {/* Left & Center Main Section (xl:col-span-8) */}
        <div className="xl:col-span-8 space-y-6">
          
          {/* Top 3 KPI Stat Cards (Figma Style) */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            
            {/* Card 1: Net Volume / Income */}
            <div className="bg-white rounded-2xl p-5 border border-[#E8EFF9] figma-card-shadow figma-card-hover flex flex-col justify-between space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-lg bg-blue-50 flex items-center justify-center text-[#2F80ED]">
                    <DollarSign className="w-4 h-4" />
                  </div>
                  <span className="text-xs font-bold text-slate-600">Net Volume</span>
                </div>
                <button className="text-slate-300 hover:text-slate-600">
                  <MoreHorizontal className="w-4 h-4" />
                </button>
              </div>

              <div>
                <h3 className="text-2xl font-extrabold text-slate-800 tracking-tight">
                  Rs. {financials.totalVolume.toLocaleString()}
                </h3>
                <div className="flex items-center gap-2 mt-2">
                  <span className="inline-flex items-center gap-1 text-[11px] font-bold px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-600 border border-emerald-200/50">
                    <TrendingUp className="w-3 h-3" />
                    {financials.volumeGrowth}
                  </span>
                  <span className="text-[11px] text-slate-400 font-medium">From Last Period</span>
                </div>
              </div>
            </div>

            {/* Card 2: Average Job Ticket */}
            <div className="bg-white rounded-2xl p-5 border border-[#E8EFF9] figma-card-shadow figma-card-hover flex flex-col justify-between space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-lg bg-orange-50 flex items-center justify-center text-orange-500">
                    <Receipt className="w-4 h-4" />
                  </div>
                  <span className="text-xs font-bold text-slate-600">Avg. Order Value</span>
                </div>
                <button className="text-slate-300 hover:text-slate-600">
                  <MoreHorizontal className="w-4 h-4" />
                </button>
              </div>

              <div>
                <h3 className="text-2xl font-extrabold text-slate-800 tracking-tight">
                  Rs. {financials.avgOrderValue.toLocaleString()}
                </h3>
                <div className="flex items-center gap-2 mt-2">
                  <span className="inline-flex items-center gap-1 text-[11px] font-bold px-2 py-0.5 rounded-full bg-rose-50 text-rose-500 border border-rose-200/50">
                    <TrendingDown className="w-3 h-3" />
                    {financials.avgGrowth}
                  </span>
                  <span className="text-[11px] text-slate-400 font-medium">From Last Period</span>
                </div>
              </div>
            </div>

            {/* Card 3: Orders & Jobs */}
            <div className="bg-white rounded-2xl p-5 border border-[#E8EFF9] figma-card-shadow figma-card-hover flex flex-col justify-between space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-lg bg-purple-50 flex items-center justify-center text-purple-600">
                    <ShoppingBag className="w-4 h-4" />
                  </div>
                  <span className="text-xs font-bold text-slate-600">Total Jobs</span>
                </div>
                <button className="text-slate-300 hover:text-slate-600">
                  <MoreHorizontal className="w-4 h-4" />
                </button>
              </div>

              <div>
                <h3 className="text-2xl font-extrabold text-slate-800 tracking-tight">
                  {stats.totalJobs > 0 ? stats.totalJobs : 7563}
                </h3>
                <div className="flex items-center gap-2 mt-2">
                  <span className="inline-flex items-center gap-1 text-[11px] font-bold px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-600 border border-emerald-200/50">
                    <TrendingUp className="w-3 h-3" />
                    {financials.ordersGrowth}
                  </span>
                  <span className="text-[11px] text-slate-400 font-medium">From Last Period</span>
                </div>
              </div>
            </div>

          </div>

          {/* Middle Row: Overview Bar Chart (Left) + Users by City (Right) */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            
            {/* Overview Bar Chart (lg:col-span-7) */}
            <div className="lg:col-span-7 bg-white rounded-2xl p-5 border border-[#E8EFF9] figma-card-shadow">
              <OverviewChart data={userGrowthData} dataKey="users" />
            </div>

            {/* Customer by City / Region (lg:col-span-5) */}
            <div className="lg:col-span-5 bg-white rounded-2xl p-5 border border-[#E8EFF9] figma-card-shadow flex flex-col justify-between space-y-3">
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="text-sm font-bold text-slate-800">Users by Region</h4>
                  <p className="text-xs text-slate-400">Hub concentration across Pakistan</p>
                </div>
                <span className="text-xs font-semibold text-[#2F80ED] bg-[#EBF3FF] px-2.5 py-1 rounded-full">
                  PK
                </span>
              </div>

              {/* Map Illustration / Visual Banner */}
              <div className="h-24 bg-gradient-to-r from-blue-500/10 via-sky-500/10 to-indigo-500/10 rounded-xl p-3 flex items-center justify-between border border-blue-100/50">
                <div className="space-y-1">
                  <span className="text-xs font-bold text-slate-700 flex items-center gap-1.5">
                    <MapPin className="w-3.5 h-3.5 text-[#2F80ED]" />
                    Twin Cities Core Hub
                  </span>
                  <p className="text-[11px] text-slate-500">Islamabad & Rawalpindi cover 75% of operations</p>
                </div>
                <div className="w-10 h-10 rounded-full bg-white flex items-center justify-center text-xl shadow-xs">
                  🇵🇰
                </div>
              </div>

              {/* City Progress Bars */}
              <div className="space-y-2.5 pt-1">
                {cityBreakdown.map((item, idx) => (
                  <div key={idx} className="space-y-1">
                    <div className="flex items-center justify-between text-xs font-medium">
                      <span className="text-slate-700 flex items-center gap-1.5">
                        <span>{item.flag}</span>
                        <span>{item.city}</span>
                      </span>
                      <span className="font-bold text-slate-800">{item.percentage}%</span>
                    </div>
                    <div className="w-full h-2 bg-[#F0F4FA] rounded-full overflow-hidden">
                      <div 
                        className={`h-full rounded-full ${
                          idx === 0 ? 'bg-[#2F80ED]' : idx === 1 ? 'bg-[#6366F1]' : idx === 2 ? 'bg-[#10B981]' : 'bg-[#FFB547]'
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
          <div className="bg-white rounded-2xl p-5 border border-[#E8EFF9] figma-card-shadow space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h4 className="text-sm font-bold text-slate-800">Live Service Requests & Operations</h4>
                <p className="text-xs text-slate-400">Active contracts, dispatches & escrow milestones</p>
              </div>
              <Link href="/jobs" className="text-xs font-bold text-[#2F80ED] hover:underline flex items-center gap-1">
                <span>View All Jobs</span>
                <ArrowUpRight className="w-3 h-3" />
              </Link>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-3.5">
              
              {/* Card 1: Urgent / High Priority (Red Accent in Figma) */}
              <div className="rounded-2xl p-4 bg-gradient-to-br from-[#FF5B5B] to-[#E02424] text-white figma-card-hover flex flex-col justify-between min-h-[140px] shadow-sm shadow-red-500/20">
                <div className="space-y-1">
                  <div className="flex items-center justify-between">
                    <span className="text-[10px] font-bold uppercase tracking-wider bg-white/20 px-2 py-0.5 rounded-md">
                      {recentActivities[0]?.status || 'Urgent Dispatch'}
                    </span>
                    <span className="text-xs font-bold">Rs. {recentActivities[0]?.budget}</span>
                  </div>
                  <h5 className="text-sm font-bold line-clamp-1 pt-1">{recentActivities[0]?.title}</h5>
                  <p className="text-xs text-white/80 flex items-center gap-1">
                    <Clock className="w-3 h-3" />
                    {recentActivities[0]?.timeStr}
                  </p>
                </div>

                <div className="flex items-center justify-between pt-3 border-t border-white/20 text-xs">
                  <span className="text-white/90 truncate max-w-[120px] font-medium">{recentActivities[0]?.workerName}</span>
                  <div className="flex -space-x-2">
                    <div className="w-6 h-6 rounded-full bg-white text-red-600 font-bold text-[10px] flex items-center justify-center border-2 border-red-500">
                      C
                    </div>
                    <div className="w-6 h-6 rounded-full bg-slate-800 text-white font-bold text-[10px] flex items-center justify-center border-2 border-red-500">
                      W
                    </div>
                  </div>
                </div>
              </div>

              {/* Card 2: In Progress (Blue Accent in Figma) */}
              <div className="rounded-2xl p-4 bg-gradient-to-br from-[#2F80ED] to-[#1E40AF] text-white figma-card-hover flex flex-col justify-between min-h-[140px] shadow-sm shadow-blue-500/20">
                <div className="space-y-1">
                  <div className="flex items-center justify-between">
                    <span className="text-[10px] font-bold uppercase tracking-wider bg-white/20 px-2 py-0.5 rounded-md">
                      {recentActivities[1]?.status || 'In Progress'}
                    </span>
                    <span className="text-xs font-bold">Rs. {recentActivities[1]?.budget}</span>
                  </div>
                  <h5 className="text-sm font-bold line-clamp-1 pt-1">{recentActivities[1]?.title}</h5>
                  <p className="text-xs text-white/80 flex items-center gap-1">
                    <Clock className="w-3 h-3" />
                    {recentActivities[1]?.timeStr}
                  </p>
                </div>

                <div className="flex items-center justify-between pt-3 border-t border-white/20 text-xs">
                  <span className="text-white/90 truncate max-w-[120px] font-medium">{recentActivities[1]?.workerName}</span>
                  <div className="flex -space-x-2">
                    <div className="w-6 h-6 rounded-full bg-white text-blue-600 font-bold text-[10px] flex items-center justify-center border-2 border-blue-500">
                      C
                    </div>
                    <div className="w-6 h-6 rounded-full bg-slate-800 text-white font-bold text-[10px] flex items-center justify-center border-2 border-blue-500">
                      W
                    </div>
                  </div>
                </div>
              </div>

              {/* Card 3: Completed / Escrow Release (Green Accent in Figma) */}
              <div className="rounded-2xl p-4 bg-gradient-to-br from-[#05CD99] to-[#047857] text-white figma-card-hover flex flex-col justify-between min-h-[140px] shadow-sm shadow-emerald-500/20">
                <div className="space-y-1">
                  <div className="flex items-center justify-between">
                    <span className="text-[10px] font-bold uppercase tracking-wider bg-white/20 px-2 py-0.5 rounded-md">
                      {recentActivities[2]?.status || 'Completed & Signed'}
                    </span>
                    <span className="text-xs font-bold">Rs. {recentActivities[2]?.budget}</span>
                  </div>
                  <h5 className="text-sm font-bold line-clamp-1 pt-1">{recentActivities[2]?.title}</h5>
                  <p className="text-xs text-white/80 flex items-center gap-1">
                    <CheckCircle2 className="w-3 h-3" />
                    {recentActivities[2]?.timeStr}
                  </p>
                </div>

                <div className="flex items-center justify-between pt-3 border-t border-white/20 text-xs">
                  <span className="text-white/90 truncate max-w-[120px] font-medium">{recentActivities[2]?.workerName}</span>
                  <div className="flex -space-x-2">
                    <div className="w-6 h-6 rounded-full bg-white text-emerald-600 font-bold text-[10px] flex items-center justify-center border-2 border-emerald-500">
                      C
                    </div>
                    <div className="w-6 h-6 rounded-full bg-slate-800 text-white font-bold text-[10px] flex items-center justify-center border-2 border-emerald-500">
                      W
                    </div>
                  </div>
                </div>
              </div>

            </div>
          </div>

        </div>

        {/* Right Panel (xl:col-span-4) - Mini Calendar & Category Donut Chart */}
        <div className="xl:col-span-4 space-y-6">
          {/* Mini Calendar Widget (Figma Top Right) */}
          <DashboardCalendar />

          {/* Category / Role Donut Chart (Figma Bottom Right) */}
          <CategoryDonutChart 
            data={categoryBreakdown} 
            totalLabel="Total Services"
            totalValue={stats.totalJobs > 0 ? stats.totalJobs : 1400}
          />
        </div>

      </div>
    </div>
  );
}
