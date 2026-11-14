import { SettingsClient } from './SettingsClient';
import { getAdminSession } from '@/lib/auth/admin-session';

export const dynamic = 'force-dynamic';

export default async function SettingsPage() {
  const admin = await getAdminSession();
  if (!admin) return null;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl lg:text-3xl font-extrabold text-sb-text tracking-tight">
            Account & Security
          </h1>
          <p className="text-xs text-sb-text-secondary mt-0.5">
            Manage your administrator account and Firebase sign-in security.
          </p>
        </div>

      </div>

      <SettingsClient email={admin.email} uid={admin.uid} role={admin.role} />
    </div>
  );
}
