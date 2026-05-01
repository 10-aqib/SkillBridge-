import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  MapPin, Clock, DollarSign, Tag, Users, Calendar,
  CheckCircle, XCircle, ArrowLeft, Send
} from 'lucide-react';
import api from '../utils/api';
import type { Job, JobApplication } from '../types';
import { useAuth } from '../hooks/useAuth';
import { formatDistanceToNow } from 'date-fns';
import toast from 'react-hot-toast';
import clsx from 'clsx';

const JobDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const { user } = useAuth();
  const navigate = useNavigate();
  const [job, setJob] = useState<Job | null>(null);
  const [applications, setApplications] = useState<JobApplication[]>([]);
  const [loading, setLoading] = useState(true);
  const [applying, setApplying] = useState(false);
  const [showApplyForm, setShowApplyForm] = useState(false);
  const [coverLetter, setCoverLetter] = useState('');
  const [proposedRate, setProposedRate] = useState('');

  useEffect(() => {
    const load = async () => {
      try {
        const { data } = await api.get(`/jobs/${id}`);
        setJob(data);
        if (user?.role === 'client' && data.client_id === user.id) {
          const appRes = await api.get(`/jobs/${id}/applications`);
          setApplications(appRes.data);
        }
      } catch {
        toast.error('Job not found');
        navigate('/jobs');
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [id, user]);

  const handleApply = async (e: React.FormEvent) => {
    e.preventDefault();
    setApplying(true);
    try {
      await api.post(`/jobs/${id}/apply`, {
        cover_letter: coverLetter,
        proposed_rate: proposedRate ? parseFloat(proposedRate) : undefined,
      });
      toast.success('Application submitted!');
      setShowApplyForm(false);
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { error?: string } } })?.response?.data?.error || 'Failed to apply';
      toast.error(msg);
    } finally {
      setApplying(false);
    }
  };

  const handleApplicationAction = async (appId: number, status: 'accepted' | 'rejected') => {
    try {
      await api.put(`/jobs/${id}/applications/${appId}`, { status });
      setApplications((prev) => prev.map((a) => a.id === appId ? { ...a, status } : a));
      toast.success(`Application ${status}`);
    } catch {
      toast.error('Failed to update application');
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-gray-400">Loading...</div>
      </div>
    );
  }

  if (!job) return null;

  const isOwner = user?.role === 'client' && user.id === job.client_id;
  const canApply = user?.role === 'worker' && job.status === 'open';

  const statusColor: Record<string, string> = {
    open: 'bg-green-100 text-green-700',
    'in-progress': 'bg-blue-100 text-blue-700',
    completed: 'bg-gray-100 text-gray-600',
    cancelled: 'bg-red-100 text-red-600',
  };

  const appStatusColor: Record<string, string> = {
    pending: 'bg-yellow-100 text-yellow-700',
    accepted: 'bg-green-100 text-green-700',
    rejected: 'bg-red-100 text-red-600',
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <button onClick={() => navigate(-1)} className="flex items-center gap-2 text-gray-500 hover:text-gray-700 mb-6">
          <ArrowLeft className="w-4 h-4" /> Back to Jobs
        </button>

        {/* Job Header */}
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-8 mb-6">
          <div className="flex items-start justify-between gap-4 mb-4">
            <h1 className="text-2xl font-bold text-gray-900">{job.title}</h1>
            <span className={clsx('text-sm px-3 py-1 rounded-full font-medium flex-shrink-0', statusColor[job.status])}>
              {job.status.replace('-', ' ')}
            </span>
          </div>

          <div className="flex flex-wrap gap-4 text-sm text-gray-500 mb-6">
            <div className="flex items-center gap-1">
              <Tag className="w-4 h-4 text-blue-500" />
              <span className="text-blue-600 font-medium">{job.category}</span>
            </div>
            <div className="flex items-center gap-1">
              <MapPin className="w-4 h-4" />
              {job.location}
            </div>
            <div className="flex items-center gap-1">
              <Clock className="w-4 h-4" />
              <span className="capitalize">{job.job_type.replace('-', ' ')}</span>
            </div>
            {job.deadline && (
              <div className="flex items-center gap-1">
                <Calendar className="w-4 h-4 text-orange-400" />
                Deadline: {new Date(job.deadline).toLocaleDateString()}
              </div>
            )}
            <div className="flex items-center gap-1">
              <Users className="w-4 h-4" />
              {job.application_count || 0} application{(job.application_count || 0) !== 1 ? 's' : ''}
            </div>
          </div>

          {(job.budget_min || job.budget_max) && (
            <div className="flex items-center gap-2 mb-6 p-4 bg-green-50 rounded-xl">
              <DollarSign className="w-5 h-5 text-green-600" />
              <span className="text-green-700 font-semibold text-lg">
                {job.budget_min && job.budget_max
                  ? `$${job.budget_min} – $${job.budget_max}`
                  : job.budget_min
                  ? `From $${job.budget_min}`
                  : `Up to $${job.budget_max}`}
              </span>
              <span className="text-green-600 text-sm">budget</span>
            </div>
          )}

          <div className="mb-6">
            <h2 className="font-semibold text-gray-900 mb-2">Description</h2>
            <p className="text-gray-600 leading-relaxed whitespace-pre-wrap">{job.description}</p>
          </div>

          {/* Client info */}
          <div className="flex items-center gap-3 pt-6 border-t border-gray-50">
            <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center">
              {job.client_avatar ? (
                <img src={job.client_avatar} alt={job.client_name} className="w-10 h-10 rounded-full" />
              ) : (
                <span className="text-blue-600 font-semibold">
                  {(job.client_name || 'C').charAt(0).toUpperCase()}
                </span>
              )}
            </div>
            <div>
              <p className="font-medium text-gray-900">{job.client_name}</p>
              <p className="text-xs text-gray-400">Posted {formatDistanceToNow(new Date(job.created_at), { addSuffix: true })}</p>
            </div>
          </div>

          {/* Apply button for workers */}
          {canApply && !showApplyForm && (
            <button
              onClick={() => user ? setShowApplyForm(true) : navigate('/login')}
              className="mt-6 w-full bg-blue-600 text-white py-3 rounded-xl font-semibold hover:bg-blue-700 transition-colors flex items-center justify-center gap-2"
            >
              <Send className="w-5 h-5" />
              Apply for this Job
            </button>
          )}

          {/* Apply Form */}
          {showApplyForm && (
            <form onSubmit={handleApply} className="mt-6 p-6 bg-blue-50 rounded-xl space-y-4">
              <h3 className="font-semibold text-gray-900">Submit Application</h3>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Cover Letter</label>
                <textarea
                  value={coverLetter}
                  onChange={(e) => setCoverLetter(e.target.value)}
                  rows={4}
                  placeholder="Introduce yourself and explain why you're a great fit..."
                  className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none bg-white"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Proposed Rate ($)</label>
                <input
                  type="number"
                  value={proposedRate}
                  onChange={(e) => setProposedRate(e.target.value)}
                  placeholder="Your rate..."
                  min="0"
                  step="0.01"
                  className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
                />
              </div>
              <div className="flex gap-3">
                <button
                  type="button"
                  onClick={() => setShowApplyForm(false)}
                  className="flex-1 py-3 rounded-xl border border-gray-200 text-gray-600 hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={applying}
                  className="flex-1 bg-blue-600 text-white py-3 rounded-xl font-semibold hover:bg-blue-700 disabled:opacity-60"
                >
                  {applying ? 'Submitting...' : 'Submit Application'}
                </button>
              </div>
            </form>
          )}
        </div>

        {/* Applications (owner only) */}
        {isOwner && (
          <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-8">
            <h2 className="font-semibold text-gray-900 mb-4">
              Applications ({applications.length})
            </h2>
            {applications.length === 0 ? (
              <div className="text-center py-8 text-gray-400">No applications yet</div>
            ) : (
              <div className="space-y-4">
                {applications.map((app) => (
                  <div key={app.id} className="border border-gray-100 rounded-xl p-4">
                    <div className="flex items-start justify-between gap-3 mb-3">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0">
                          {app.worker_avatar ? (
                            <img src={app.worker_avatar} alt={app.worker_name} className="w-10 h-10 rounded-full" />
                          ) : (
                            <span className="text-blue-600 font-semibold text-sm">
                              {(app.worker_name || 'W').charAt(0).toUpperCase()}
                            </span>
                          )}
                        </div>
                        <div>
                          <p
                            className="font-medium text-gray-900 hover:text-blue-600 cursor-pointer"
                            onClick={() => navigate(`/workers/${app.worker_id}`)}
                          >
                            {app.worker_name}
                          </p>
                          <div className="flex items-center gap-3 text-xs text-gray-500">
                            {app.worker_title && <span>{app.worker_title}</span>}
                            {app.avg_rating ? <span>⭐ {app.avg_rating.toFixed(1)}</span> : null}
                            {app.total_jobs ? <span>{app.total_jobs} jobs</span> : null}
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        {app.proposed_rate && (
                          <span className="text-green-600 font-semibold text-sm">${app.proposed_rate}</span>
                        )}
                        <span className={clsx('text-xs px-2 py-1 rounded-full font-medium', appStatusColor[app.status])}>
                          {app.status}
                        </span>
                      </div>
                    </div>
                    {app.cover_letter && (
                      <p className="text-sm text-gray-600 mb-3 bg-gray-50 p-3 rounded-lg">{app.cover_letter}</p>
                    )}
                    {app.status === 'pending' && (
                      <div className="flex gap-2">
                        <button
                          onClick={() => handleApplicationAction(app.id, 'accepted')}
                          className="flex items-center gap-1 text-sm bg-green-600 text-white px-3 py-1.5 rounded-lg hover:bg-green-700"
                        >
                          <CheckCircle className="w-4 h-4" /> Accept
                        </button>
                        <button
                          onClick={() => handleApplicationAction(app.id, 'rejected')}
                          className="flex items-center gap-1 text-sm bg-red-100 text-red-600 px-3 py-1.5 rounded-lg hover:bg-red-200"
                        >
                          <XCircle className="w-4 h-4" /> Reject
                        </button>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default JobDetailPage;
