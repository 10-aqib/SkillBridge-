import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import {
  Zap, Search, Star, Shield, Clock, Users, Briefcase, TrendingUp,
  Wrench, Zap as ZapIcon, Hammer, Paintbrush, GraduationCap, Truck, ChevronRight, CheckCircle
} from 'lucide-react';
import CategoryCard from '../components/CategoryCard';

const categories = [
  { title: 'Electricians', icon: ZapIcon, count: 120, color: 'bg-yellow-500' },
  { title: 'Plumbers', icon: Wrench, count: 95, color: 'bg-blue-500' },
  { title: 'Carpenters', icon: Hammer, count: 80, color: 'bg-orange-500' },
  { title: 'Painters', icon: Paintbrush, count: 110, color: 'bg-purple-500' },
  { title: 'Home Tutors', icon: GraduationCap, count: 200, color: 'bg-green-500' },
  { title: 'Movers', icon: Truck, count: 65, color: 'bg-red-500' },
];

const steps = [
  {
    step: '01',
    title: 'Post a Job or Search Workers',
    description: 'Describe what you need or browse hundreds of skilled professionals in your area.',
    icon: Search,
  },
  {
    step: '02',
    title: 'Review & Connect',
    description: 'Check profiles, ratings, and portfolios. Send messages and get quotes.',
    icon: Users,
  },
  {
    step: '03',
    title: 'Hire & Get It Done',
    description: 'Agree on terms, sign a contract, and track progress until completion.',
    icon: CheckCircle,
  },
];

const stats = [
  { label: 'Skilled Workers', value: '10,000+', icon: Users },
  { label: 'Jobs Completed', value: '50,000+', icon: Briefcase },
  { label: 'Client Satisfaction', value: '98%', icon: Star },
  { label: 'Cities Covered', value: '150+', icon: TrendingUp },
];

const LandingPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen">
      {/* Hero Section */}
      <section className="bg-gradient-to-br from-blue-600 via-blue-700 to-blue-800 text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 md:py-28">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            <div>
              <div className="inline-flex items-center gap-2 bg-blue-500/30 rounded-full px-4 py-2 mb-6">
                <Zap className="w-4 h-4 text-yellow-300" />
                <span className="text-sm font-medium">Trusted by 10,000+ professionals</span>
              </div>
              <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold leading-tight mb-6">
                Find Skilled Workers{' '}
                <span className="text-yellow-300">Near You</span>
              </h1>
              <p className="text-lg text-blue-100 mb-8 leading-relaxed">
                SkillBridge connects you with verified local tradespeople, tutors, and service professionals. 
                Post a job or find work — all in one place.
              </p>
              <div className="flex flex-col sm:flex-row gap-4">
                <Link
                  to="/workers"
                  className="bg-white text-blue-700 px-8 py-4 rounded-xl font-semibold hover:bg-blue-50 transition-colors text-center text-lg"
                >
                  Find Workers
                </Link>
                <Link
                  to="/register"
                  className="bg-orange-500 text-white px-8 py-4 rounded-xl font-semibold hover:bg-orange-600 transition-colors text-center text-lg"
                >
                  Post a Job
                </Link>
              </div>
              <div className="flex items-center gap-6 mt-8 text-sm text-blue-200">
                <div className="flex items-center gap-1"><Shield className="w-4 h-4" /> Verified Profiles</div>
                <div className="flex items-center gap-1"><Star className="w-4 h-4" /> Rated Reviews</div>
                <div className="flex items-center gap-1"><Clock className="w-4 h-4" /> Quick Hire</div>
              </div>
            </div>
            {/* Hero Image / Stats Grid */}
            <div className="hidden lg:grid grid-cols-2 gap-4">
              {stats.map((stat) => (
                <div key={stat.label} className="bg-white/10 backdrop-blur-sm rounded-2xl p-6 border border-white/20">
                  <stat.icon className="w-8 h-8 text-yellow-300 mb-3" />
                  <p className="text-3xl font-bold text-white">{stat.value}</p>
                  <p className="text-blue-200 text-sm mt-1">{stat.label}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Search Bar */}
      <section className="bg-white shadow-sm">
        <div className="max-w-4xl mx-auto px-4 py-6">
          <div className="flex gap-3">
            <div className="flex-1 relative">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                placeholder="Search for electricians, plumbers, tutors..."
                className="w-full pl-12 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500"
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    const val = (e.target as HTMLInputElement).value;
                    navigate(`/workers?skill=${encodeURIComponent(val)}`);
                  }
                }}
              />
            </div>
            <button
              onClick={() => navigate('/workers')}
              className="bg-blue-600 text-white px-6 py-3 rounded-xl font-medium hover:bg-blue-700 transition-colors"
            >
              Search
            </button>
          </div>
        </div>
      </section>

      {/* Categories */}
      <section className="py-16 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-10">
            <h2 className="text-3xl font-bold text-gray-900 mb-3">Browse by Category</h2>
            <p className="text-gray-500 text-lg">Find the right professional for every job</p>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
            {categories.map((cat) => (
              <CategoryCard
                key={cat.title}
                title={cat.title}
                icon={cat.icon}
                count={cat.count}
                color={cat.color}
                onClick={() => navigate(`/workers?skill=${encodeURIComponent(cat.title)}`)}
              />
            ))}
          </div>
        </div>
      </section>

      {/* How It Works */}
      <section className="py-16 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-gray-900 mb-3">How SkillBridge Works</h2>
            <p className="text-gray-500 text-lg">Simple steps to get started</p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 relative">
            {steps.map((step, i) => (
              <div key={step.step} className="relative flex flex-col items-center text-center">
                <div className="w-16 h-16 rounded-2xl bg-blue-600 flex items-center justify-center mb-6 relative z-10">
                  <step.icon className="w-8 h-8 text-white" />
                </div>
                {i < steps.length - 1 && (
                  <div className="hidden md:block absolute top-8 left-[calc(50%+2rem)] right-[-50%] h-0.5 bg-blue-100 z-0">
                    <ChevronRight className="absolute -right-4 -top-3 w-6 h-6 text-blue-300" />
                  </div>
                )}
                <div className="text-4xl font-black text-blue-100 mb-2">{step.step}</div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">{step.title}</h3>
                <p className="text-gray-500 leading-relaxed">{step.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Stats */}
      <section className="py-16 bg-blue-600">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
            {stats.map((stat) => (
              <div key={stat.label} className="text-center">
                <p className="text-4xl font-black text-white mb-1">{stat.value}</p>
                <p className="text-blue-200 font-medium">{stat.label}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-20 bg-gray-50">
        <div className="max-w-4xl mx-auto px-4 text-center">
          <h2 className="text-4xl font-bold text-gray-900 mb-4">
            Ready to Get Started?
          </h2>
          <p className="text-gray-500 text-lg mb-8">
            Join thousands of professionals and clients already using SkillBridge.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              to="/register"
              className="bg-blue-600 text-white px-8 py-4 rounded-xl font-semibold hover:bg-blue-700 transition-colors text-lg"
            >
              Join as a Worker
            </Link>
            <Link
              to="/register"
              className="bg-orange-500 text-white px-8 py-4 rounded-xl font-semibold hover:bg-orange-600 transition-colors text-lg"
            >
              Hire a Worker
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
};

export default LandingPage;
