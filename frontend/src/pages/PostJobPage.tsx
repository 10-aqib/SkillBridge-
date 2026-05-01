import React from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import api from '../utils/api';
import toast from 'react-hot-toast';
import { Briefcase, MapPin, DollarSign, Calendar, AlignLeft, Tag } from 'lucide-react';

const jobSchema = z.object({
  title: z.string().min(5, 'Title must be at least 5 characters'),
  description: z.string().min(20, 'Description must be at least 20 characters'),
  category: z.string().min(1, 'Category is required'),
  location: z.string().min(1, 'Location is required'),
  job_type: z.enum(['one-time', 'permanent']),
  budget_min: z.string().optional(),
  budget_max: z.string().optional(),
  deadline: z.string().optional(),
});

type JobFormData = z.infer<typeof jobSchema>;

const categories = [
  'Electrician', 'Plumbing', 'Carpentry', 'Painting', 'Home Tutoring',
  'Moving', 'Cleaning', 'Landscaping', 'HVAC', 'Roofing', 'General Labor', 'Other',
];

const PostJobPage: React.FC = () => {
  const { user } = useAuth();
  const navigate = useNavigate();

  React.useEffect(() => {
    if (!user) { navigate('/login'); return; }
    if (user.role !== 'client') {
      toast.error('Only clients can post jobs');
      navigate('/');
    }
  }, [user]);

  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<JobFormData>({
    resolver: zodResolver(jobSchema),
    defaultValues: { job_type: 'one-time' },
  });

  const onSubmit = async (data: JobFormData) => {
    try {
      const payload = {
        ...data,
        budget_min: data.budget_min ? parseFloat(data.budget_min) : undefined,
        budget_max: data.budget_max ? parseFloat(data.budget_max) : undefined,
      };
      const { data: job } = await api.post('/jobs', payload);
      toast.success('Job posted successfully!');
      navigate(`/jobs/${job.id}`);
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { error?: string } } })?.response?.data?.error || 'Failed to post job';
      toast.error(msg);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-2xl mx-auto px-4 sm:px-6 py-10">
        <div className="mb-8">
          <h1 className="text-2xl font-bold text-gray-900">Post a Job</h1>
          <p className="text-gray-500 mt-1">Describe your project and find the right professional</p>
        </div>

        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-8">
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
            {/* Title */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Job Title *</label>
              <div className="relative">
                <Briefcase className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  {...register('title')}
                  type="text"
                  placeholder="e.g. Fix electrical wiring in kitchen"
                  className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              {errors.title && <p className="text-red-500 text-sm mt-1">{errors.title.message}</p>}
            </div>

            {/* Description */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Description *</label>
              <div className="relative">
                <AlignLeft className="absolute left-3 top-3 w-5 h-5 text-gray-400" />
                <textarea
                  {...register('description')}
                  rows={5}
                  placeholder="Describe the work that needs to be done..."
                  className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
                />
              </div>
              {errors.description && <p className="text-red-500 text-sm mt-1">{errors.description.message}</p>}
            </div>

            {/* Category */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Category *</label>
              <div className="relative">
                <Tag className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <select
                  {...register('category')}
                  className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 appearance-none bg-white"
                >
                  <option value="">Select a category...</option>
                  {categories.map((cat) => (
                    <option key={cat} value={cat}>{cat}</option>
                  ))}
                </select>
              </div>
              {errors.category && <p className="text-red-500 text-sm mt-1">{errors.category.message}</p>}
            </div>

            {/* Location & Job Type */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">Location *</label>
                <div className="relative">
                  <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    {...register('location')}
                    type="text"
                    placeholder="City, State"
                    className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                {errors.location && <p className="text-red-500 text-sm mt-1">{errors.location.message}</p>}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">Job Type *</label>
                <div className="flex gap-2">
                  {(['one-time', 'permanent'] as const).map((type) => (
                    <label key={type} className="flex-1">
                      <input {...register('job_type')} type="radio" value={type} className="sr-only" />
                      <div className="text-center py-3 px-2 rounded-xl border-2 cursor-pointer text-sm font-medium transition-colors border-gray-200 text-gray-600 hover:border-blue-300 peer-checked:border-blue-600">
                        {type === 'one-time' ? '⚡ One-time' : '🔄 Permanent'}
                      </div>
                    </label>
                  ))}
                </div>
              </div>
            </div>

            {/* Budget */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">Min Budget ($)</label>
                <div className="relative">
                  <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    {...register('budget_min')}
                    type="number"
                    min="0"
                    step="0.01"
                    placeholder="0"
                    className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1.5">Max Budget ($)</label>
                <div className="relative">
                  <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    {...register('budget_max')}
                    type="number"
                    min="0"
                    step="0.01"
                    placeholder="0"
                    className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
            </div>

            {/* Deadline */}
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Deadline <span className="text-gray-400">(optional)</span></label>
              <div className="relative">
                <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  {...register('deadline')}
                  type="date"
                  className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full bg-blue-600 text-white py-3 rounded-xl font-semibold hover:bg-blue-700 transition-colors disabled:opacity-60"
            >
              {isSubmitting ? 'Posting...' : 'Post Job'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

export default PostJobPage;
