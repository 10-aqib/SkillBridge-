import React from 'react';
import { Link } from 'react-router-dom';
import { MapPin, Clock, DollarSign, Tag } from 'lucide-react';
import type { Job } from '../types';
import { formatDistanceToNow } from 'date-fns';
import clsx from 'clsx';

interface JobCardProps {
  job: Job;
}

const statusColors: Record<string, string> = {
  open: 'bg-green-100 text-green-700',
  'in-progress': 'bg-blue-100 text-blue-700',
  completed: 'bg-gray-100 text-gray-600',
  cancelled: 'bg-red-100 text-red-600',
};

const JobCard: React.FC<JobCardProps> = ({ job }) => {
  return (
    <Link to={`/jobs/${job.id}`} className="block">
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 hover:shadow-md hover:border-blue-200 transition-all duration-200">
        <div className="flex items-start justify-between gap-2 mb-3">
          <h3 className="font-semibold text-gray-900 text-lg leading-tight">{job.title}</h3>
          <span className={clsx('text-xs px-2 py-1 rounded-full font-medium flex-shrink-0', statusColors[job.status])}>
            {job.status.replace('-', ' ')}
          </span>
        </div>

        <p className="text-gray-500 text-sm line-clamp-2 mb-4">{job.description}</p>

        <div className="flex flex-wrap gap-3 text-sm text-gray-500 mb-4">
          <div className="flex items-center gap-1">
            <Tag className="w-3.5 h-3.5 text-blue-500" />
            <span className="text-blue-600 font-medium">{job.category}</span>
          </div>
          <div className="flex items-center gap-1">
            <MapPin className="w-3.5 h-3.5" />
            <span>{job.location}</span>
          </div>
          <div className="flex items-center gap-1">
            <Clock className="w-3.5 h-3.5" />
            <span className="capitalize">{job.job_type.replace('-', ' ')}</span>
          </div>
        </div>

        <div className="flex items-center justify-between">
          {(job.budget_min || job.budget_max) ? (
            <div className="flex items-center gap-1 text-green-600 font-medium">
              <DollarSign className="w-4 h-4" />
              {job.budget_min && job.budget_max
                ? `$${job.budget_min} - $${job.budget_max}`
                : job.budget_min
                ? `From $${job.budget_min}`
                : `Up to $${job.budget_max}`}
            </div>
          ) : (
            <span className="text-gray-400 text-sm">Budget negotiable</span>
          )}
          <span className="text-xs text-gray-400">
            {formatDistanceToNow(new Date(job.created_at), { addSuffix: true })}
          </span>
        </div>
      </div>
    </Link>
  );
};

export default JobCard;
