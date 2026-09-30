'use client';

import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from 'recharts';
import { CategoryMetric } from '@/lib/services/analytics.service';

interface DonutProps {
  data: CategoryMetric[];
  totalLabel?: string;
  totalValue?: number | string;
}

export function CategoryDonutChart({ data, totalLabel = 'Total Services', totalValue = 1400 }: DonutProps) {
  const chartData = data && data.length > 0 ? data : [
    { name: 'Electrician', value: 35, color: '#2F80ED' },
    { name: 'Plumber', value: 25, color: '#FFB547' },
    { name: 'AC Repair', value: 20, color: '#05CD99' },
    { name: 'Cleaning', value: 20, color: '#7551FF' },
  ];

  const total = chartData.reduce((acc, curr) => acc + curr.value, 0);

  return (
    <div className="bg-white rounded-2xl p-5 border border-[#E8EFF9] figma-card-shadow flex flex-col space-y-3">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">{totalLabel}</span>
          <h4 className="text-base font-bold text-slate-800">{totalValue}</h4>
        </div>
        <span className="text-xs font-semibold text-[#2F80ED] bg-[#EBF3FF] px-2.5 py-1 rounded-full">
          Live
        </span>
      </div>

      {/* Donut Chart Container */}
      <div className="h-44 w-full relative flex items-center justify-center">
        <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Tooltip 
              contentStyle={{
                backgroundColor: '#1E293B',
                borderRadius: '8px',
                border: 'none',
                color: '#fff',
                fontSize: '12px'
              }}
              formatter={(value: any, name: any) => [`${value} jobs (${Math.round((value / total) * 100)}%)`, name]}
            />
            <Pie
              data={chartData}
              innerRadius={48}
              outerRadius={68}
              paddingAngle={4}
              dataKey="value"
            >
              {chartData.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={entry.color} strokeWidth={0} />
              ))}
            </Pie>
          </PieChart>
        </ResponsiveContainer>

        {/* Center Label */}
        <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
          <span className="text-xs font-bold text-slate-700">{total}</span>
          <span className="text-[10px] text-slate-400">Total</span>
        </div>
      </div>

      {/* Legend with Color Dots */}
      <div className="grid grid-cols-2 gap-2 pt-2 border-t border-[#F0F4FA] text-xs">
        {chartData.map((item, index) => {
          const pct = Math.round((item.value / total) * 100);
          return (
            <div key={index} className="flex items-center justify-between text-slate-600">
              <div className="flex items-center gap-1.5 truncate">
                <span className="w-2.5 h-2.5 rounded-full shrink-0" style={{ backgroundColor: item.color }} />
                <span className="truncate text-slate-700 font-medium">{item.name}</span>
              </div>
              <span className="text-slate-400 font-semibold pl-1">{pct}%</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
