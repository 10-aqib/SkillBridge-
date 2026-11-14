'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { FirebaseError } from 'firebase/app';
import { signInWithEmailAndPassword, signInWithPopup, sendPasswordResetEmail } from 'firebase/auth';
import { auth, googleProvider } from '@/lib/firebase/client';
import { Loader2, Eye, EyeOff } from 'lucide-react';

export default function AdminLoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isResetMode, setIsResetMode] = useState(false);
  const [resetSent, setResetSent] = useState(false);
  const router = useRouter();

  // Create session and handle redirection
  const handleSession = async (idToken: string) => {
    const res = await fetch('/api/auth/session', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ idToken }),
    });

    if (res.ok) {
      const data = await res.json();
      const role = data.role;
      
      if (role === 'SUPER_ADMIN' || role === 'super_admin' || role === 'admin') {
        router.push('/adminpanel/dashboard');
      }
      
      router.refresh();
    } else {
      const data = await res.json();
      setError(data.error || 'You do not have permission to access the SkillBridge administration portal.');
      setIsLoading(false);
      auth.signOut();
    }
  };

  const handleEmailLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const idToken = await userCredential.user.getIdToken();
      await handleSession(idToken);
    } catch (err) {
      const code = err instanceof FirebaseError ? err.code : '';
      if (code === 'auth/user-disabled') {
        setError('Your administrator account has been disabled.');
      } else if (code === 'auth/network-request-failed') {
        setError('Unable to connect. Please check your internet connection and try again.');
      } else {
        setError('Invalid email or password.');
      }
      setIsLoading(false);
    }
  };

  const handleGoogleLogin = async () => {
    setIsLoading(true);
    setError('');
    
    try {
      const userCredential = await signInWithPopup(auth, googleProvider);
      const idToken = await userCredential.user.getIdToken();
      await handleSession(idToken);
    } catch (err) {
      const code = err instanceof FirebaseError ? err.code : '';
      if (code === 'auth/network-request-failed') {
        setError('Unable to connect. Please check your internet connection and try again.');
      } else {
        setError('Google sign-in failed. Please try again.');
      }
      setIsLoading(false);
    }
  };

  const handlePasswordReset = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) {
      setError('Please enter your admin email first.');
      return;
    }
    
    setIsLoading(true);
    setError('');
    
    try {
      await sendPasswordResetEmail(auth, email);
      setResetSent(true);
    } catch {
      setError('Failed to send password reset email. Check your email address.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen w-full flex flex-col items-center justify-center bg-sb-canvas p-4 relative overflow-hidden font-sans">
      {/* Subtle Background glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-sb-primary-subtle rounded-full blur-[100px] opacity-70 pointer-events-none" />
      
      <div className="w-full max-w-[500px] relative z-10 flex flex-col items-center">
        {/* Brand Header */}
        <div className="text-center mb-8 flex flex-col items-center">
          <div className="w-[84px] h-[84px] rounded-[22px] bg-sb-surface shadow-[0_8px_30px_rgb(0,0,0,0.04)] flex items-center justify-center mb-5 border border-sb-border">
            {/* Custom S Logo mimicking the reference image */}
            <svg width="46" height="46" viewBox="0 0 46 46" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M23.0001 0.165039L33.7383 6.36511L22.9515 12.5937L12.2133 6.39365L23.0001 0.165039Z" fill="#8FB6EC"/>
              <path d="M33.7383 6.36511V18.7653L22.9515 24.9938V12.5937L33.7383 6.36511Z" fill="#174A8B"/>
              <path d="M12.2133 6.39365V18.7938L22.9515 24.9938V12.5937L12.2133 6.39365Z" fill="#3D6FB0"/>
              <path d="M12.2618 39.635L22.9515 45.835L33.7868 39.5779L22.9999 33.3779L12.2618 39.635Z" fill="#8FB6EC"/>
              <path d="M22.9515 45.835V33.4348L33.7868 27.1777V39.5779L22.9515 45.835Z" fill="#174A8B"/>
              <path d="M12.2618 39.635V27.2348L22.9999 33.3779V45.7781L12.2618 39.635Z" fill="#3D6FB0"/>
              <path d="M22.9515 12.5938L33.7383 18.7938L22.9515 25.0224L12.1647 18.8224L22.9515 12.5938Z" fill="#8FB6EC"/>
              <path d="M33.7383 18.7938V31.194L22.9515 37.4225V25.0224L33.7383 18.7938Z" fill="#174A8B"/>
              <path d="M12.1647 18.8224V31.2225L22.9515 37.4225V25.0224L12.1647 18.8224Z" fill="#3D6FB0"/>
            </svg>
          </div>
          <h1 className="text-[26px] font-bold text-sb-text tracking-tight mb-1">
            SkillBridge
          </h1>
          <p className="text-[15px] text-sb-text-secondary font-medium">
            Sign in to access the dashboard
          </p>
        </div>

        {/* Login Card */}
        <div className="w-full bg-sb-surface/95 rounded-[24px] border border-sb-border shadow-[0_20px_60px_rgba(15,23,42,0.06)] px-8 py-10 sm:px-10">
          
          {error && (
            <div className="mb-6 p-4 rounded-xl bg-sb-error-subtle border border-sb-error/20 text-sm text-sb-error font-medium text-center">
              {error}
            </div>
          )}

          {resetSent && (
            <div className="mb-6 p-4 rounded-xl bg-sb-success-subtle border border-sb-success/20 text-sm text-sb-on-success-subtle font-medium text-center">
              Password reset email sent.
            </div>
          )}

          {!isResetMode ? (
            <form onSubmit={handleEmailLogin} className="space-y-5">
              {/* Email */}
              <div className="space-y-2">
                <label htmlFor="email" className="block text-[11px] font-bold text-sb-text-secondary uppercase tracking-wider">
                  EMAIL
                </label>
                <input 
                  id="email" 
                  type="email" 
                  placeholder="admin@skillbridge.com" 
                  required 
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full h-[56px] px-4 rounded-[14px] bg-sb-surface border border-sb-border-input text-[15px] text-sb-text placeholder:text-sb-text-secondary focus:outline-none focus:border-sb-focus focus:ring-4 focus:ring-sb-focus/10 transition-all"
                />
              </div>

              {/* Password */}
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <label htmlFor="password" className="block text-[11px] font-bold text-sb-text-secondary uppercase tracking-wider">
                    PASSWORD
                  </label>
                  <button 
                    type="button" 
                    onClick={() => setIsResetMode(true)}
                    className="text-[13px] font-bold text-sb-primary hover:text-sb-primary-hover transition-colors"
                  >
                    Forgot password?
                  </button>
                </div>
                <div className="relative">
                  <input 
                    id="password" 
                    type={showPassword ? "text" : "password"} 
                    required 
                    placeholder="Password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full h-[56px] pl-4 pr-12 rounded-[14px] bg-sb-surface border border-sb-border-input text-[15px] text-sb-text placeholder:text-sb-text-secondary focus:outline-none focus:border-sb-focus focus:ring-4 focus:ring-sb-focus/10 transition-all"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-4 top-1/2 -translate-y-1/2 text-sb-text-secondary hover:text-sb-text-secondary focus:outline-none"
                  >
                    {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                </div>
              </div>

              {/* Submit */}
              <button 
                type="submit" 
                disabled={isLoading}
                className="w-full h-[56px] rounded-[14px] bg-sb-primary hover:bg-sb-primary-hover active:scale-[0.98] text-sb-on-primary font-bold text-[15px] transition-all disabled:opacity-70 disabled:pointer-events-none flex items-center justify-center mt-2"
              >
                {isLoading ? (
                  <>
                    <Loader2 className="w-5 h-5 animate-spin mr-2" />
                    Signing in...
                  </>
                ) : (
                  'Continue'
                )}
              </button>
              
              {/* Divider */}
              <div className="flex items-center justify-center pt-2 pb-2">
                <div className="h-[1px] bg-sb-surface-sunken w-full" />
                <span className="px-4 text-[12px] font-semibold text-sb-text-secondary uppercase">OR</span>
                <div className="h-[1px] bg-sb-surface-sunken w-full" />
              </div>

              {/* Google Button */}
              <button
                type="button" 
                onClick={handleGoogleLogin}
                disabled={isLoading}
                className="w-full h-[56px] rounded-[14px] bg-sb-surface border border-sb-border-input hover:bg-sb-canvas active:scale-[0.98] text-sb-text font-bold text-[15px] transition-all disabled:opacity-70 disabled:pointer-events-none flex items-center justify-center gap-3"
              >
                <svg className="w-5 h-5" viewBox="0 0 24 24">
                  <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
                  <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
                  <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z" />
                  <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z" />
                </svg>
                Sign in with Google
              </button>
            </form>
          ) : (
            <form onSubmit={handlePasswordReset} className="space-y-5">
              <div className="space-y-2 text-center mb-2">
                <h3 className="text-[17px] font-bold text-sb-text">Reset Password</h3>
                <p className="text-[14px] text-sb-text-secondary">Enter your admin email to receive a reset link.</p>
              </div>
              
              <div className="space-y-2">
                <label htmlFor="reset-email" className="block text-[11px] font-bold text-sb-text-secondary uppercase tracking-wider">
                  EMAIL
                </label>
                <input 
                  id="reset-email" 
                  type="email" 
                  placeholder="admin@skillbridge.com" 
                  required 
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full h-[56px] px-4 rounded-[14px] bg-sb-surface border border-sb-border-input text-[15px] text-sb-text placeholder:text-sb-text-secondary focus:outline-none focus:border-sb-focus focus:ring-4 focus:ring-sb-focus/10 transition-all"
                />
              </div>

              <div className="pt-2 flex flex-col gap-3">
                <button 
                  type="submit" 
                  disabled={isLoading}
                  className="w-full h-[56px] rounded-[14px] bg-sb-primary hover:bg-sb-primary-hover active:scale-[0.98] text-sb-on-primary font-bold text-[15px] transition-all disabled:opacity-70 disabled:pointer-events-none flex items-center justify-center"
                >
                  {isLoading ? <Loader2 className="w-5 h-5 animate-spin" /> : 'Send Reset Link'}
                </button>
                <button 
                  type="button" 
                  onClick={() => setIsResetMode(false)}
                  className="w-full h-[56px] rounded-[14px] bg-sb-surface text-sb-text-secondary font-bold text-[15px] hover:bg-sb-canvas transition-colors"
                >
                  Back to login
                </button>
              </div>
            </form>
          )}
        </div>

        {/* Footer */}
        <div className="mt-8 text-[13px] font-medium text-sb-text-secondary">
          Powered by SkillBridge
        </div>
      </div>
    </div>
  );
}
