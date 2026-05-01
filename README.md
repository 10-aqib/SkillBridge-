# SkillBridge 🔧⚡

A digital platform connecting local skilled workers (electricians, plumbers, carpenters, painters, home tutors, tradespeople) with clients — similar to LinkedIn/Indeed but built for the local and informal labor market.

## Features

### For Workers
- Create a professional profile with skills, rates, and portfolio
- Browse and apply to job postings
- Manage contracts and track earnings
- Receive ratings and reviews from clients

### For Clients
- Post job listings with budget and requirements
- Search and filter workers by skill, location, and availability
- Review applications and hire workers
- Create and manage contracts

### Platform
- JWT-based authentication (worker & client roles)
- Real-time worker search with advanced filters
- Contract management with platform fee calculation (10%)
- Review and rating system
- Responsive, mobile-first design

## Tech Stack

| Layer     | Technology                                         |
|-----------|----------------------------------------------------|
| Backend   | Node.js, Express, TypeScript, SQLite (better-sqlite3) |
| Frontend  | React, TypeScript, Vite, Tailwind CSS              |
| Auth      | JWT (jsonwebtoken), bcryptjs                       |
| Validation| express-validator, zod, react-hook-form            |
| UI        | lucide-react, react-hot-toast, date-fns, clsx      |

## Project Structure

```
SkillBridge/
├── backend/               # Express + TypeScript API
│   ├── src/
│   │   ├── database/      # SQLite schema + db connection
│   │   ├── middleware/    # Auth middleware, error handler
│   │   ├── routes/        # API route handlers
│   │   ├── types/         # TypeScript interfaces
│   │   └── index.ts       # Entry point
│   └── .env.example
├── frontend/              # React + TypeScript + Tailwind
│   └── src/
│       ├── components/    # Reusable UI components
│       ├── context/       # AuthContext
│       ├── hooks/         # useAuth hook
│       ├── pages/         # All page components
│       ├── types/         # TypeScript types
│       └── utils/         # Axios API instance
├── package.json           # Root scripts
└── .gitignore
```

## Getting Started

### Prerequisites
- Node.js 18+
- npm 9+

### Installation

```bash
# Clone the repository
git clone https://github.com/10-aqib/SkillBridge-
cd SkillBridge-

# Install all dependencies
npm run install:all
```

### Configuration

```bash
# Backend: copy .env.example and configure
cp backend/.env.example backend/.env
# Edit backend/.env and set a strong JWT_SECRET
```

### Running in Development

```bash
# Start backend (port 5000)
npm run dev:backend

# Start frontend (port 5173) in another terminal
npm run dev:frontend
```

### Building for Production

```bash
npm run build:backend
npm run build:frontend
```

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register a new user |
| POST | `/api/auth/login` | Login and receive JWT |
| GET | `/api/workers` | Search workers with filters |
| GET | `/api/workers/:id` | Get worker profile |
| PUT | `/api/workers/profile` | Update worker profile |
| GET | `/api/jobs` | List open jobs |
| POST | `/api/jobs` | Post a new job |
| POST | `/api/jobs/:id/apply` | Apply to a job |
| GET | `/api/contracts` | List user's contracts |
| POST | `/api/contracts` | Create a contract |
| PUT | `/api/contracts/:id/complete` | Mark contract complete |
| POST | `/api/reviews` | Submit a review |

## Database Schema

- **users** — accounts for workers and clients
- **worker_profiles** — worker-specific details (skills, rates, availability)
- **portfolio_items** — work examples for worker profiles
- **jobs** — job postings by clients
- **job_applications** — worker applications to jobs
- **contracts** — agreements between worker and client
- **reviews** — post-contract ratings and feedback

## License

MIT
