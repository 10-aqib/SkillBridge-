'use client';

import { Bar, BarChart, ResponsiveContainer, XAxis, YAxis, Tooltip, CartesianGrid, Cell } from 'recharts';

interface ChartProps {
  data: { date: string; users?: number; jobs?: number }[];
  dataKey: 'users' | 'jobs';
  rangeLabel: string;
}

export function OverviewChart({ data, dataKey, rangeLabel }: ChartProps) {
  // Find index of maximum item to highlight with purple like in Figma
  let maxIndex = 0;
  let maxVal = -1;
  data.forEach((item, idx) => {
    const val = item[dataKey] ?? 0;
    if (val > maxVal) {
      maxVal = val;
      maxIndex = idx;
    }
  });

  return (
    <div className="w-full h-full flex flex-col">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h4 className="text-sm font-bold text-sb-text">Activity Overview</h4>
          <p className="text-xs text-sb-text-secondary">User registrations · {rangeLabel}</p>
        </div>
        <span className="rounded-lg bg-sb-canvas px-3 py-1.5 text-xs font-semibold text-sb-text-secondary">{rangeLabel}</span>
      </div>

      {data.length === 0 ? (
        <div className="flex-1 w-full min-h-[220px] flex items-center justify-center text-sm text-sb-text-secondary">
          No activity data available.
        </div>
      ) : <div className="flex-1 w-full min-h-[220px]">
        <ResponsiveContainer width="100%" height={230}>
          <BarChart data={data} barGap={8} barCategoryGap="25%">
            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="var(--sb-border)" />
            <XAxis
              dataKey="date"
              stroke="var(--sb-text-secondary)"
              fontSize={12}
              tickLine={false}
              axisLine={false}
              dy={6}
            />
            <YAxis
              stroke="var(--sb-text-secondary)"
              fontSize={12}
              tickLine={false}
              axisLine={false}
              allowDecimals={false}
              dx={-6}
            />
            <Tooltip 
              cursor={{ fill: 'var(--sb-primary-subtle)', radius: 8 }}
              contentStyle={{
                backgroundColor: 'var(--sb-surface-raised)',
                borderRadius: '10px',
                border: '1px solid var(--sb-border)',
                color: 'var(--sb-text)',
                fontSize: '12px',
                padding: '8px 12px',
                boxShadow: 'var(--sb-shadow-overlay)'
              }}
              formatter={(value) => [`${value} Activity`, 'Count']}
            />
            <Bar 
              dataKey={dataKey} 
              radius={[8, 8, 0, 0]}
              maxBarSize={38}
            >
              {data.map((_, index) => (
                <Cell 
                  key={`cell-${index}`} 
                  fill={index === maxIndex ? 'var(--sb-chart-3)' : 'var(--sb-chart-1)'} 
                  className="transition-colors duration-150 hover:opacity-80"
                />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>}
    </div>
  );
}
