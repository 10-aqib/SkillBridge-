import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { CheckCircle, XCircle, Clock, DollarSign, Calendar } from 'lucide-react';
import { useAuth } from '../hooks/useAuth';
import api from '../utils/api';
import type { Contract } from '../types';
import { formatDistanceToNow } from 'date-fns';
import toast from 'react-hot-toast';
import clsx from 'clsx';

const ContractsPage: React.FC = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [contracts, setContracts] = useState<Contract[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeFilter, setActiveFilter] = useState<string>('all');

  useEffect(() => {
    if (!user) { navigate('/login'); return; }
    api.get('/contracts')
      .then(({ data }) => setContracts(data))
      .catch(() => toast.error('Failed to load contracts'))
      .finally(() => setLoading(false));
  }, [user]);

  const handleAction = async (contractId: number, action: 'complete' | 'cancel') => {
    try {
      const { data } = await api.put(`/contracts/${contractId}/${action}`);
      setContracts((prev) => prev.map((c) => c.id === contractId ? data : c));
      toast.success(`Contract ${action === 'complete' ? 'completed' : 'cancelled'}`);
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { error?: string } } })?.response?.data?.error || 'Action failed';
      toast.error(msg);
    }
  };

  if (!user) return null;

  const filtered = activeFilter === 'all' ? contracts : contracts.filter((c) => c.status === activeFilter);

  const statusConfig: Record<string, { label: string; color: string; icon: React.ReactNode }> = {
    active: {
      label: 'Active',
      color: 'bg-green-100 text-green-700',
      icon: <Clock className="w-4 h-4 text-green-500" />,
    },
    completed: {
      label: 'Completed',
      color: 'bg-gray-100 text-gray-600',
      icon: <CheckCircle className="w-4 h-4 text-gray-400" />,
    },
    cancelled: {
      label: 'Cancelled',
      color: 'bg-red-100 text-red-600',
      icon: <XCircle className="w-4 h-4 text-red-400" />,
    },
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <h1 className="text-2xl font-bold text-gray-900 mb-6">My Contracts</h1>

        {/* Filters */}
        <div className="flex gap-2 mb-6">
          {['all', 'active', 'completed', 'cancelled'].map((f) => (
            <button
              key={f}
              onClick={() => setActiveFilter(f)}
              className={`px-4 py-2 rounded-full text-sm font-medium capitalize transition-colors ${
                activeFilter === f ? 'bg-blue-600 text-white' : 'bg-white text-gray-600 border border-gray-200 hover:border-blue-300'
              }`}
            >
              {f}
            </button>
          ))}
        </div>

        {loading ? (
          <div className="space-y-4">
            {Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="bg-white rounded-2xl p-6 animate-pulse border border-gray-100 h-32" />
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <div className="text-center py-16 bg-white rounded-2xl border border-gray-100">
            <Clock className="w-12 h-12 text-gray-200 mx-auto mb-4" />
            <h3 className="text-lg font-semibold text-gray-700 mb-1">No contracts found</h3>
            <p className="text-gray-400 text-sm">
              {user.role === 'worker' ? 'Apply for jobs to get contracts' : 'Post jobs and hire workers to create contracts'}
            </p>
          </div>
        ) : (
          <div className="space-y-4">
            {filtered.map((contract) => (
              <div key={contract.id} className="bg-white rounded-2xl border border-gray-100 shadow-sm p-6">
                <div className="flex items-start justify-between gap-4 mb-4">
                  <div>
                    <h3 className="font-semibold text-gray-900 text-lg">{contract.job_title}</h3>
                    <p className="text-sm text-gray-500 mt-0.5">
                      {user.role === 'worker'
                        ? `Client: ${contract.client_name}`
                        : `Worker: ${contract.worker_name}`}
                    </p>
                  </div>
                  <div className="flex items-center gap-2">
                    {statusConfig[contract.status]?.icon}
                    <span className={clsx('text-sm px-3 py-1 rounded-full font-medium', statusConfig[contract.status]?.color)}>
                      {statusConfig[contract.status]?.label}
                    </span>
                  </div>
                </div>

                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-4 p-4 bg-gray-50 rounded-xl">
                  <div>
                    <p className="text-xs text-gray-400 mb-0.5">Agreed Rate</p>
                    <div className="flex items-center gap-1">
                      <DollarSign className="w-4 h-4 text-green-600" />
                      <p className="font-semibold text-gray-900">${contract.agreed_rate}</p>
                    </div>
                  </div>
                  <div>
                    <p className="text-xs text-gray-400 mb-0.5">Type</p>
                    <p className="font-medium text-gray-700 capitalize">{contract.contract_type}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-400 mb-0.5">Start Date</p>
                    <div className="flex items-center gap-1">
                      <Calendar className="w-4 h-4 text-blue-400" />
                      <p className="font-medium text-gray-700">
                        {new Date(contract.start_date).toLocaleDateString()}
                      </p>
                    </div>
                  </div>
                  <div>
                    <p className="text-xs text-gray-400 mb-0.5">Platform Fee</p>
                    <p className="font-medium text-gray-700">
                      ${contract.platform_fee?.toFixed(2) || '0.00'} ({contract.commission_rate}%)
                    </p>
                  </div>
                </div>

                {contract.status === 'active' && (
                  <div className="flex gap-3">
                    <button
                      onClick={() => handleAction(contract.id, 'complete')}
                      className="flex items-center gap-2 bg-green-600 text-white px-4 py-2 rounded-xl text-sm font-medium hover:bg-green-700"
                    >
                      <CheckCircle className="w-4 h-4" /> Mark Complete
                    </button>
                    <button
                      onClick={() => handleAction(contract.id, 'cancel')}
                      className="flex items-center gap-2 bg-red-50 text-red-600 px-4 py-2 rounded-xl text-sm font-medium hover:bg-red-100"
                    >
                      <XCircle className="w-4 h-4" /> Cancel
                    </button>
                  </div>
                )}

                <p className="text-xs text-gray-400 mt-3">
                  Created {formatDistanceToNow(new Date(contract.created_at), { addSuffix: true })}
                </p>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default ContractsPage;
