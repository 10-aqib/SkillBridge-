import type { LucideIcon } from 'lucide-react';
import { AlertCircle, Inbox, Lock, SearchX } from 'lucide-react';
import type { ReactNode } from 'react';
import { cn } from '@/lib/utils';

export type DataStateKind = 'empty' | 'no-results' | 'error' | 'permission';

const config: Record<DataStateKind, { icon: LucideIcon; tone: string; role?: 'alert' }> = {
  empty: { icon: Inbox, tone: 'bg-sb-surface-sunken text-sb-text-secondary' },
  'no-results': { icon: SearchX, tone: 'bg-sb-surface-sunken text-sb-text-secondary' },
  error: { icon: AlertCircle, tone: 'bg-sb-error-subtle text-sb-on-error-subtle', role: 'alert' },
  permission: { icon: Lock, tone: 'bg-sb-primary-subtle text-sb-on-primary-subtle' },
};

/**
 * Distinct states for tables, charts and panels. "empty" (query succeeded,
 * zero rows) must never be used for a failed query — use "error".
 */
export function DataState({
  kind,
  title,
  description,
  action,
  className,
}: {
  kind: DataStateKind;
  title: string;
  description?: string;
  action?: ReactNode;
  className?: string;
}) {
  const { icon: Icon, tone, role } = config[kind];
  return (
    <div role={role} className={cn('flex flex-col items-center px-6 py-10 text-center', className)}>
      <span className={cn('mb-3 flex size-12 items-center justify-center rounded-full', tone)}>
        <Icon aria-hidden className="size-6" />
      </span>
      <p className="text-base font-semibold text-sb-text">{title}</p>
      {description && <p className="mt-1 max-w-sm text-sm text-sb-text-secondary">{description}</p>}
      {action && <div className="mt-4">{action}</div>}
    </div>
  );
}

/** Skeleton rows shaped like the table they replace. */
export function TableSkeleton({ rows = 5, columns = 4 }: { rows?: number; columns?: number }) {
  return (
    <div role="status" aria-label="Loading" className="divide-y divide-sb-border">
      {Array.from({ length: rows }).map((_, r) => (
        <div key={r} className="flex gap-4 px-4 py-3.5">
          {Array.from({ length: columns }).map((_, c) => (
            <div
              key={c}
              className="h-3.5 animate-pulse rounded bg-sb-surface-sunken"
              style={{ width: c === 0 ? '28%' : `${14 + ((r + c) % 3) * 6}%` }}
            />
          ))}
        </div>
      ))}
    </div>
  );
}
