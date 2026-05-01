import { Router, Request, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { authenticate, requireRole } from '../middleware/auth';
import db from '../database/db';

const router = Router();

// GET /api/contracts
router.get('/', authenticate, (req: Request, res: Response): void => {
  const userId = req.user!.userId;
  const role = req.user!.role;

  const field = role === 'worker' ? 'c.worker_id' : 'c.client_id';

  const contracts = db
    .prepare(
      `SELECT c.*,
              j.title as job_title, j.category as job_category,
              w.full_name as worker_name, w.avatar_url as worker_avatar,
              cl.full_name as client_name, cl.avatar_url as client_avatar
       FROM contracts c
       JOIN jobs j ON c.job_id = j.id
       JOIN users w ON c.worker_id = w.id
       JOIN users cl ON c.client_id = cl.id
       WHERE ${field} = ?
       ORDER BY c.created_at DESC`
    )
    .all(userId);

  res.json(contracts);
});

// POST /api/contracts
router.post(
  '/',
  authenticate,
  requireRole('client'),
  [
    body('job_id').isInt(),
    body('worker_id').isInt(),
    body('agreed_rate').isNumeric(),
    body('contract_type').trim().notEmpty(),
    body('start_date').notEmpty(),
  ],
  (req: Request, res: Response): void => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const { job_id, worker_id, agreed_rate, contract_type, start_date, end_date } = req.body;
    const clientId = req.user!.userId;

    const job = db.prepare('SELECT * FROM jobs WHERE id = ?').get(job_id) as any;
    if (!job) {
      res.status(404).json({ error: 'Job not found' });
      return;
    }
    if (job.client_id !== clientId) {
      res.status(403).json({ error: 'Not authorized' });
      return;
    }

    const commission_rate = 10;
    const platform_fee = (agreed_rate * commission_rate) / 100;

    const result = db
      .prepare(
        `INSERT INTO contracts (job_id, worker_id, client_id, agreed_rate, contract_type, start_date, end_date, commission_rate, platform_fee)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
      )
      .run(
        job_id,
        worker_id,
        clientId,
        agreed_rate,
        contract_type,
        start_date,
        end_date || null,
        commission_rate,
        platform_fee
      );

    db.prepare("UPDATE jobs SET status = 'in-progress' WHERE id = ?").run(job_id);

    const contract = db
      .prepare('SELECT * FROM contracts WHERE id = ?')
      .get(result.lastInsertRowid);

    res.status(201).json(contract);
  }
);

// GET /api/contracts/:id
router.get('/:id', authenticate, (req: Request, res: Response): void => {
  const userId = req.user!.userId;

  const contract = db
    .prepare(
      `SELECT c.*,
              j.title as job_title, j.description as job_description, j.category as job_category,
              w.full_name as worker_name, w.avatar_url as worker_avatar, w.phone as worker_phone,
              cl.full_name as client_name, cl.avatar_url as client_avatar, cl.phone as client_phone
       FROM contracts c
       JOIN jobs j ON c.job_id = j.id
       JOIN users w ON c.worker_id = w.id
       JOIN users cl ON c.client_id = cl.id
       WHERE c.id = ?`
    )
    .get(req.params.id) as any;

  if (!contract) {
    res.status(404).json({ error: 'Contract not found' });
    return;
  }
  if (contract.worker_id !== userId && contract.client_id !== userId) {
    res.status(403).json({ error: 'Not authorized' });
    return;
  }

  res.json(contract);
});

// PUT /api/contracts/:id/complete
router.put('/:id/complete', authenticate, (req: Request, res: Response): void => {
  const userId = req.user!.userId;

  const contract = db
    .prepare('SELECT * FROM contracts WHERE id = ?')
    .get(req.params.id) as any;

  if (!contract) {
    res.status(404).json({ error: 'Contract not found' });
    return;
  }
  if (contract.worker_id !== userId && contract.client_id !== userId) {
    res.status(403).json({ error: 'Not authorized' });
    return;
  }
  if (contract.status !== 'active') {
    res.status(400).json({ error: 'Contract is not active' });
    return;
  }

  const now = new Date().toISOString().split('T')[0];
  db.prepare("UPDATE contracts SET status = 'completed', end_date = ? WHERE id = ?").run(
    now,
    req.params.id
  );
  db.prepare("UPDATE jobs SET status = 'completed' WHERE id = ?").run(contract.job_id);
  db.prepare(
    'UPDATE worker_profiles SET total_jobs = total_jobs + 1 WHERE user_id = ?'
  ).run(contract.worker_id);

  const updated = db.prepare('SELECT * FROM contracts WHERE id = ?').get(req.params.id);
  res.json(updated);
});

// PUT /api/contracts/:id/cancel
router.put('/:id/cancel', authenticate, (req: Request, res: Response): void => {
  const userId = req.user!.userId;

  const contract = db
    .prepare('SELECT * FROM contracts WHERE id = ?')
    .get(req.params.id) as any;

  if (!contract) {
    res.status(404).json({ error: 'Contract not found' });
    return;
  }
  if (contract.worker_id !== userId && contract.client_id !== userId) {
    res.status(403).json({ error: 'Not authorized' });
    return;
  }
  if (contract.status !== 'active') {
    res.status(400).json({ error: 'Contract is not active' });
    return;
  }

  db.prepare("UPDATE contracts SET status = 'cancelled' WHERE id = ?").run(req.params.id);
  db.prepare("UPDATE jobs SET status = 'cancelled' WHERE id = ?").run(contract.job_id);

  const updated = db.prepare('SELECT * FROM contracts WHERE id = ?').get(req.params.id);
  res.json(updated);
});

export default router;
