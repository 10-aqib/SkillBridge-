import { adminDb } from '@/lib/firebase/admin';

export interface CityMetric {
  city: string;
  count: number;
  percentage: number;
}

export interface CategoryMetric {
  name: string;
  value: number;
  color: string;
}

export interface RecentJobActivity {
  id: string;
  title: string;
  clientName: string;
  workerName: string;
  timeStr: string;
  status: string;
  budget: number | null;
}

export class AnalyticsService {
  /**
   * Fetch high level counts for the dashboard overview cards.
   */
  static async getOverviewStats() {
    try {
      const [
        totalUsersSnap,
        totalWorkersSnap,
        totalCustomersSnap,
        totalJobsSnap,
        activeJobsSnap,
        completedJobsSnap
      ] = await Promise.all([
        adminDb.collection('users').count().get(),
        adminDb.collection('users').where('role', '==', 'worker').count().get(),
        adminDb.collection('users').where('role', '==', 'client').count().get(),
        adminDb.collection('jobs').count().get(),
        adminDb.collection('jobs').where('status', 'in', ['open', 'assigned', 'in_progress']).count().get(),
        adminDb.collection('jobs').where('status', '==', 'completed').count().get(),
      ]);

      const totalUsers = totalUsersSnap.data().count;
      const totalWorkers = totalWorkersSnap.data().count;
      const totalCustomers = totalCustomersSnap.data().count;
      const totalJobs = totalJobsSnap.data().count;
      const activeJobs = activeJobsSnap.data().count;
      const completedJobs = completedJobsSnap.data().count;

      return {
        totalUsers,
        totalWorkers,
        totalCustomers,
        totalJobs,
        activeJobs,
        completedJobs,
      };
    } catch (error) {
      console.error('Error fetching overview counts:', error);
      return {
        totalUsers: 0,
        totalWorkers: 0,
        totalCustomers: 0,
        totalJobs: 0,
        activeJobs: 0,
        completedJobs: 0,
      };
    }
  }

  /**
   * Calculate completed contract value from Firestore records.
   */
  static async getFinancialMetrics(days = 365) {
    try {
      const startDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
      const contractsSnap = await adminDb.collection('contracts')
        .where('status', '==', 'completed')
        .where('completedAt', '>=', startDate)
        .get();

      let totalVolume = 0;
      contractsSnap.forEach(doc => {
        const data = doc.data();
        totalVolume += Number(data.totalAmount || 0);
      });

      return {
        totalVolume,
        avgOrderValue: contractsSnap.size > 0 ? Math.round(totalVolume / contractsSnap.size) : 0,
      };
    } catch (e) {
      console.error('Error fetching completed contract metrics:', e);
      return {
        totalVolume: 0,
        avgOrderValue: 0,
      };
    }
  }

  /**
   * Fetch recent users created in the last N days for the Activity Bar Chart.
   */
  static async getUserGrowth(days: number = 7) {
    try {
      const now = new Date();
      const startDate = new Date(now.getTime() - days * 24 * 60 * 60 * 1000);

      const snapshot = await adminDb.collection('users')
        .where('createdAt', '>=', startDate)
        .get();

      const hourly = days <= 1;
      const monthly = days > 31;
      const bucketDates: Date[] = [];
      if (hourly) {
        for (let offset = 23; offset >= 0; offset--) {
          const bucket = new Date(now);
          bucket.setMinutes(0, 0, 0);
          bucket.setHours(bucket.getHours() - offset);
          bucketDates.push(bucket);
        }
      } else if (monthly) {
        for (let offset = 11; offset >= 0; offset--) {
          bucketDates.push(new Date(now.getFullYear(), now.getMonth() - offset, 1));
        }
      } else {
        for (let offset = days - 1; offset >= 0; offset--) {
          const bucket = new Date(now);
          bucket.setHours(0, 0, 0, 0);
          bucket.setDate(bucket.getDate() - offset);
          bucketDates.push(bucket);
        }
      }

      const bucketKey = (date: Date) => hourly
        ? `${date.getFullYear()}-${date.getMonth()}-${date.getDate()}-${date.getHours()}`
        : monthly
          ? `${date.getFullYear()}-${date.getMonth()}`
          : `${date.getFullYear()}-${date.getMonth()}-${date.getDate()}`;
      const countsByDate = new Map(bucketDates.map((date) => [bucketKey(date), 0]));

      snapshot.forEach(doc => {
        const data = doc.data();
        if (data.createdAt) {
          const date = data.createdAt.toDate ? data.createdAt.toDate() : new Date(data.createdAt);
          const key = bucketKey(date);
          if (countsByDate.has(key)) countsByDate.set(key, (countsByDate.get(key) || 0) + 1);
        }
      });

      return bucketDates.map((date) => ({
        date: hourly
          ? date.toLocaleTimeString([], { hour: 'numeric' })
          : monthly
            ? date.toLocaleDateString([], { month: 'short' })
            : date.toLocaleDateString([], { month: 'short', day: 'numeric' }),
        users: countsByDate.get(bucketKey(date)) || 0,
      }));
    } catch (e) {
      console.error('Error fetching user growth:', e);
      return [];
    }
  }

