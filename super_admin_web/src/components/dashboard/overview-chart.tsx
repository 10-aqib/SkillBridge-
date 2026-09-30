'use client';

import { Bar, BarChart, ResponsiveContainer, XAxis, YAxis, Tooltip, CartesianGrid, Cell } from 'recharts';

interface ChartProps {
  data: { date: string; users?: number; jobs?: number }[];
  dataKey: string;
}

export function OverviewChart({ data, dataKey }: ChartProps) {
  // Find index of maximum item to highlight with purple like in Figma
  let maxIndex = 0;
  let maxVal = -1;
  data.forEach((item: any, idx) => {
    const val = item[dataKey] || 0;
    if (val > maxVal) {
      maxVal = val;
      maxIndex = idx;
    }
  });

  return (
    <div className="w-full h-full flex flex-col">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h4 className="text-sm font-bold text-slate-800">Activity Overview</h4>
          <p className="text-xs text-slate-400">Daily registrations & service requests</p>
        </div>
        <div className="flex items-center gap-1.5 bg-[#F4F7FE] p-1 rounded-xl text-xs font-semibold text-slate-600">
          <span className="px-3 py-1 rounded-lg bg-white text-[#2F80ED] shadow-xs">This Week</span>
          <span className="px-3 py-1 rounded-lg text-slate-400 hover:text-slate-600 cursor-pointer">Last Week</span>
        </div>
      </div>

      <div className="flex-1 w-full min-h-[220px]">
        <ResponsiveContainer width="100%" height={230}>
          <BarChart data={data} barGap={8} barCategoryGap="25%">
            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F0F4FA" />
            <XAxis
              dataKey="date"
              stroke="#94A3B8"
              fontSize={12}
              tickLine={false}
              axisLine={false}
              dy={6}
            />
            <YAxis
              stroke="#94A3B8"
              fontSize={12}
              tickLine={false}
              axisLine={false}
              allowDecimals={false}
              dx={-6}
            />
            <Tooltip 
              cursor={{ fill: 'rgba(235, 243, 255, 0.5)', radius: 8 }}
              contentStyle={{
                backgroundColor: '#1E293B',
                borderRadius: '10px',
                border: 'none',
                color: '#fff',
                fontSize: '12px',
                padding: '8px 12px',
                boxShadow: '0 4px 20px rgba(0,0,0,0.15)'
              }}
              formatter={(value: any) => [`${value} Activity`, 'Count']}
            />
            <Bar 
              dataKey={dataKey} 
              radius={[8, 8, 0, 0]}
              maxBarSize={38}
            >
              {data.map((_, index) => (
                <Cell 
                  key={`cell-${index}`} 
                  fill={index === maxIndex ? '#6366F1' : '#3874FF'} 
                  className="transition-colors duration-150 hover:opacity-80"
                />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
