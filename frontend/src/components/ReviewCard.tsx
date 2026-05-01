import React from 'react';
import StarRating from './StarRating';
import type { Review } from '../types';
import { formatDistanceToNow } from 'date-fns';

interface ReviewCardProps {
  review: Review;
}

const ReviewCard: React.FC<ReviewCardProps> = ({ review }) => {
  return (
    <div className="bg-white rounded-xl border border-gray-100 p-5 shadow-sm">
      <div className="flex items-start gap-3 mb-3">
        {review.reviewer_avatar ? (
          <img
            src={review.reviewer_avatar}
            alt={review.reviewer_name}
            className="w-10 h-10 rounded-full object-cover"
          />
        ) : (
          <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0">
            <span className="text-blue-600 font-semibold text-sm">
              {(review.reviewer_name || 'A').charAt(0).toUpperCase()}
            </span>
          </div>
        )}
        <div className="flex-1">
          <p className="font-medium text-gray-900">{review.reviewer_name || 'Anonymous'}</p>
          <div className="flex items-center gap-2">
            <StarRating rating={review.rating} size="sm" />
            <span className="text-xs text-gray-400">
              {formatDistanceToNow(new Date(review.created_at), { addSuffix: true })}
            </span>
          </div>
        </div>
      </div>
      {review.comment && (
        <p className="text-gray-600 text-sm leading-relaxed">{review.comment}</p>
      )}
    </div>
  );
};

export default ReviewCard;
