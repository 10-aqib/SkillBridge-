import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Briefcase, Star, DollarSign, Clock, CheckCircle, TrendingUp } from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import api from '../../utils/api';
import type { Contract } from '../../types';
import StatCard from '../../components/StatCard';
import toast from 'react-hot-toast';
import clsx from 'clsx';

const WorkerDashboard: React.FC = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [contracts, setContracts] = useState<Contract[]>([]);
  const [profile, setProfile] = useState<{ avg_rating: number; total_jobs: number; hourly_rate?: number } | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) { navigate('/login'); return; }
    if (user.role !== 'worker') { navigate('/dashboard/client'); return; }

    Promise.all([
      api.get('/contracts'),
      api.get(`/workers/${user.id}`),
    ]).then(([contractsRes, workerRes]) => {
      setContracts(contractsRes.data);
      setProfile(workerRes.data);
    }).catch(() => toast.error('Failed to load data'))
      .finally(() => setLoading(false));
  }, [user]);

  if (!user) return null;

  const activeContracts = contracts.filter((c) => c.status === 'active');
  const completedContracts = contracts.filter((c) => c.status === 'completed');
  const totalEarnings = completedContracts.reduce((sum, c) => sum + (c.agreed_rate || 0), 0);

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
            <p className="text-gray-500 mt-1">Here's what's happening with your work</p>
          </div>
          <button
            onClick={() => navigate('/jobs')}
            className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-xl hover:bg-blue-700"
          >
            <Briefcase className="w-4 h-4" />
            Browse Jobs
          </button>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          <StatCard
            title="Active Contracts"
            value={activeContracts.length}
            icon={CheckCircle}
            color="bg-green-500"
          />
          <StatCard
            title="Jobs Completed"
            value={profile?.total_jobs || 0}
            icon={Briefcase}
            color="bg-blue-500"
          />
          <StatCard
            title="Avg Rating"
            value={profile?.avg_rating ? profile.avg_rating.toFixed(1) : 'N/A'}
            icon={Star}
            color="bg-yellow-500"
          />
          <StatCard
            title="Total Earnings"
            value={`$${totalEarnings.toLocaleString()}`}
            icon={DollarSign}
            color="bg-purple-500"
          />
        </div>

        {/* Profile Completeness */}
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6 mb-6">
          <div className="flex items-center justify-between mb-3">
            <h2 className="font-semibold text-gray-900">Profile Completeness</h2>
            <button
              onClick={() => navigate('/profile')}
              className="text-blue-600 text-sm hover:underline"
            >
              Edit Profile
            </button>
          </div>
          <div className="space-y-2">
            {[
              { label: 'Basic Info', done: !!user.full_name },
              { label: 'Location', done: !!user.location },
              { label: 'Bio', done: !!user.bio },
              { label: 'Hourly Rate', done: !!(profile as { hourly_rate?: number } | null)?.hourly_rate },
            ].map((item) => (
              <div key={item.label} className="flex items-center gap-2">
                <div className={clsx('w-5 h-5 rounded-full flex items-center justify-center', item.done ? 'bg-green-100' : 'bg-gray-100')}>
                  {item.done
                    ? <CheckCircle className="w-3 h-3 text-green-600" />
                    : <Clock className="w-3 h-3 text-gray-400" />
                  }
                </div>
                <span className={clsx('text-sm', item.done ? 'text-gray-700' : 'text-gray-400')}>{item.label}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Active Contracts */}
          <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="font-semibold text-gray-900">Active Contracts</h2>
              <button onClick={() => navigate('/contracts')} className="text-blue-600 text-sm hover:underline">
                View All
              </button>
            </div>
            {loading ? (
              <div className="text-center py-8 text-gray-400">Loading...</div>
            ) : activeContracts.length === 0 ? (
              <div className="text-center py-8">
                <TrendingUp className="w-10 h-10 text-gray-200 mx-auto mb-2" />
                <p className="text-gray-400 text-sm">No active contracts</p>
                <button onClick={() => navigate('/jobs')} className="mt-3 text-blue-600 text-sm hover:underline">
                  Browse available jobs
                </button>
              </div>
            ) : (
              <div className="space-y-3">
                {activeContracts.slice(0, 3).map((contract) => (
                  <div
                    key={contract.id}
                    className="flex items-start justify-between p-3 bg-gray-50 rounded-xl cursor-pointer hover:bg-blue-50"
                    onClick={() => navigate('/contracts')}
                  >
                    <div>
                      <p className="font-medium text-gray-900 text-sm">{contract.job_title}</p>
                      <p className="text-xs text-gray-500">{contract.client_name}</p>
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

          {/* All Contracts summary */}
          <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
            <h2 className="font-semibold text-gray-900 mb-4">Contract History</h2>
            {contracts.length === 0 ? (
              <div className="text-center py-8">
                <Briefcase className="w-10 h-10 text-gray-200 mx-auto mb-2" />
                <p className="text-gray-400 text-sm">No contracts yet</p>
              </div>
            ) : (
              <div className="space-y-3">
                {contracts.slice(0, 5).map((contract) => (
                  <div key={contract.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
                    <div>
                      <p className="font-medium text-gray-900 text-sm">{contract.job_title}</p>
                      <p className="text-xs text-gray-400">{new Date(contract.created_at).toLocaleDateString()}</p>
                    </div>
                    <span className={clsx('text-xs px-2 py-1 rounded-full font-medium', statusColors[contract.status])}>
                      {contract.status}
                    </span>
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

export default WorkerDashboard;
