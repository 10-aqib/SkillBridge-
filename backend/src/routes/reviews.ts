import { Router, Request, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { authenticate } from '../middleware/auth';
import db from '../database/db';

const router = Router();

// POST /api/reviews
router.post(
  '/',
  authenticate,
  [
    body('contract_id').isInt(),
    body('reviewee_id').isInt(),
    body('rating').isInt({ min: 1, max: 5 }),
    body('comment').optional().trim(),
  ],
  (req: Request, res: Response): void => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const { contract_id, reviewee_id, rating, comment } = req.body;
    const reviewerId = req.user!.userId;

    const contract = db
      .prepare('SELECT * FROM contracts WHERE id = ?')
      .get(contract_id) as any;

    if (!contract) {
      res.status(404).json({ error: 'Contract not found' });
      return;
    }
    if (contract.status !== 'completed') {
      res.status(400).json({ error: 'Can only review completed contracts' });
      return;
    }
    if (contract.worker_id !== reviewerId && contract.client_id !== reviewerId) {
      res.status(403).json({ error: 'Not authorized to review this contract' });
      return;
    }
    if (reviewerId === reviewee_id) {
      res.status(400).json({ error: 'Cannot review yourself' });
      return;
    }

    try {
      const result = db
        .prepare(
          'INSERT INTO reviews (contract_id, reviewer_id, reviewee_id, rating, comment) VALUES (?, ?, ?, ?, ?)'
        )
        .run(contract_id, reviewerId, reviewee_id, rating, comment || null);

      // Update worker's avg rating if reviewee is a worker
      const reviewee = db.prepare('SELECT role FROM users WHERE id = ?').get(reviewee_id) as any;
      if (reviewee?.role === 'worker') {
        const avgResult = db
          .prepare('SELECT AVG(rating) as avg FROM reviews WHERE reviewee_id = ?')
          .get(reviewee_id) as any;
        db.prepare('UPDATE worker_profiles SET avg_rating = ? WHERE user_id = ?').run(
          avgResult.avg,
          reviewee_id
        );
      }

      const review = db.prepare('SELECT * FROM reviews WHERE id = ?').get(result.lastInsertRowid);
      res.status(201).json(review);
    } catch (err: any) {
      if (err.message?.includes('UNIQUE')) {
        res.status(409).json({ error: 'Already reviewed this contract' });
      } else {
        res.status(500).json({ error: 'Failed to create review' });
      }
    }
  }
);

// GET /api/reviews/worker/:workerId
router.get('/worker/:workerId', (req: Request, res: Response): void => {
  const reviews = db
    .prepare(
      `SELECT r.*, u.full_name as reviewer_name, u.avatar_url as reviewer_avatar
       FROM reviews r JOIN users u ON r.reviewer_id = u.id
       WHERE r.reviewee_id = ?
       ORDER BY r.created_at DESC`
    )
    .all(req.params.workerId);

  res.json(reviews);
});

// GET /api/reviews/client/:clientId
router.get('/client/:clientId', (req: Request, res: Response): void => {
  const reviews = db
    .prepare(
      `SELECT r.*, u.full_name as reviewer_name, u.avatar_url as reviewer_avatar
       FROM reviews r JOIN users u ON r.reviewer_id = u.id
       WHERE r.reviewee_id = ?
       ORDER BY r.created_at DESC`
    )
    .all(req.params.clientId);

  res.json(reviews);
});

export default router;
