export interface User {
  id: number;
  email: string;
  password_hash: string;
  role: 'worker' | 'client';
  full_name: string;
  phone: string | null;
  location: string | null;
  avatar_url: string | null;
  bio: string | null;
  created_at: string;
}

export interface WorkerProfile {
  id: number;
  user_id: number;
  title: string | null;
  hourly_rate: number | null;
  daily_rate: number | null;
  skills: string; // JSON string
  availability: 'full-time' | 'part-time' | 'one-time' | null;
  experience_years: number | null;
  is_verified: number;
  total_jobs: number;
  avg_rating: number;
}

export interface PortfolioItem {
  id: number;
  worker_id: number;
  title: string;
  description: string | null;
  image_url: string | null;
  completed_date: string | null;
}

export interface Job {
  id: number;
  client_id: number;
  title: string;
  description: string;
  category: string;
  location: string;
  budget_min: number | null;
  budget_max: number | null;
  job_type: 'one-time' | 'permanent';
  status: 'open' | 'in-progress' | 'completed' | 'cancelled';
  created_at: string;
  deadline: string | null;
}

export interface JobApplication {
  id: number;
  job_id: number;
  worker_id: number;
  cover_letter: string | null;
  proposed_rate: number | null;
  status: 'pending' | 'accepted' | 'rejected';
  created_at: string;
}

export interface Contract {
  id: number;
  job_id: number;
  worker_id: number;
  client_id: number;
  agreed_rate: number;
  contract_type: string;
  status: 'active' | 'completed' | 'cancelled';
  start_date: string;
  end_date: string | null;
  commission_rate: number;
  platform_fee: number | null;
  created_at: string;
}

export interface Review {
  id: number;
  contract_id: number;
  reviewer_id: number;
  reviewee_id: number;
  rating: number;
  comment: string | null;
  created_at: string;
}

export interface JwtPayload {
  userId: number;
  role: 'worker' | 'client';
}

declare global {
  namespace Express {
    interface Request {
      user?: JwtPayload;
    }
  }
}
