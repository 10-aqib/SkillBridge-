import React from 'react';
import { Star } from 'lucide-react';
import clsx from 'clsx';

interface StarRatingProps {
  rating: number;
  max?: number;
  size?: 'sm' | 'md' | 'lg';
  showValue?: boolean;
}

const StarRating: React.FC<StarRatingProps> = ({ rating, max = 5, size = 'md', showValue = false }) => {
  const sizeClass = { sm: 'w-3 h-3', md: 'w-4 h-4', lg: 'w-5 h-5' }[size];

  return (
    <div className="flex items-center gap-1">
      {Array.from({ length: max }).map((_, i) => (
        <Star
          key={i}
          className={clsx(sizeClass, i < Math.round(rating) ? 'text-yellow-400 fill-yellow-400' : 'text-gray-300')}
        />
      ))}
      {showValue && <span className="text-sm text-gray-600 ml-1">{rating.toFixed(1)}</span>}
    </div>
  );
};

export default StarRating;
