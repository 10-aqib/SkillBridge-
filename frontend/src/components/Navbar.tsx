import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import { Zap, Menu, X, User, LogOut, LayoutDashboard } from 'lucide-react';

const Navbar: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const [menuOpen, setMenuOpen] = React.useState(false);
  const [dropdownOpen, setDropdownOpen] = React.useState(false);

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  const dashboardPath = user?.role === 'worker' ? '/dashboard/worker' : '/dashboard/client';

  return (
    <nav className="bg-white shadow-sm border-b border-gray-100 sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link to="/" className="flex items-center gap-2">
            <div className="bg-blue-600 p-1.5 rounded-lg">
              <Zap className="w-5 h-5 text-white" />
            </div>
            <span className="text-xl font-bold text-gray-900">
              Skill<span className="text-blue-600">Bridge</span>
            </span>
          </Link>

          {/* Desktop Nav */}
          <div className="hidden md:flex items-center gap-6">
            <Link to="/workers" className="text-gray-600 hover:text-blue-600 font-medium transition-colors">
              Find Workers
            </Link>
            <Link to="/jobs" className="text-gray-600 hover:text-blue-600 font-medium transition-colors">
              Browse Jobs
            </Link>
            {user ? (
              <>
                <Link to="/contracts" className="text-gray-600 hover:text-blue-600 font-medium transition-colors">
                  Contracts
                </Link>
                <div className="relative">
                  <button
                    onClick={() => setDropdownOpen(!dropdownOpen)}
                    className="flex items-center gap-2 text-gray-700 hover:text-blue-600 transition-colors"
                  >
                    {user.avatar_url ? (
                      <img src={user.avatar_url} alt={user.full_name} className="w-8 h-8 rounded-full object-cover" />
                    ) : (
                      <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center">
                        <span className="text-blue-600 font-semibold text-sm">
                          {user.full_name.charAt(0).toUpperCase()}
                        </span>
                      </div>
                    )}
                    <span className="font-medium">{user.full_name.split(' ')[0]}</span>
                  </button>
                  {dropdownOpen && (
                    <div className="absolute right-0 mt-2 w-48 bg-white rounded-xl shadow-lg border border-gray-100 py-1 z-50">
                      <Link
                        to={dashboardPath}
                        className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
                        onClick={() => setDropdownOpen(false)}
                      >
                        <LayoutDashboard className="w-4 h-4" />
                        Dashboard
                      </Link>
                      <Link
                        to="/profile"
                        className="flex items-center gap-2 px-4 py-2 text-sm text-gray-700 hover:bg-gray-50"
                        onClick={() => setDropdownOpen(false)}
                      >
                        <User className="w-4 h-4" />
                        Profile
                      </Link>
                      <button
                        onClick={handleLogout}
                        className="flex items-center gap-2 w-full px-4 py-2 text-sm text-red-600 hover:bg-red-50"
                      >
                        <LogOut className="w-4 h-4" />
                        Logout
                      </button>
                    </div>
                  )}
                </div>
              </>
            ) : (
              <div className="flex items-center gap-3">
                <Link to="/login" className="text-gray-700 hover:text-blue-600 font-medium transition-colors">
                  Login
                </Link>
                <Link
                  to="/register"
                  className="bg-blue-600 text-white px-4 py-2 rounded-lg font-medium hover:bg-blue-700 transition-colors"
                >
                  Get Started
                </Link>
              </div>
            )}
          </div>

          {/* Mobile menu button */}
          <button className="md:hidden p-2" onClick={() => setMenuOpen(!menuOpen)}>
            {menuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>
      </div>

      {/* Mobile menu */}
      {menuOpen && (
        <div className="md:hidden border-t border-gray-100 bg-white px-4 py-4 space-y-3">
          <Link to="/workers" className="block text-gray-700 font-medium py-2" onClick={() => setMenuOpen(false)}>
            Find Workers
          </Link>
          <Link to="/jobs" className="block text-gray-700 font-medium py-2" onClick={() => setMenuOpen(false)}>
            Browse Jobs
          </Link>
          {user ? (
            <>
              <Link to="/contracts" className="block text-gray-700 font-medium py-2" onClick={() => setMenuOpen(false)}>
                Contracts
              </Link>
              <Link to={dashboardPath} className="block text-gray-700 font-medium py-2" onClick={() => setMenuOpen(false)}>
                Dashboard
              </Link>
              <Link to="/profile" className="block text-gray-700 font-medium py-2" onClick={() => setMenuOpen(false)}>
                Profile
              </Link>
              <button onClick={handleLogout} className="block w-full text-left text-red-600 font-medium py-2">
                Logout
              </button>
            </>
          ) : (
            <>
              <Link to="/login" className="block text-gray-700 font-medium py-2" onClick={() => setMenuOpen(false)}>
                Login
              </Link>
              <Link to="/register" className="block bg-blue-600 text-white px-4 py-2 rounded-lg font-medium text-center" onClick={() => setMenuOpen(false)}>
                Get Started
              </Link>
            </>
          )}
        </div>
      )}
    </nav>
  );
};

export default Navbar;
