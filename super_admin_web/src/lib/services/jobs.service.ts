import { adminDb } from '@/lib/firebase/admin';

export class JobsService {
  /**
   * Fetch jobs from Firestore with basic pagination/limiting.
   */
  static async getJobs(limit = 100) {
    const snapshot = await adminDb.collection('jobs')
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();

    return snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        title: data.title || 'Untitled',
        clientName: data.clientName || 'Unknown Client',
        categoryName: data.categoryName || 'Uncategorized',
        city: data.city || 'Unknown',
        budgetMin: data.budgetMin || 0,
        budgetMax: data.budgetMax || 0,
        status: data.status || 'open',
        totalProposals: data.totalProposals || 0,
        createdAt: data.createdAt ? (data.createdAt.toDate ? data.createdAt.toDate().toISOString() : new Date(data.createdAt).toISOString()) : new Date().toISOString(),
      };
    });
  }
}
