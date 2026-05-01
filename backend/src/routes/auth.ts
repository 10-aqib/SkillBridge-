import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { body, validationResult } from 'express-validator';
import db from '../database/db';

const router = Router();
const JWT_SECRET = process.env.JWT_SECRET || 'skillbridge_secret_key';

// POST /api/auth/register
router.post(
  '/register',
  [
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 6 }),
    body('role').isIn(['worker', 'client']),
    body('full_name').trim().notEmpty(),
  ],
  async (req: Request, res: Response): Promise<void> => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const { email, password, role, full_name, phone, location } = req.body;

    try {
      const existingUser = db.prepare('SELECT id FROM users WHERE email = ?').get(email);
      if (existingUser) {
        res.status(409).json({ error: 'Email already registered' });
        return;
      }

      const password_hash = await bcrypt.hash(password, 12);
      const result = db
        .prepare(
          'INSERT INTO users (email, password_hash, role, full_name, phone, location) VALUES (?, ?, ?, ?, ?, ?)'
        )
        .run(email, password_hash, role, full_name, phone || null, location || null);

      const userId = result.lastInsertRowid as number;

      if (role === 'worker') {
        db.prepare('INSERT INTO worker_profiles (user_id) VALUES (?)').run(userId);
      }

      const token = jwt.sign({ userId, role }, JWT_SECRET, { expiresIn: '7d' });

      res.status(201).json({
        token,
        user: { id: userId, email, role, full_name },
      });
    } catch (err) {
      res.status(500).json({ error: 'Registration failed' });
    }
  }
);

// POST /api/auth/login
router.post(
  '/login',
  [body('email').isEmail().normalizeEmail(), body('password').notEmpty()],
  async (req: Request, res: Response): Promise<void> => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const { email, password } = req.body;

    try {
      const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email) as any;
      if (!user) {
        res.status(401).json({ error: 'Invalid credentials' });
        return;
      }

      const valid = await bcrypt.compare(password, user.password_hash);
      if (!valid) {
        res.status(401).json({ error: 'Invalid credentials' });
        return;
      }

      const token = jwt.sign({ userId: user.id, role: user.role }, JWT_SECRET, {
        expiresIn: '7d',
      });

      res.json({
        token,
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          full_name: user.full_name,
          avatar_url: user.avatar_url,
        },
      });
    } catch {
      res.status(500).json({ error: 'Login failed' });
    }
  }
);

export default router;
