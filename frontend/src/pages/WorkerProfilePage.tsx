import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  MapPin, Phone, Star, Clock, Briefcase, CheckCircle, Award, Calendar,
  MessageSquare, DollarSign, ArrowLeft
} from 'lucide-react';
import api from '../utils/api';
import type { WorkerProfile } from '../types';
import { useAuth } from '../hooks/useAuth';
import SkillBadge from '../components/SkillBadge';
import ReviewCard from '../components/ReviewCard';
import StarRating from '../components/StarRating';
import toast from 'react-hot-toast';

const WorkerProfilePage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const { user } = useAuth();
  const navigate = useNavigate();
  const [worker, setWorker] = useState<WorkerProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'portfolio' | 'reviews'>('portfolio');

  useEffect(() => {
    const fetchWorker = async () => {
      try {
        const { data } = await api.get(`/workers/${id}`);
        setWorker(data);
      } catch {
        toast.error('Worker not found');
        navigate('/workers');
      } finally {
        setLoading(false);
      }
    };
    fetchWorker();
  }, [id]);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-gray-400">Loading...</div>
      </div>
    );
  }

  if (!worker) return null;

  const skills: string[] = (() => {
    try { return JSON.parse(worker.skills || '[]'); } catch { return []; }
  })();

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Back */}
        <button
          onClick={() => navigate(-1)}
          className="flex items-center gap-2 text-gray-500 hover:text-gray-700 mb-6"
        >
          <ArrowLeft className="w-4 h-4" /> Back to Search
        </button>

        {/* Profile Header */}
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-8 mb-6">
          <div className="flex flex-col md:flex-row gap-6 items-start">
            <div className="relative">
              {worker.avatar_url ? (
                <img
                  src={worker.avatar_url}
                  alt={worker.full_name}
                  className="w-28 h-28 rounded-2xl object-cover"
                />
              ) : (
                <div className="w-28 h-28 rounded-2xl bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center">
                  <span className="text-white text-4xl font-bold">
                    {worker.full_name.charAt(0).toUpperCase()}
                  </span>
                </div>
              )}
              {worker.is_verified === 1 && (
                <div className="absolute -bottom-2 -right-2 bg-white rounded-full p-0.5">
                  <CheckCircle className="w-6 h-6 text-blue-600 fill-blue-100" />
                </div>
              )}
            </div>

            <div className="flex-1">
              <div className="flex flex-wrap items-start justify-between gap-4">
                <div>
                  <h1 className="text-2xl font-bold text-gray-900">{worker.full_name}</h1>
                  {worker.title && <p className="text-blue-600 font-medium mt-0.5">{worker.title}</p>}
                  {worker.location && (
                    <div className="flex items-center gap-1 mt-2 text-gray-500">
                      <MapPin className="w-4 h-4" />
                      <span>{worker.location}</span>
                    </div>
                  )}
                </div>
                {user && user.role === 'client' && user.id !== worker.id && (
                  <div className="flex gap-3">
                    {worker.phone && (
                      <a
                        href={`tel:${worker.phone}`}
                        className="flex items-center gap-2 px-4 py-2 border border-gray-200 rounded-xl text-gray-700 hover:bg-gray-50"
                      >
                        <Phone className="w-4 h-4" />
                        Call
                      </a>
                    )}
                    <button
                      onClick={() => navigate('/jobs/new')}
                      className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-xl hover:bg-blue-700"
                    >
                      <MessageSquare className="w-4 h-4" />
                      Post a Job
                    </button>
                  </div>
                )}
              </div>

              {/* Stats */}
              <div className="flex flex-wrap gap-6 mt-4">
                <div className="flex items-center gap-2">
                  <div className="flex items-center gap-1">
                    <Star className="w-5 h-5 text-yellow-400 fill-yellow-400" />
                    <span className="font-bold text-gray-900">
                      {worker.avg_rating > 0 ? worker.avg_rating.toFixed(1) : 'New'}
                    </span>
                  </div>
                  {worker.reviews && worker.reviews.length > 0 && (
                    <span className="text-gray-400 text-sm">({worker.reviews.length} reviews)</span>
                  )}
                </div>
                <div className="flex items-center gap-1 text-gray-600">
                  <Briefcase className="w-4 h-4 text-green-500" />
                  <span>{worker.total_jobs} jobs completed</span>
                </div>
                {worker.experience_years !== undefined && worker.experience_years !== null && (
                  <div className="flex items-center gap-1 text-gray-600">
                    <Award className="w-4 h-4 text-purple-500" />
                    <span>{worker.experience_years} years experience</span>
                  </div>
                )}
                {worker.availability && (
                  <div className="flex items-center gap-1 text-gray-600">
                    <Clock className="w-4 h-4 text-blue-400" />
                    <span className="capitalize">{worker.availability}</span>
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Rates */}
          {(worker.hourly_rate || worker.daily_rate) && (
            <div className="flex gap-6 mt-6 pt-6 border-t border-gray-50">
              {worker.hourly_rate && (
                <div className="flex items-center gap-2">
                  <DollarSign className="w-5 h-5 text-green-600" />
                  <div>
                    <p className="text-2xl font-bold text-gray-900">${worker.hourly_rate}</p>
                    <p className="text-sm text-gray-500">per hour</p>
                  </div>
                </div>
              )}
              {worker.daily_rate && (
                <div className="flex items-center gap-2">
                  <Calendar className="w-5 h-5 text-blue-500" />
                  <div>
                    <p className="text-2xl font-bold text-gray-900">${worker.daily_rate}</p>
                    <p className="text-sm text-gray-500">per day</p>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left column */}
          <div className="space-y-6">
            {/* Bio */}
            {worker.bio && (
              <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
                <h2 className="font-semibold text-gray-900 mb-3">About</h2>
                <p className="text-gray-600 leading-relaxed">{worker.bio}</p>
              </div>
            )}

            {/* Skills */}
            {skills.length > 0 && (
              <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
                <h2 className="font-semibold text-gray-900 mb-3">Skills</h2>
                <div className="flex flex-wrap gap-2">
                  {skills.map((skill, i) => (
                    <SkillBadge key={i} skill={skill} />
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Right column */}
          <div className="lg:col-span-2">
            {/* Tabs */}
            <div className="flex gap-1 bg-gray-100 p-1 rounded-xl mb-6">
              {(['portfolio', 'reviews'] as const).map((tab) => (
                <button
                  key={tab}
                  onClick={() => setActiveTab(tab)}
                  className={`flex-1 py-2 rounded-lg text-sm font-medium transition-colors capitalize ${
                    activeTab === tab ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'
                  }`}
                >
                  {tab} {tab === 'reviews' && worker.reviews && `(${worker.reviews.length})`}
                </button>
              ))}
            </div>

            {/* Portfolio */}
            {activeTab === 'portfolio' && (
              <div>
                {worker.portfolio && worker.portfolio.length > 0 ? (
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    {worker.portfolio.map((item) => (
                      <div key={item.id} className="bg-white rounded-xl border border-gray-100 shadow-sm overflow-hidden">
                        {item.image_url ? (
                          <img src={item.image_url} alt={item.title} className="w-full h-40 object-cover" />
                        ) : (
                          <div className="w-full h-40 bg-gradient-to-br from-blue-100 to-blue-200 flex items-center justify-center">
                            <Briefcase className="w-12 h-12 text-blue-300" />
                          </div>
                        )}
                        <div className="p-4">
                          <h3 className="font-semibold text-gray-900">{item.title}</h3>
                          {item.description && (
                            <p className="text-sm text-gray-500 mt-1">{item.description}</p>
                          )}
                          {item.completed_date && (
                            <p className="text-xs text-gray-400 mt-2">
                              Completed: {new Date(item.completed_date).toLocaleDateString()}
                            </p>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div className="text-center py-12 bg-white rounded-2xl border border-gray-100">
                    <Briefcase className="w-12 h-12 text-gray-200 mx-auto mb-3" />
                    <p className="text-gray-400">No portfolio items yet</p>
                  </div>
                )}
              </div>
            )}

            {/* Reviews */}
            {activeTab === 'reviews' && (
              <div>
                {worker.reviews && worker.reviews.length > 0 ? (
                  <div className="space-y-4">
                    <div className="flex items-center gap-3 bg-white rounded-xl border border-gray-100 p-4 shadow-sm">
                      <div className="text-center">
                        <p className="text-4xl font-black text-gray-900">{worker.avg_rating.toFixed(1)}</p>
                        <StarRating rating={worker.avg_rating} showValue={false} />
                        <p className="text-xs text-gray-400 mt-1">{worker.reviews.length} reviews</p>
                      </div>
                    </div>
                    {worker.reviews.map((review) => (
                      <ReviewCard key={review.id} review={review} />
                    ))}
                  </div>
                ) : (
                  <div className="text-center py-12 bg-white rounded-2xl border border-gray-100">
                    <Star className="w-12 h-12 text-gray-200 mx-auto mb-3" />
                    <p className="text-gray-400">No reviews yet</p>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default WorkerProfilePage;
