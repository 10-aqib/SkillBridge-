import { adminDb } from '@/lib/firebase/admin';

function toIsoDate(value: unknown): string {
  if (value && typeof value === 'object' && 'toDate' in value) {
    const date = (value as { toDate: () => Date }).toDate();
    return Number.isNaN(date.getTime()) ? '' : date.toISOString();
  }
  if (value instanceof Date) return value.toISOString();
  return '';
}

export class ReportsService {
  static async getQueueSummary() {
    const [open, investigating] = await Promise.all([
      adminDb.collection('reports').where('status', '==', 'open').count().get(),
      adminDb.collection('reports').where('status', '==', 'investigating').count().get(),
    ]);
    return { open: open.data().count, investigating: investigating.data().count };
  }

  static async getReports(limit = 100) {
    const snapshot = await adminDb.collection('reports')
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();

    const userIds = [...new Set(snapshot.docs.flatMap((doc) => {
      const data = doc.data();
      return [data.reporterId, data.targetUserId].filter(
        (id): id is string => typeof id === 'string' && id.length > 0,
      );
    }))];

    const userSnapshots = await Promise.all(
      userIds.map((uid) => adminDb.collection('users').doc(uid).get()),
    );
    const users = new Map(userSnapshots.map((user) => [
      user.id,
      user.data()?.displayName || user.data()?.name || 'Deleted or unnamed account',
    ]));

    return snapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        reporterId: typeof data.reporterId === 'string' ? data.reporterId : '',
        reporterName: users.get(data.reporterId) || 'Unknown reporter',
        targetUserId: typeof data.targetUserId === 'string' ? data.targetUserId : '',
        targetName: users.get(data.targetUserId) || 'Unknown account',
        targetType: typeof data.targetType === 'string' ? data.targetType : 'user',
        reason: typeof data.reason === 'string' ? data.reason : 'No reason supplied',
        status: typeof data.status === 'string' ? data.status : 'open',
        moderationNote: typeof data.moderationNote === 'string' ? data.moderationNote : '',
        createdAt: toIsoDate(data.createdAt),
      };
    });
  }
}
