import { Router, Request, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { authenticate, requireRole } from '../middleware/auth';
import db from '../database/db';

const router = Router();

// GET /api/workers
router.get('/', (req: Request, res: Response): void => {
  const { skill, location, category, min_rate, max_rate, availability } = req.query;

  let query = `
    SELECT u.id, u.full_name, u.location, u.avatar_url, u.bio,
           wp.id as profile_id, wp.title, wp.hourly_rate, wp.daily_rate,
           wp.skills, wp.availability, wp.experience_years,
           wp.is_verified, wp.total_jobs, wp.avg_rating
    FROM users u
    JOIN worker_profiles wp ON u.id = wp.user_id
    WHERE u.role = 'worker'
  `;
  const params: (string | number)[] = [];

  if (location) {
    query += ` AND LOWER(u.location) LIKE LOWER(?)`;
    params.push(`%${location}%`);
  }
  if (availability) {
    query += ` AND wp.availability = ?`;
    params.push(availability as string);
  }
  if (min_rate) {
    query += ` AND wp.hourly_rate >= ?`;
    params.push(Number(min_rate));
  }
  if (max_rate) {
    query += ` AND wp.hourly_rate <= ?`;
    params.push(Number(max_rate));
  }

  const workers = db.prepare(query).all(...params) as any[];

  let filtered = workers;
  if (skill || category) {
    const term = ((skill || category) as string).toLowerCase();
    filtered = workers.filter((w) => {
      try {
        const skills: string[] = JSON.parse(w.skills || '[]');
        return (
          skills.some((s) => s.toLowerCase().includes(term)) ||
          (w.title && w.title.toLowerCase().includes(term))
        );
      } catch {
        return false;
      }
    });
  }

  res.json(filtered);
});

// GET /api/workers/:id
router.get('/:id', (req: Request, res: Response): void => {
  const user = db
    .prepare(
      `SELECT u.id, u.full_name, u.location, u.avatar_url, u.bio, u.phone, u.created_at,
              wp.id as profile_id, wp.title, wp.hourly_rate, wp.daily_rate,
              wp.skills, wp.availability, wp.experience_years,
              wp.is_verified, wp.total_jobs, wp.avg_rating
       FROM users u
       JOIN worker_profiles wp ON u.id = wp.user_id
       WHERE u.id = ? AND u.role = 'worker'`
    )
    .get(req.params.id) as any;

  if (!user) {
    res.status(404).json({ error: 'Worker not found' });
    return;
  }

  const portfolio = db
    .prepare('SELECT * FROM portfolio_items WHERE worker_id = ?')
    .all(user.profile_id);

  const reviews = db
    .prepare(
      `SELECT r.*, u.full_name as reviewer_name, u.avatar_url as reviewer_avatar
       FROM reviews r JOIN users u ON r.reviewer_id = u.id
       WHERE r.reviewee_id = ? ORDER BY r.created_at DESC`
    )
    .all(req.params.id);

  res.json({ ...user, portfolio, reviews });
});

// PUT /api/workers/profile
router.put(
  '/profile',
  authenticate,
  requireRole('worker'),
  [
    body('title').optional().trim(),
    body('hourly_rate').optional().isNumeric(),
    body('daily_rate').optional().isNumeric(),
    body('skills').optional().isArray(),
    body('availability').optional().isIn(['full-time', 'part-time', 'one-time']),
    body('experience_years').optional().isInt({ min: 0 }),
  ],
  (req: Request, res: Response): void => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const userId = req.user!.userId;
    const { title, hourly_rate, daily_rate, skills, availability, experience_years } = req.body;

    const profile = db
      .prepare('SELECT * FROM worker_profiles WHERE user_id = ?')
      .get(userId) as any;

    if (!profile) {
      res.status(404).json({ error: 'Worker profile not found' });
      return;
    }

    db.prepare(
      `UPDATE worker_profiles SET
        title = ?, hourly_rate = ?, daily_rate = ?,
        skills = ?, availability = ?, experience_years = ?
       WHERE user_id = ?`
    ).run(
      title ?? profile.title,
      hourly_rate ?? profile.hourly_rate,
      daily_rate ?? profile.daily_rate,
      skills ? JSON.stringify(skills) : profile.skills,
      availability ?? profile.availability,
      experience_years ?? profile.experience_years,
      userId
    );

    const updated = db
      .prepare('SELECT * FROM worker_profiles WHERE user_id = ?')
      .get(userId);

    res.json(updated);
  }
);

// POST /api/workers/portfolio
router.post(
  '/portfolio',
  authenticate,
  requireRole('worker'),
  [body('title').trim().notEmpty()],
  (req: Request, res: Response): void => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const userId = req.user!.userId;
    const { title, description, image_url, completed_date } = req.body;

    const profile = db
      .prepare('SELECT id FROM worker_profiles WHERE user_id = ?')
      .get(userId) as any;

    if (!profile) {
      res.status(404).json({ error: 'Worker profile not found' });
      return;
    }

    const result = db
      .prepare(
        'INSERT INTO portfolio_items (worker_id, title, description, image_url, completed_date) VALUES (?, ?, ?, ?, ?)'
      )
      .run(profile.id, title, description || null, image_url || null, completed_date || null);

    const item = db
      .prepare('SELECT * FROM portfolio_items WHERE id = ?')
      .get(result.lastInsertRowid);

    res.status(201).json(item);
  }
);

// DELETE /api/workers/portfolio/:itemId
router.delete(
  '/portfolio/:itemId',
  authenticate,
  requireRole('worker'),
  (req: Request, res: Response): void => {
    const userId = req.user!.userId;

    const profile = db
      .prepare('SELECT id FROM worker_profiles WHERE user_id = ?')
      .get(userId) as any;

    if (!profile) {
      res.status(404).json({ error: 'Worker profile not found' });
      return;
    }

    const item = db
      .prepare('SELECT * FROM portfolio_items WHERE id = ? AND worker_id = ?')
      .get(req.params.itemId, profile.id);

    if (!item) {
      res.status(404).json({ error: 'Portfolio item not found' });
      return;
    }

    db.prepare('DELETE FROM portfolio_items WHERE id = ?').run(req.params.itemId);
    res.json({ message: 'Portfolio item deleted' });
  }
);

export default router;
