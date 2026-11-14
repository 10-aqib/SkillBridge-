'use client';

import { useState } from 'react';
import { sendPasswordResetEmail } from 'firebase/auth';
import { auth } from '@/lib/firebase/client';
import { CheckCircle2, KeyRound, ShieldCheck } from 'lucide-react';

export function SettingsClient({
  email,
  uid,
  role,
}: {
  email: string;
  uid: string;
  role: string;
}) {
  const [isSending, setIsSending] = useState(false);
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  async function requestPasswordReset() {
    if (!email) {
      setError('A verified email is not available for this administrator account.');
      return;
    }
    setIsSending(true);
    setMessage('');
    setError('');
    try {
      await sendPasswordResetEmail(auth, email);
      setMessage(`Password reset instructions were sent to ${email}.`);
    } catch (cause) {
      console.error('Password reset request failed:', cause);
      setError('Could not send the reset email. Check the account email and try again.');
    } finally {
      setIsSending(false);
    }
  }

  return (
    <div className="mx-auto max-w-4xl space-y-6">
      <section className="rounded-2xl border border-sb-border bg-sb-surface p-5 shadow-sm sm:p-7">
        <div className="flex items-start gap-4">
          <span className="rounded-xl bg-sb-primary-subtle p-3 text-sb-primary"><ShieldCheck className="h-5 w-5" /></span>
          <div>
            <h2 className="text-base font-semibold text-sb-text">Administrator account</h2>
            <p className="mt-1 text-sm text-sb-text-secondary">Identity and permissions verified from your Firebase session.</p>
          </div>
        </div>

        <dl className="mt-6 grid gap-4 border-t border-sb-border pt-5 sm:grid-cols-2">
          <div>
            <dt className="text-xs font-medium uppercase tracking-wide text-sb-text-secondary">Email</dt>
            <dd className="mt-1 break-all text-sm font-medium text-sb-text">{email || 'No email on this account'}</dd>
          </div>
          <div>
            <dt className="text-xs font-medium uppercase tracking-wide text-sb-text-secondary">Access role</dt>
            <dd className="mt-1 text-sm font-medium capitalize text-sb-text">{role === 'admin' ? 'Administrator' : 'Super administrator'}</dd>
          </div>
          <div className="sm:col-span-2">
            <dt className="text-xs font-medium uppercase tracking-wide text-sb-text-secondary">Firebase account ID</dt>
            <dd className="mt-1 break-all font-mono text-xs text-sb-text-secondary">{uid}</dd>
          </div>
        </dl>
      </section>

      <section className="rounded-2xl border border-sb-border bg-sb-surface p-5 shadow-sm sm:p-7">
        <div className="flex items-start gap-4">
          <span className="rounded-xl bg-sb-warning-subtle p-3 text-sb-on-warning-subtle"><KeyRound className="h-5 w-5" /></span>
          <div className="flex-1">
            <h2 className="text-base font-semibold text-sb-text">Sign-in security</h2>
            <p className="mt-1 text-sm leading-6 text-sb-text-secondary">
              Admin sessions expire after five days. Firebase sends password changes through its verified account recovery flow.
            </p>
            <button
              type="button"
              onClick={requestPasswordReset}
              disabled={isSending || !email}
              className="mt-4 inline-flex h-10 items-center justify-center gap-2 rounded-xl bg-sb-primary px-4 text-sm font-semibold text-sb-on-primary transition hover:bg-sb-primary-hover disabled:cursor-not-allowed disabled:opacity-60"
            >
              <KeyRound className="h-4 w-4" />
              {isSending ? 'Sending…' : 'Send password reset email'}
            </button>
            {message && <p role="status" className="mt-3 flex items-center gap-2 text-sm text-sb-on-success-subtle"><CheckCircle2 className="h-4 w-4" />{message}</p>}
            {error && <p role="alert" className="mt-3 text-sm text-sb-error">{error}</p>}
          </div>
        </div>
      </section>

      <p className="text-xs leading-5 text-sb-text-secondary">
        Platform-wide controls such as maintenance mode, fees, escrow timing, and regional availability are not shown as editable here because the mobile app does not currently read those values from Firebase.
      </p>
    </div>
  );
}
