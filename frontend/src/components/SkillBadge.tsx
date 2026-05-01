import React from 'react';
import clsx from 'clsx';

interface SkillBadgeProps {
  skill: string;
  variant?: 'blue' | 'orange' | 'green' | 'purple' | 'gray';
  size?: 'sm' | 'md';
}

const colors = {
  blue: 'bg-blue-100 text-blue-700',
  orange: 'bg-orange-100 text-orange-700',
  green: 'bg-green-100 text-green-700',
  purple: 'bg-purple-100 text-purple-700',
  gray: 'bg-gray-100 text-gray-700',
};

const SkillBadge: React.FC<SkillBadgeProps> = ({ skill, variant = 'blue', size = 'md' }) => {
  return (
    <span
      className={clsx(
        'inline-flex items-center rounded-full font-medium',
        colors[variant],
        size === 'sm' ? 'px-2 py-0.5 text-xs' : 'px-3 py-1 text-sm'
      )}
    >
      {skill}
    </span>
  );
};

export default SkillBadge;
