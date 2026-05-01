import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { AuthProvider } from './context/AuthContext';
import { useAuth } from './hooks/useAuth';
import Navbar from './components/Navbar';
import Footer from './components/Footer';
import LandingPage from './pages/LandingPage';
import LoginPage from './pages/LoginPage';
import RegisterPage from './pages/RegisterPage';
import WorkerSearchPage from './pages/WorkerSearchPage';
import WorkerProfilePage from './pages/WorkerProfilePage';
import ClientProfilePage from './pages/ClientProfilePage';
import WorkerDashboard from './pages/dashboard/WorkerDashboard';
import ClientDashboard from './pages/dashboard/ClientDashboard';
import PostJobPage from './pages/PostJobPage';
import JobDetailPage from './pages/JobDetailPage';
import JobsPage from './pages/JobsPage';
import ContractsPage from './pages/ContractsPage';

const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { user, loading } = useAuth();
  if (loading) return <div className="min-h-screen flex items-center justify-center"><div className="text-gray-400">Loading...</div></div>;
  if (!user) return <Navigate to="/login" replace />;
  return <>{children}</>;
};

const Layout: React.FC<{ children: React.ReactNode; showFooter?: boolean }> = ({ children, showFooter = true }) => (
  <>
    <Navbar />
    <main>{children}</main>
    {showFooter && <Footer />}
  </>
);

const AppRoutes: React.FC = () => {
  return (
    <Routes>
      <Route path="/" element={<Layout><LandingPage /></Layout>} />
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />
      <Route path="/workers" element={<Layout><WorkerSearchPage /></Layout>} />
      <Route path="/workers/:id" element={<Layout><WorkerProfilePage /></Layout>} />
      <Route path="/jobs" element={<Layout><JobsPage /></Layout>} />
      <Route path="/jobs/:id" element={<Layout><JobDetailPage /></Layout>} />
      <Route path="/jobs/new" element={
        <ProtectedRoute><Layout><PostJobPage /></Layout></ProtectedRoute>
      } />
      <Route path="/profile" element={
        <ProtectedRoute><Layout><ClientProfilePage /></Layout></ProtectedRoute>
      } />
      <Route path="/contracts" element={
        <ProtectedRoute><Layout><ContractsPage /></Layout></ProtectedRoute>
      } />
      <Route path="/dashboard/worker" element={
        <ProtectedRoute><Layout><WorkerDashboard /></Layout></ProtectedRoute>
      } />
      <Route path="/dashboard/client" element={
        <ProtectedRoute><Layout><ClientDashboard /></Layout></ProtectedRoute>
      } />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
};

const App: React.FC = () => {
  return (
    <BrowserRouter>
      <AuthProvider>
        <AppRoutes />
        <Toaster
          position="top-right"
          toastOptions={{
            className: 'rounded-xl shadow-lg',
            duration: 3000,
          }}
        />
      </AuthProvider>
    </BrowserRouter>
  );
};

export default App;
