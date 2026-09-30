import { adminDb, adminAuth } from '@/lib/firebase/admin';

export class UsersService {
  /**
   * Fetch users combining Firebase Auth (source of truth for suspension) and Firestore (metadata).
   */
  static async getUsers(limit = 100) {
    const listUsersResult = await adminAuth.listUsers(limit);
    
    // Fetch only the users returned from auth to prevent downloading the whole collection
    const uids = listUsersResult.users.map(u => u.uid);
    let firestoreUsers = new Map();
    
    if (uids.length > 0) {
      // Chunk uids in batches of 30 for 'in' query limit
      const chunks = [];
      for (let i = 0; i < uids.length; i += 30) {
        chunks.push(uids.slice(i, i + 30));
      }
      
      const snapshots = await Promise.all(
        chunks.map(chunk => 
          adminDb.collection('users').where('uid', 'in', chunk).get()
        )
      );
      
      snapshots.forEach(snap => {
        snap.forEach(doc => {
          firestoreUsers.set(doc.id, doc.data());
        });
      });
    }

    return listUsersResult.users.map(userRecord => {
      const fsData = firestoreUsers.get(userRecord.uid) || {};
      return {
        uid: userRecord.uid,
        email: userRecord.email || '',
        displayName: userRecord.displayName || fsData.displayName || 'Unknown',
        role: fsData.role || 'client',
        disabled: userRecord.disabled,
        isActive: fsData.isActive ?? true,
        createdAt: userRecord.metadata.creationTime || (fsData.createdAt ? new Date(fsData.createdAt).toISOString() : new Date().toISOString()),
      };
    }).sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  }

  /**
   * Fetch workers specifically.
   */
  static async getWorkers(limit = 100) {
    let snapshot;
    try {
      snapshot = await adminDb.collection('users')
        .where('role', '==', 'worker')
        .orderBy('createdAt', 'desc')
        .limit(limit)
        .get();
    } catch (e: any) {
      // Fallback in case Firestore composite index is still building or missing
      snapshot = await adminDb.collection('users')
        .where('role', '==', 'worker')
        .limit(limit)
        .get();
    }

    return snapshot.docs.map(doc => {
      const data = doc.data();
      const profile = data.workerProfile || {};
      
      return {
        uid: doc.id,
        email: data.email || '',
        displayName: data.displayName || 'Unknown Worker',
        isActive: data.isActive ?? true,
        isVerified: profile.isVerified ?? false,
        skills: profile.skills || [],
        city: profile.city || data.city || 'Not specified',
        rating: data.rating || profile.averageRating || 0,
        completedJobs: profile.totalJobsCompleted || data.totalJobsCompleted || 0,
        createdAt: data.createdAt ? (data.createdAt.toDate ? data.createdAt.toDate().toISOString() : new Date(data.createdAt).toISOString()) : new Date().toISOString(),
      };
    }).sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  }

  /**
   * Updates worker verification status securely.
   */
  static async updateWorkerVerification(uid: string, isVerified: boolean, adminUid: string) {
    const userRef = adminDb.collection('users').doc(uid);
    const userDoc = await userRef.get();
    
    if (!userDoc.exists) throw new Error('User not found');
    if (userDoc.data()?.role !== 'worker') throw new Error('User is not a worker');

    // Worker profile is nested in Firestore
    await userRef.update({
      'workerProfile.isVerified': isVerified
    });

    // Write audit log
    await adminDb.collection('auditLogs').add({
      action: isVerified ? 'WORKER_VERIFIED' : 'WORKER_UNVERIFIED',
      adminId: adminUid,
      targetId: uid,
      timestamp: new Date(),
    });

    return true;
  }
}
