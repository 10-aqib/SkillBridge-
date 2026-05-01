CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK(role IN ('worker', 'client')),
  full_name TEXT NOT NULL,
  phone TEXT,
  location TEXT,
  avatar_url TEXT,
  bio TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS worker_profiles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER UNIQUE NOT NULL,
  title TEXT,
  hourly_rate REAL,
  daily_rate REAL,
  skills TEXT DEFAULT '[]',
  availability TEXT CHECK(availability IN ('full-time', 'part-time', 'one-time')),
  experience_years INTEGER,
  is_verified INTEGER DEFAULT 0,
  total_jobs INTEGER DEFAULT 0,
  avg_rating REAL DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS portfolio_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  worker_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  completed_date TEXT,
  FOREIGN KEY (worker_id) REFERENCES worker_profiles(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS jobs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  client_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  location TEXT NOT NULL,
  budget_min REAL,
  budget_max REAL,
  job_type TEXT NOT NULL CHECK(job_type IN ('one-time', 'permanent')),
  status TEXT NOT NULL DEFAULT 'open' CHECK(status IN ('open', 'in-progress', 'completed', 'cancelled')),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  deadline TEXT,
  FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS job_applications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  job_id INTEGER NOT NULL,
  worker_id INTEGER NOT NULL,
  cover_letter TEXT,
  proposed_rate REAL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending', 'accepted', 'rejected')),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(job_id, worker_id),
  FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE,
  FOREIGN KEY (worker_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS contracts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  job_id INTEGER NOT NULL,
  worker_id INTEGER NOT NULL,
  client_id INTEGER NOT NULL,
  agreed_rate REAL NOT NULL,
  contract_type TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'completed', 'cancelled')),
  start_date TEXT NOT NULL,
  end_date TEXT,
  commission_rate REAL DEFAULT 10,
  platform_fee REAL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (job_id) REFERENCES jobs(id),
  FOREIGN KEY (worker_id) REFERENCES users(id),
  FOREIGN KEY (client_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS reviews (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  contract_id INTEGER NOT NULL,
  reviewer_id INTEGER NOT NULL,
  reviewee_id INTEGER NOT NULL,
  rating INTEGER NOT NULL CHECK(rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(contract_id, reviewer_id),
  FOREIGN KEY (contract_id) REFERENCES contracts(id),
  FOREIGN KEY (reviewer_id) REFERENCES users(id),
  FOREIGN KEY (reviewee_id) REFERENCES users(id)
);
