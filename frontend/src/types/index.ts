export interface User {
  id: number;
  email: string;
  role: 'worker' | 'client';
  full_name: string;
  phone?: string;
  location?: string;
  avatar_url?: string;
  bio?: string;
  created_at?: string;
}

export interface WorkerProfile {
  id: number;
  user_id: number;
  profile_id: number;
  full_name: string;
  location?: string;
  avatar_url?: string;
  bio?: string;
  phone?: string;
  title?: string;
  hourly_rate?: number;
  daily_rate?: number;
  skills: string;
  availability?: 'full-time' | 'part-time' | 'one-time';
  experience_years?: number;
  is_verified: number;
  total_jobs: number;
  avg_rating: number;
  portfolio?: PortfolioItem[];
  reviews?: Review[];
}

export interface PortfolioItem {
  id: number;
  worker_id: number;
  title: string;
  description?: string;
  image_url?: string;
  completed_date?: string;
}

export interface Job {
  id: number;
  client_id: number;
  client_name?: string;
  client_avatar?: string;
  title: string;
  description: string;
  category: string;
  location: string;
  budget_min?: number;
  budget_max?: number;
  job_type: 'one-time' | 'permanent';
  status: 'open' | 'in-progress' | 'completed' | 'cancelled';
  created_at: string;
  deadline?: string;
  application_count?: number;
}

export interface JobApplication {
  id: number;
  job_id: number;
  worker_id: number;
  worker_name?: string;
  worker_avatar?: string;
  worker_location?: string;
  worker_title?: string;
  avg_rating?: number;
  total_jobs?: number;
  cover_letter?: string;
  proposed_rate?: number;
  status: 'pending' | 'accepted' | 'rejected';
  created_at: string;
}

export interface Contract {
  id: number;
  job_id: number;
  worker_id: number;
  client_id: number;
  job_title?: string;
  job_category?: string;
  worker_name?: string;
  worker_avatar?: string;
  client_name?: string;
  client_avatar?: string;
  agreed_rate: number;
  contract_type: string;
  status: 'active' | 'completed' | 'cancelled';
  start_date: string;
  end_date?: string;
  commission_rate: number;
  platform_fee?: number;
  created_at: string;
}

export interface Review {
  id: number;
  contract_id: number;
  reviewer_id: number;
  reviewee_id: number;
  reviewer_name?: string;
  reviewer_avatar?: string;
  rating: number;
  comment?: string;
  created_at: string;
}

export interface AuthContextType {
  user: User | null;
  token: string | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (data: RegisterData) => Promise<void>;
  logout: () => void;
  updateUser: (data: Partial<User>) => void;
}

export interface RegisterData {
  email: string;
  password: string;
  role: 'worker' | 'client';
  full_name: string;
  phone?: string;
  location?: string;
}
