import { getAdminSession } from '@/lib/auth/admin-session';
import { redirect } from 'next/navigation';
import { AdminShell } from '@/components/layout/admin-shell';

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const admin = await getAdminSession();
  if (!admin) redirect('/admin-login');

  return (
    <AdminShell admin={admin}>{children}</AdminShell>
  );
}
