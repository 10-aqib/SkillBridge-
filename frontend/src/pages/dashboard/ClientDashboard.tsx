import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Briefcase, Users, CheckCircle, Clock, Plus, TrendingUp } from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import api from '../../utils/api';
import type { Job, Contract } from '../../types';
import StatCard from '../../components/StatCard';
import toast from 'react-hot-toast';
import clsx from 'clsx';

const ClientDashboard: React.FC = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [jobs, setJobs] = useState<Job[]>([]);
  const [contracts, setContracts] = useState<Contract[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) { navigate('/login'); return; }
    if (user.role !== 'client') { navigate('/dashboard/worker'); return; }

    Promise.all([
      api.get('/jobs'),
      api.get('/contracts'),
    ]).then(([jobsRes, contractsRes]) => {
      setJobs(jobsRes.data.filter((j: Job) => j.client_id === user.id));
      setContracts(contractsRes.data);
    }).catch(() => toast.error('Failed to load data'))
      .finally(() => setLoading(false));
  }, [user]);

  if (!user) return null;

  const openJobs = jobs.filter((j) => j.status === 'open');
  const activeContracts = contracts.filter((c) => c.status === 'active');
  const completedContracts = contracts.filter((c) => c.status === 'completed');

  const statusColors: Record<string, string> = {
    active: 'bg-green-100 text-green-700',
    completed: 'bg-gray-100 text-gray-600',
    cancelled: 'bg-red-100 text-red-600',
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">
              Welcome back, {user.full_name.split(' ')[0]}! 👋
            </h1>
            <p className="text-gray-500 mt-1">Manage your jobs and contracts</p>
          </div>
          <button
            onClick={() => navigate('/jobs/new')}
            className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-xl hover:bg-blue-700"
          >
            <Plus className="w-4 h-4" />
            Post a Job
          </button>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          <StatCard title="Total Jobs Posted" value={jobs.length} icon={Briefcase} color="bg-blue-500" />
          <StatCard title="Open Jobs" value={openJobs.length} icon={Clock} color="bg-orange-500" />
          <StatCard title="Active Contracts" value={activeContracts.length} icon={CheckCircle} color="bg-green-500" />
          <StatCard title="Completed Work" value={completedContracts.length} icon={TrendingUp} color="bg-purple-500" />
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Recent Jobs */}
          <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="font-semibold text-gray-900">Recent Jobs</h2>
              <button onClick={() => navigate('/profile')} className="text-blue-600 text-sm hover:underline">
                View All
              </button>
            </div>
            {loading ? (
              <div className="text-center py-8 text-gray-400">Loading...</div>
            ) : jobs.length === 0 ? (
              <div className="text-center py-8">
                <Briefcase className="w-10 h-10 text-gray-200 mx-auto mb-2" />
                <p className="text-gray-400 text-sm">No jobs posted yet</p>
                <button
                  onClick={() => navigate('/jobs/new')}
                  className="mt-3 bg-blue-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-blue-700"
                >
                  Post Your First Job
                </button>
              </div>
            ) : (
              <div className="space-y-3">
                {jobs.slice(0, 3).map((job) => (
                  <div
                    key={job.id}
                    className="p-3 bg-gray-50 rounded-xl cursor-pointer hover:bg-blue-50"
                    onClick={() => navigate(`/jobs/${job.id}`)}
                  >
                    <div className="flex items-start justify-between">
                      <div>
                        <p className="font-medium text-gray-900 text-sm">{job.title}</p>
                        <p className="text-xs text-gray-500">{job.category} • {job.location}</p>
                      </div>
                      <div className="flex items-center gap-2">
                        {job.application_count !== undefined && job.application_count > 0 && (
                          <span className="flex items-center gap-1 text-xs text-blue-600 bg-blue-50 px-2 py-0.5 rounded-full">
                            <Users className="w-3 h-3" />
                            {job.application_count}
                          </span>
                        )}
                        <span className={clsx('text-xs px-2 py-1 rounded-full font-medium', {
                          'bg-green-100 text-green-700': job.status === 'open',
                          'bg-blue-100 text-blue-700': job.status === 'in-progress',
                          'bg-gray-100 text-gray-600': job.status === 'completed',
                        })}>
                          {job.status}
                        </span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Active Contracts */}
          <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="font-semibold text-gray-900">Active Contracts</h2>
              <button onClick={() => navigate('/contracts')} className="text-blue-600 text-sm hover:underline">
                View All
              </button>
            </div>
            {activeContracts.length === 0 ? (
              <div className="text-center py-8">
                <Users className="w-10 h-10 text-gray-200 mx-auto mb-2" />
                <p className="text-gray-400 text-sm">No active contracts</p>
                <button
                  onClick={() => navigate('/workers')}
                  className="mt-3 text-blue-600 text-sm hover:underline"
                >
                  Find skilled workers
                </button>
              </div>
            ) : (
              <div className="space-y-3">
                {activeContracts.slice(0, 4).map((contract) => (
                  <div
                    key={contract.id}
                    className="flex items-start justify-between p-3 bg-gray-50 rounded-xl cursor-pointer hover:bg-blue-50"
                    onClick={() => navigate('/contracts')}
                  >
                    <div>
                      <p className="font-medium text-gray-900 text-sm">{contract.job_title}</p>
                      <p className="text-xs text-gray-500">{contract.worker_name}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-semibold text-green-600">${contract.agreed_rate}</p>
                      <span className={clsx('text-xs px-1.5 py-0.5 rounded-full', statusColors[contract.status])}>
                        {contract.status}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default ClientDashboard;
