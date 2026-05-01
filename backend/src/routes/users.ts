import { Router, Request, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { authenticate } from '../middleware/auth';
import db from '../database/db';

const router = Router();

// GET /api/users/me
router.get('/me', authenticate, (req: Request, res: Response): void => {
  const user = db
    .prepare('SELECT id, email, role, full_name, phone, location, avatar_url, bio, created_at FROM users WHERE id = ?')
    .get(req.user!.userId) as any;

  if (!user) {
    res.status(404).json({ error: 'User not found' });
    return;
  }
  res.json(user);
});

// PUT /api/users/me
router.put(
  '/me',
  authenticate,
  [
    body('full_name').optional().trim().notEmpty(),
    body('phone').optional().trim(),
    body('location').optional().trim(),
    body('bio').optional().trim(),
  ],
  (req: Request, res: Response): void => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const { full_name, phone, location, bio, avatar_url } = req.body;
    const userId = req.user!.userId;

    const current = db
      .prepare('SELECT * FROM users WHERE id = ?')
      .get(userId) as any;

    if (!current) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    db.prepare(
      'UPDATE users SET full_name = ?, phone = ?, location = ?, bio = ?, avatar_url = ? WHERE id = ?'
    ).run(
      full_name ?? current.full_name,
      phone ?? current.phone,
      location ?? current.location,
      bio ?? current.bio,
      avatar_url ?? current.avatar_url,
      userId
    );

    const updated = db
      .prepare('SELECT id, email, role, full_name, phone, location, avatar_url, bio, created_at FROM users WHERE id = ?')
      .get(userId);

    res.json(updated);
  }
);

// GET /api/users/:id
router.get('/:id', (req: Request, res: Response): void => {
  const user = db
    .prepare('SELECT id, email, role, full_name, phone, location, avatar_url, bio, created_at FROM users WHERE id = ?')
    .get(req.params.id) as any;

  if (!user) {
    res.status(404).json({ error: 'User not found' });
    return;
  }
  res.json(user);
});

export default router;
