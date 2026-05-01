import React, { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Search, Filter, X } from 'lucide-react';
import api from '../utils/api';
import type { Job } from '../types';
import JobCard from '../components/JobCard';
import toast from 'react-hot-toast';

const categories = [
  'Electrician', 'Plumbing', 'Carpentry', 'Painting', 'Home Tutoring',
  'Moving', 'Cleaning', 'Landscaping', 'HVAC', 'Roofing', 'General Labor',
];

const JobsPage: React.FC = () => {
  const [searchParams] = useSearchParams();
  const [jobs, setJobs] = useState<Job[]>([]);
  const [loading, setLoading] = useState(false);
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState(searchParams.get('category') || '');
  const [location, setLocation] = useState('');
  const [jobType, setJobType] = useState('');
  const [showFilters, setShowFilters] = useState(false);

  const fetchJobs = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (category) params.set('category', category);
      if (location) params.set('location', location);
      if (jobType) params.set('job_type', jobType);
      const { data } = await api.get(`/jobs?${params.toString()}`);
      let filtered = data;
      if (search) {
        const term = search.toLowerCase();
        filtered = data.filter((j: Job) =>
          j.title.toLowerCase().includes(term) || j.description.toLowerCase().includes(term)
        );
      }
      setJobs(filtered);
    } catch {
      toast.error('Failed to load jobs');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchJobs(); }, []);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    fetchJobs();
  };

  const clearFilters = () => {
    setCategory('');
    setLocation('');
    setJobType('');
    setSearch('');
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-white border-b border-gray-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <h1 className="text-2xl font-bold text-gray-900 mb-4">Browse Jobs</h1>
          <form onSubmit={handleSearch} className="flex gap-3">
            <div className="flex-1 relative">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search jobs..."
                className="w-full pl-12 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <button
              type="button"
              onClick={() => setShowFilters(!showFilters)}
              className="flex items-center gap-2 px-4 py-3 border border-gray-200 rounded-xl hover:bg-gray-50 text-gray-600"
            >
              <Filter className="w-5 h-5" />
              <span className="hidden sm:inline">Filters</span>
            </button>
            <button type="submit" className="bg-blue-600 text-white px-6 py-3 rounded-xl font-medium hover:bg-blue-700">
              Search
            </button>
          </form>

          {showFilters && (
            <div className="mt-4 p-4 bg-gray-50 rounded-xl border border-gray-100">
              <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-1">Location</label>
                  <input
                    type="text"
                    value={location}
                    onChange={(e) => setLocation(e.target.value)}
                    placeholder="City..."
                    className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-1 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-1">Job Type</label>
                  <select
                    value={jobType}
                    onChange={(e) => setJobType(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none"
                  >
                    <option value="">Any</option>
                    <option value="one-time">One-time</option>
                    <option value="permanent">Permanent</option>
                  </select>
                </div>
              </div>
              <div className="flex justify-end mt-3 gap-2">
                <button onClick={clearFilters} className="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700">
                  <X className="w-4 h-4" /> Clear
                </button>
                <button
                  onClick={fetchJobs}
                  className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-blue-700"
                >
                  Apply
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Category chips */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
        <div className="flex gap-2 overflow-x-auto pb-2">
          <button
            onClick={() => { setCategory(''); setTimeout(fetchJobs, 50); }}
            className={`flex-shrink-0 px-4 py-2 rounded-full text-sm font-medium transition-colors ${
              !category ? 'bg-blue-600 text-white' : 'bg-white text-gray-600 border border-gray-200 hover:border-blue-300'
            }`}
          >
            All
          </button>
          {categories.map((cat) => (
            <button
              key={cat}
              onClick={() => { setCategory(cat); setTimeout(fetchJobs, 50); }}
              className={`flex-shrink-0 px-4 py-2 rounded-full text-sm font-medium transition-colors ${
                category === cat ? 'bg-blue-600 text-white' : 'bg-white text-gray-600 border border-gray-200 hover:border-blue-300'
              }`}
            >
              {cat}
            </button>
          ))}
        </div>
      </div>

      {/* Results */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pb-12">
        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="bg-white rounded-2xl p-6 animate-pulse border border-gray-100 h-48">
                <div className="h-5 bg-gray-200 rounded mb-3" />
                <div className="h-3 bg-gray-100 rounded mb-2" />
                <div className="h-3 bg-gray-100 rounded w-2/3" />
              </div>
            ))}
          </div>
        ) : jobs.length === 0 ? (
          <div className="text-center py-16">
            <Search className="w-12 h-12 text-gray-200 mx-auto mb-4" />
            <h3 className="text-lg font-semibold text-gray-700 mb-1">No jobs found</h3>
            <p className="text-gray-400">Try different filters or check back later</p>
          </div>
        ) : (
          <>
            <p className="text-gray-500 text-sm mb-4">{jobs.length} job{jobs.length !== 1 ? 's' : ''} found</p>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {jobs.map((job) => <JobCard key={job.id} job={job} />)}
            </div>
          </>
        )}
      </div>
    </div>
  );
};

export default JobsPage;
