import { Router, Request, Response } from 'express';
import { body, validationResult } from 'express-validator';
import { authenticate, requireRole } from '../middleware/auth';
import db from '../database/db';

const router = Router();

// GET /api/jobs
router.get('/', (req: Request, res: Response): void => {
  const { category, location, job_type, status } = req.query;

  let query = `
    SELECT j.*, u.full_name as client_name, u.avatar_url as client_avatar
    FROM jobs j JOIN users u ON j.client_id = u.id
    WHERE 1=1
  `;
  const params: (string | number)[] = [];

  if (category) {
    query += ` AND LOWER(j.category) LIKE LOWER(?)`;
    params.push(`%${category}%`);
  }
  if (location) {
    query += ` AND LOWER(j.location) LIKE LOWER(?)`;
    params.push(`%${location}%`);
  }
  if (job_type) {
    query += ` AND j.job_type = ?`;
    params.push(job_type as string);
  }
  if (status) {
    query += ` AND j.status = ?`;
    params.push(status as string);
  } else {
    query += ` AND j.status = 'open'`;
  }

  query += ` ORDER BY j.created_at DESC`;

  const jobs = db.prepare(query).all(...params);
  res.json(jobs);
});

// POST /api/jobs
router.post(
  '/',
  authenticate,
  requireRole('client'),
  [
    body('title').trim().notEmpty(),
    body('description').trim().notEmpty(),
    body('category').trim().notEmpty(),
    body('location').trim().notEmpty(),
    body('job_type').isIn(['one-time', 'permanent']),
  ],
  (req: Request, res: Response): void => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      res.status(400).json({ errors: errors.array() });
      return;
    }

    const { title, description, category, location, budget_min, budget_max, job_type, deadline } =
      req.body;
    const clientId = req.user!.userId;

    const result = db
      .prepare(
        `INSERT INTO jobs (client_id, title, description, category, location, budget_min, budget_max, job_type, deadline)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
      )
      .run(
        clientId,
        title,
        description,
        category,
        location,
        budget_min || null,
        budget_max || null,
        job_type,
        deadline || null
      );

    const job = db.prepare('SELECT * FROM jobs WHERE id = ?').get(result.lastInsertRowid);
    res.status(201).json(job);
  }
);

// GET /api/jobs/:id
router.get('/:id', (req: Request, res: Response): void => {
  const job = db
    .prepare(
      `SELECT j.*, u.full_name as client_name, u.avatar_url as client_avatar
       FROM jobs j JOIN users u ON j.client_id = u.id
       WHERE j.id = ?`
    )
    .get(req.params.id) as any;

  if (!job) {
    res.status(404).json({ error: 'Job not found' });
    return;
  }

  const applicationCount = (
    db
      .prepare('SELECT COUNT(*) as count FROM job_applications WHERE job_id = ?')
      .get(req.params.id) as any
  ).count;

  res.json({ ...job, application_count: applicationCount });
});

// PUT /api/jobs/:id
router.put(
  '/:id',
  authenticate,
  requireRole('client'),
  (req: Request, res: Response): void => {
    const job = db.prepare('SELECT * FROM jobs WHERE id = ?').get(req.params.id) as any;

    if (!job) {
      res.status(404).json({ error: 'Job not found' });
      return;
    }
    if (job.client_id !== req.user!.userId) {
      res.status(403).json({ error: 'Not authorized' });
      return;
    }

    const { title, description, category, location, budget_min, budget_max, job_type, status, deadline } =
      req.body;

    db.prepare(
      `UPDATE jobs SET title=?, description=?, category=?, location=?,
       budget_min=?, budget_max=?, job_type=?, status=?, deadline=? WHERE id=?`
    ).run(
      title ?? job.title,
      description ?? job.description,
      category ?? job.category,
      location ?? job.location,
      budget_min ?? job.budget_min,
      budget_max ?? job.budget_max,
      job_type ?? job.job_type,
      status ?? job.status,
      deadline ?? job.deadline,
      req.params.id
    );

    const updated = db.prepare('SELECT * FROM jobs WHERE id = ?').get(req.params.id);
    res.json(updated);
  }
);

// DELETE /api/jobs/:id
router.delete('/:id', authenticate, requireRole('client'), (req: Request, res: Response): void => {
  const job = db.prepare('SELECT * FROM jobs WHERE id = ?').get(req.params.id) as any;

  if (!job) {
    res.status(404).json({ error: 'Job not found' });
    return;
  }
  if (job.client_id !== req.user!.userId) {
    res.status(403).json({ error: 'Not authorized' });
    return;
  }

  db.prepare('DELETE FROM jobs WHERE id = ?').run(req.params.id);
  res.json({ message: 'Job deleted' });
});

// POST /api/jobs/:id/apply
router.post(
  '/:id/apply',
  authenticate,
  requireRole('worker'),
  [body('cover_letter').optional().trim()],
  (req: Request, res: Response): void => {
    const job = db.prepare('SELECT * FROM jobs WHERE id = ?').get(req.params.id) as any;

    if (!job) {
      res.status(404).json({ error: 'Job not found' });
      return;
    }
    if (job.status !== 'open') {
      res.status(400).json({ error: 'Job is not open for applications' });
      return;
    }

    const { cover_letter, proposed_rate } = req.body;
    const workerId = req.user!.userId;

    try {
      const result = db
        .prepare(
          'INSERT INTO job_applications (job_id, worker_id, cover_letter, proposed_rate) VALUES (?, ?, ?, ?)'
        )
        .run(req.params.id, workerId, cover_letter || null, proposed_rate || null);

      const application = db
        .prepare('SELECT * FROM job_applications WHERE id = ?')
        .get(result.lastInsertRowid);

      res.status(201).json(application);
    } catch (err: any) {
      if (err.message?.includes('UNIQUE')) {
        res.status(409).json({ error: 'Already applied to this job' });
      } else {
        res.status(500).json({ error: 'Failed to apply' });
      }
    }
  }
);

// GET /api/jobs/:id/applications
router.get(
  '/:id/applications',
  authenticate,
  requireRole('client'),
  (req: Request, res: Response): void => {
    const job = db.prepare('SELECT * FROM jobs WHERE id = ?').get(req.params.id) as any;

    if (!job) {
      res.status(404).json({ error: 'Job not found' });
      return;
    }
    if (job.client_id !== req.user!.userId) {
      res.status(403).json({ error: 'Not authorized' });
      return;
    }

    const applications = db
      .prepare(
        `SELECT ja.*, u.full_name as worker_name, u.avatar_url as worker_avatar,
                u.location as worker_location,
                wp.title as worker_title, wp.avg_rating, wp.total_jobs
         FROM job_applications ja
         JOIN users u ON ja.worker_id = u.id
         LEFT JOIN worker_profiles wp ON u.id = wp.user_id
         WHERE ja.job_id = ?
         ORDER BY ja.created_at DESC`
      )
      .all(req.params.id);

    res.json(applications);
  }
);

// PUT /api/jobs/:id/applications/:appId
router.put(
  '/:id/applications/:appId',
  authenticate,
  requireRole('client'),
  (req: Request, res: Response): void => {
    const job = db.prepare('SELECT * FROM jobs WHERE id = ?').get(req.params.id) as any;

    if (!job) {
      res.status(404).json({ error: 'Job not found' });
      return;
    }
    if (job.client_id !== req.user!.userId) {
      res.status(403).json({ error: 'Not authorized' });
      return;
    }

    const { status } = req.body;
    if (!['accepted', 'rejected'].includes(status)) {
      res.status(400).json({ error: 'Status must be accepted or rejected' });
      return;
    }

    const app = db
      .prepare('SELECT * FROM job_applications WHERE id = ? AND job_id = ?')
      .get(req.params.appId, req.params.id) as any;

    if (!app) {
      res.status(404).json({ error: 'Application not found' });
      return;
    }

    db.prepare('UPDATE job_applications SET status = ? WHERE id = ?').run(
      status,
      req.params.appId
    );

    const updated = db
      .prepare('SELECT * FROM job_applications WHERE id = ?')
      .get(req.params.appId);

    res.json(updated);
  }
);

export default router;
