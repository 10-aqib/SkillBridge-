'use client';

import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from 'recharts';
import { CategoryMetric } from '@/lib/services/analytics.service';

interface DonutProps {
  data: CategoryMetric[];
  totalLabel?: string;
  totalValue?: number | string;
}

export function CategoryDonutChart({ data, totalLabel = 'Total Services', totalValue = 0 }: DonutProps) {
  const chartData = data ?? [];

  const total = chartData.reduce((acc, curr) => acc + curr.value, 0);

  return (
    <div className="bg-sb-surface rounded-2xl p-5 border border-sb-border figma-card-shadow flex flex-col space-y-3">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <span className="text-xs font-semibold text-sb-text-secondary uppercase tracking-wider">{totalLabel}</span>
          <h4 className="text-base font-bold text-sb-text">{totalValue}</h4>
        </div>
        <span className="text-xs font-semibold text-sb-primary bg-sb-primary-subtle px-2.5 py-1 rounded-full">
          Firestore
        </span>
      </div>

      {/* Donut Chart Container */}
      <div className="h-44 w-full relative flex items-center justify-center">
        {chartData.length === 0 ? (
          <p className="text-sm text-sb-text-secondary">No service category data yet.</p>
        ) : <ResponsiveContainer width="100%" height="100%">
          <PieChart>
            <Tooltip 
              contentStyle={{
                backgroundColor: 'var(--sb-surface-raised)',
                borderRadius: '8px',
                border: '1px solid var(--sb-border)',
                color: 'var(--sb-text)',
                fontSize: '12px'
              }}
              formatter={(value, name) => [`${value} jobs (${Math.round((Number(value) / total) * 100)}%)`, name]}
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
        </ResponsiveContainer>}

        {/* Center Label */}
        <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
          <span className="text-xs font-bold text-sb-text">{total}</span>
          <span className="text-[10px] text-sb-text-secondary">Total</span>
        </div>
      </div>

      {/* Legend with Color Dots */}
      <div className="grid grid-cols-2 gap-2 pt-2 border-t border-sb-border text-xs">
        {chartData.map((item, index) => {
          const pct = Math.round((item.value / total) * 100);
          return (
            <div key={index} className="flex items-center justify-between text-sb-text-secondary">
              <div className="flex items-center gap-1.5 truncate">
                <span className="w-2.5 h-2.5 rounded-full shrink-0" style={{ backgroundColor: item.color }} />
                <span className="truncate text-sb-text font-medium">{item.name}</span>
              </div>
              <span className="text-sb-text-secondary font-semibold pl-1">{pct}%</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
