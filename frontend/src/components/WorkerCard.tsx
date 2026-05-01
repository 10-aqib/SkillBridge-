import React from 'react';
import { Link } from 'react-router-dom';
import { MapPin, Star, Clock, CheckCircle, DollarSign } from 'lucide-react';
import type { WorkerProfile } from '../types';
import SkillBadge from './SkillBadge';

interface WorkerCardProps {
  worker: WorkerProfile;
}

const WorkerCard: React.FC<WorkerCardProps> = ({ worker }) => {
  const skills: string[] = (() => {
    try { return JSON.parse(worker.skills || '[]'); } catch { return []; }
  })();

  return (
    <Link to={`/workers/${worker.id}`} className="block">
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 hover:shadow-md hover:border-blue-200 transition-all duration-200 h-full flex flex-col">
        {/* Header */}
        <div className="flex items-start gap-4 mb-4">
          <div className="relative flex-shrink-0">
            {worker.avatar_url ? (
              <img
                src={worker.avatar_url}
                alt={worker.full_name}
                className="w-14 h-14 rounded-full object-cover"
              />
            ) : (
              <div className="w-14 h-14 rounded-full bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center">
                <span className="text-white text-xl font-bold">
                  {worker.full_name.charAt(0).toUpperCase()}
                </span>
              </div>
            )}
            {worker.is_verified === 1 && (
              <div className="absolute -bottom-1 -right-1">
                <CheckCircle className="w-5 h-5 text-blue-600 fill-white" />
              </div>
            )}
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="font-semibold text-gray-900 truncate">{worker.full_name}</h3>
            {worker.title && (
              <p className="text-sm text-gray-500 truncate">{worker.title}</p>
            )}
            {worker.location && (
              <div className="flex items-center gap-1 mt-1">
                <MapPin className="w-3 h-3 text-gray-400" />
                <span className="text-xs text-gray-500 truncate">{worker.location}</span>
              </div>
            )}
          </div>
        </div>

        {/* Rating & Jobs */}
        <div className="flex items-center gap-4 mb-4">
          <div className="flex items-center gap-1">
            <Star className="w-4 h-4 text-yellow-400 fill-yellow-400" />
            <span className="text-sm font-medium text-gray-700">
              {worker.avg_rating > 0 ? worker.avg_rating.toFixed(1) : 'New'}
            </span>
          </div>
          <div className="flex items-center gap-1">
            <CheckCircle className="w-4 h-4 text-green-500" />
            <span className="text-sm text-gray-500">{worker.total_jobs} jobs</span>
          </div>
          {worker.availability && (
            <div className="flex items-center gap-1">
              <Clock className="w-4 h-4 text-blue-400" />
              <span className="text-xs text-gray-500 capitalize">{worker.availability}</span>
            </div>
          )}
        </div>

        {/* Skills */}
        {skills.length > 0 && (
          <div className="flex flex-wrap gap-1.5 mb-4 flex-1">
            {skills.slice(0, 4).map((skill, i) => (
              <SkillBadge key={i} skill={skill} size="sm" />
            ))}
            {skills.length > 4 && (
              <span className="text-xs text-gray-400 self-center">+{skills.length - 4} more</span>
            )}
          </div>
        )}

        {/* Rate */}
        {worker.hourly_rate && (
          <div className="flex items-center gap-1 mt-auto pt-4 border-t border-gray-50">
            <DollarSign className="w-4 h-4 text-green-600" />
            <span className="text-base font-bold text-gray-900">${worker.hourly_rate}</span>
            <span className="text-sm text-gray-500">/hour</span>
          </div>
        )}
      </div>
    </Link>
  );
};

export default WorkerCard;