  /**
   * Fetch live regional user distribution for Pakistan cities (Islamabad, Rawalpindi, etc.)
   */
  static async getCityBreakdown(): Promise<CityMetric[]> {
    try {
      const usersSnap = await adminDb.collection("users").get();
      const cityCounts: Record<string, number> = {};

      usersSnap.forEach(doc => {
        const data = doc.data();
        const city = data.city || data.workerProfile?.city;
        if (typeof city === "string" && city.trim()) {
          const name = city.trim();
          cityCounts[name] = (cityCounts[name] || 0) + 1;
        }
      });

      const total = Object.values(cityCounts).reduce((sum, count) => sum + count, 0);
      return Object.entries(cityCounts)
        .map(([city, count]) => ({ city, count, percentage: total > 0 ? Math.round((count / total) * 100) : 0 }))
        .sort((a, b) => b.count - a.count);
    } catch (error) {
      console.error("Error fetching city distribution:", error);
      return [];
    }
  }

  /**
   * Fetch category distribution for Donut Chart.
   */
  static async getCategoryBreakdown(): Promise<CategoryMetric[]> {
    try {
      const jobsSnap = await adminDb.collection("jobs").get();
      const catCounts: Record<string, number> = {};

      jobsSnap.forEach(doc => {
        const category = doc.data().categoryName;
        if (typeof category === "string" && category.trim()) {
          const name = category.trim();
          catCounts[name] = (catCounts[name] || 0) + 1;
        }
      });

      // Theme-aware chart tokens (resolve in light and dark).
      const colors = ["var(--sb-chart-1)", "var(--sb-chart-3)", "var(--sb-chart-2)", "var(--sb-chart-5)", "var(--sb-chart-4)"];
      return Object.entries(catCounts).slice(0, 5).map(([name, value], index) => ({
        name,
        value,
        color: colors[index % colors.length],
      }));
    } catch (error) {
      console.error("Error fetching category distribution:", error);
      return [];
    }
  }

  /**
   * Fetch recent live job/contract activities for the status cards.
   */
  static async getRecentJobActivities(): Promise<RecentJobActivity[]> {
    try {
      const snapshot = await adminDb.collection('jobs')
        .orderBy('createdAt', 'desc')
        .limit(3)
        .get();

      return snapshot.docs.map(doc => {
        const data = doc.data();
        const rawBudget = Number(data.budgetMax ?? data.budgetMin ?? data.budget);
        const createdAt = data.createdAt?.toDate
          ? data.createdAt.toDate()
          : data.createdAt ? new Date(data.createdAt) : null;

        return {
          id: doc.id,
          title: data.title || 'Untitled service request',
          clientName: data.clientName || 'Not recorded',
          workerName: data.workerName || (data.workerId ? 'Assigned worker' : 'Not assigned'),
          timeStr: createdAt && !Number.isNaN(createdAt.getTime())
            ? createdAt.toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' })
            : 'Time not recorded',
          status: data.status ? String(data.status).toUpperCase() : 'Status not recorded',
          budget: Number.isFinite(rawBudget) ? rawBudget : null,
        };
      });
    } catch (error) {
      console.error('Error fetching recent job activities:', error);
      return [];
    }
  }
}
