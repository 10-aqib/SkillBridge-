import React from 'react';
import { Link } from 'react-router-dom';
import { Zap, Globe, Mail, Phone, ExternalLink } from 'lucide-react';

const Footer: React.FC = () => {
  return (
    <footer className="bg-gray-900 text-gray-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Brand */}
          <div className="col-span-1 md:col-span-1">
            <Link to="/" className="flex items-center gap-2 mb-4">
              <div className="bg-blue-600 p-1.5 rounded-lg">
                <Zap className="w-5 h-5 text-white" />
              </div>
              <span className="text-xl font-bold text-white">
                Skill<span className="text-blue-400">Bridge</span>
              </span>
            </Link>
            <p className="text-sm text-gray-400 mb-4">
              Connecting skilled workers with clients across your local community.
            </p>
            <div className="flex gap-3">
              {[Globe, Mail, Phone, ExternalLink].map((Icon, i) => (
                <a
                  key={i}
                  href="#"
                  className="w-8 h-8 rounded-full bg-gray-800 flex items-center justify-center hover:bg-blue-600 transition-colors"
                >
                  <Icon className="w-4 h-4" />
                </a>
              ))}
            </div>
          </div>

          {/* For Workers */}
          <div>
            <h3 className="font-semibold text-white mb-4">For Workers</h3>
            <ul className="space-y-2 text-sm">
              <li><Link to="/register" className="hover:text-white transition-colors">Create Profile</Link></li>
              <li><Link to="/jobs" className="hover:text-white transition-colors">Browse Jobs</Link></li>
              <li><Link to="/dashboard/worker" className="hover:text-white transition-colors">Worker Dashboard</Link></li>
              <li><a href="#" className="hover:text-white transition-colors">How It Works</a></li>
            </ul>
          </div>

          {/* For Clients */}
          <div>
            <h3 className="font-semibold text-white mb-4">For Clients</h3>
            <ul className="space-y-2 text-sm">
              <li><Link to="/workers" className="hover:text-white transition-colors">Find Workers</Link></li>
              <li><Link to="/jobs/new" className="hover:text-white transition-colors">Post a Job</Link></li>
              <li><Link to="/dashboard/client" className="hover:text-white transition-colors">Client Dashboard</Link></li>
              <li><a href="#" className="hover:text-white transition-colors">Success Stories</a></li>
            </ul>
          </div>

          {/* Company */}
          <div>
            <h3 className="font-semibold text-white mb-4">Company</h3>
            <ul className="space-y-2 text-sm">
              <li><a href="#" className="hover:text-white transition-colors">About Us</a></li>
              <li><a href="#" className="hover:text-white transition-colors">Contact</a></li>
              <li><a href="#" className="hover:text-white transition-colors">Privacy Policy</a></li>
              <li><a href="#" className="hover:text-white transition-colors">Terms of Service</a></li>
            </ul>
          </div>
        </div>

        <div className="border-t border-gray-800 mt-10 pt-6 text-center text-sm text-gray-500">
          <p>© {new Date().getFullYear()} SkillBridge. All rights reserved.</p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
