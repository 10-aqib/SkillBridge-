import React from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import toast from 'react-hot-toast';
import { Zap, Mail, Lock, User, Phone, MapPin } from 'lucide-react';

const registerSchema = z.object({
  full_name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  role: z.enum(['worker', 'client']),
  phone: z.string().optional(),
  location: z.string().optional(),
});

type RegisterFormData = z.infer<typeof registerSchema>;

const RegisterPage: React.FC = () => {
  const { register: authRegister } = useAuth();
  const navigate = useNavigate();
  const [selectedRole, setSelectedRole] = React.useState<'worker' | 'client'>('client');

  const { register, handleSubmit, setValue, formState: { errors, isSubmitting } } = useForm<RegisterFormData>({
    resolver: zodResolver(registerSchema),
    defaultValues: { role: 'client' },
  });

  const onSubmit = async (data: RegisterFormData) => {
    try {
      await authRegister(data);
      toast.success('Account created successfully!');
      navigate(data.role === 'worker' ? '/dashboard/worker' : '/dashboard/client');
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { error?: string } } })?.response?.data?.error || 'Registration failed';
      toast.error(msg);
    }
  };

  const handleRoleSelect = (role: 'worker' | 'client') => {
    setSelectedRole(role);
    setValue('role', role);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-white flex items-center justify-center px-4 py-10">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <Link to="/" className="inline-flex items-center gap-2 mb-4">
            <div className="bg-blue-600 p-2 rounded-xl">
              <Zap className="w-6 h-6 text-white" />
            </div>
            <span className="text-2xl font-bold text-gray-900">
              Skill<span className="text-blue-600">Bridge</span>
            </span>
          </Link>
          <h1 className="text-2xl font-bold text-gray-900">Create your account</h1>
          <p className="text-gray-500 mt-1">Join the SkillBridge community</p>
        </div>

        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-8">
          {/* Role Selector */}
          <div className="grid grid-cols-2 gap-3 mb-6">
            {(['client', 'worker'] as const).map((role) => (
              <button
                key={role}
                type="button"
                onClick={() => handleRoleSelect(role)}
                className={`py-3 px-4 rounded-xl border-2 font-medium text-sm transition-all ${
                  selectedRole === role
                    ? 'border-blue-600 bg-blue-50 text-blue-700'
                    : 'border-gray-200 text-gray-600 hover:border-gray-300'
                }`}
              >
                {role === 'client' ? '🏢 I need workers' : '🔧 I offer services'}
              </button>
            ))}
          </div>

          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <input type="hidden" {...register('role')} />

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Full Name</label>
              <div className="relative">
                <User className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  {...register('full_name')}
                  type="text"
                  placeholder="John Doe"
                  className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              {errors.full_name && <p className="text-red-500 text-sm mt-1">{errors.full_name.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Email</label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  {...register('email')}
                  type="email"
                  placeholder="you@example.com"
                  className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              {errors.email && <p className="text-red-500 text-sm mt-1">{errors.email.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Password</label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  {...register('password')}
                  type="password"
                  placeholder="Min. 6 characters"
                  className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
              {errors.password && <p className="text-red-500 text-sm mt-1">{errors.password.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Phone <span className="text-gray-400">(optional)</span></label>
              <div className="relative">
                <Phone className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  {...register('phone')}
                  type="tel"
                  placeholder="+1 234 567 8900"
                  className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Location <span className="text-gray-400">(optional)</span></label>
              <div className="relative">
                <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  {...register('location')}
                  type="text"
                  placeholder="City, State"
                  className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full bg-blue-600 text-white py-3 rounded-xl font-semibold hover:bg-blue-700 transition-colors disabled:opacity-60 mt-2"
            >
              {isSubmitting ? 'Creating account...' : 'Create Account'}
            </button>
          </form>

          <p className="text-center text-gray-500 text-sm mt-6">
            Already have an account?{' '}
            <Link to="/login" className="text-blue-600 font-medium hover:underline">
              Sign in
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
};

export default RegisterPage;
