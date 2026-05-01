import React from 'react';
import type { LucideIcon } from 'lucide-react';
import clsx from 'clsx';

interface StatCardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  color?: string;
  subtitle?: string;
}

const StatCard: React.FC<StatCardProps> = ({ title, value, icon: Icon, color = 'bg-blue-500', subtitle }) => {
  return (
    <div className="bg-white rounded-2xl border border-gray-100 p-6 shadow-sm">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm text-gray-500 font-medium">{title}</p>
          <p className="text-3xl font-bold text-gray-900 mt-1">{value}</p>
          {subtitle && <p className="text-xs text-gray-400 mt-1">{subtitle}</p>}
        </div>
        <div className={clsx('w-12 h-12 rounded-xl flex items-center justify-center text-white', color)}>
          <Icon className="w-6 h-6" />
        </div>
      </div>
    </div>
  );
};

export default StatCard;
