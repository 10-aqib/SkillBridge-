import React from 'react';
import type { LucideIcon } from 'lucide-react';
import clsx from 'clsx';

interface CategoryCardProps {
  title: string;
  icon: LucideIcon;
  count?: number;
  color?: string;
  onClick?: () => void;
}

const CategoryCard: React.FC<CategoryCardProps> = ({ title, icon: Icon, count, color = 'bg-blue-500', onClick }) => {
  return (
    <button
      onClick={onClick}
      className="flex flex-col items-center gap-3 p-6 bg-white rounded-2xl shadow-sm border border-gray-100 hover:shadow-md hover:border-blue-200 transition-all duration-200 w-full group"
    >
      <div className={clsx('w-14 h-14 rounded-2xl flex items-center justify-center text-white transition-transform group-hover:scale-110', color)}>
        <Icon className="w-7 h-7" />
      </div>
      <div className="text-center">
        <p className="font-semibold text-gray-800">{title}</p>
        {count !== undefined && (
          <p className="text-xs text-gray-400 mt-0.5">{count}+ workers</p>
        )}
      </div>
    </button>
  );
};

export default CategoryCard;
