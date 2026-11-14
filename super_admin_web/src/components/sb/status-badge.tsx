import type { LucideIcon } from 'lucide-react';
import { AlertCircle, CheckCircle2, Circle, Clock, Info, MinusCircle, Zap } from 'lucide-react';
import { cn } from '@/lib/utils';

export type SbTone = 'neutral' | 'info' | 'success' | 'warning' | 'error' | 'accent';

const toneClass: Record<SbTone, string> = {
  neutral: 'bg-sb-surface-sunken text-sb-text-secondary',
  info: 'bg-sb-primary-subtle text-sb-on-primary-subtle',
  success: 'bg-sb-success-subtle text-sb-on-success-subtle',
  warning: 'bg-sb-warning-subtle text-sb-on-warning-subtle',
  error: 'bg-sb-error-subtle text-sb-on-error-subtle',
  accent: 'bg-sb-accent-subtle text-sb-on-accent-subtle',
};

const toneIcon: Record<SbTone, LucideIcon> = {
  neutral: MinusCircle,
  info: Info,
  success: CheckCircle2,
  warning: Clock,
  error: AlertCircle,
  accent: Zap,
};

/**
 * Status badge: icon + text, never colour alone.
 * Map backend status strings to a tone in one place (see `statusTone`).
 */
export function StatusBadge({
  label,
  tone = 'neutral',
  icon,
  className,
}: {
  label: string;
  tone?: SbTone;
  icon?: LucideIcon;
  className?: string;
}) {
  const Icon = icon ?? toneIcon[tone];
  return (
    <span
      className={cn(
        'inline-flex h-6 items-center gap-1 whitespace-nowrap rounded-full pl-2 pr-2.5 text-xs font-semibold',
        toneClass[tone],
        className,
      )}
    >
      <Icon aria-hidden className="size-3.5 shrink-0" strokeWidth={2} />
      {label}
    </span>
  );
}

/** Small dot + text for dense tables. */
export function StatusDot({ label, tone = 'neutral' }: { label: string; tone?: SbTone }) {
  const dot: Record<SbTone, string> = {
    neutral: 'text-sb-text-secondary',
    info: 'text-sb-primary',
    success: 'text-sb-success',
    warning: 'text-sb-warning',
    error: 'text-sb-error',
    accent: 'text-sb-accent',
  };
  return (
    <span className="inline-flex items-center gap-1.5 text-sm text-sb-text">
      <Circle aria-hidden className={cn('size-2 fill-current', dot[tone])} />
      {label}
    </span>
  );
}

/**
 * Single mapping from Firestore status values to tones, so the same status
 * looks the same on every admin screen. Unknown values render neutral with
 * their raw label rather than being hidden.
 */
export function statusTone(status: string | null | undefined): SbTone {
  switch ((status ?? '').toLowerCase()) {
    case 'verified':
    case 'completed':
    case 'active':
    case 'resolved':
    case 'accepted':
      return 'success';
    case 'pending':
    case 'open':
    case 'investigating':
    case 'in_progress':
    case 'inprogress':
    case 'assigned':
      return 'warning';
    case 'suspended':
    case 'rejected':
    case 'cancelled':
    case 'canceled':
    case 'disputed':
    case 'failed':
      return 'error';
    case 'urgent':
      return 'accent';
    case 'not_configured':
    case 'draft':
    case 'closed':
      return 'neutral';
    default:
      return 'neutral';
  }
}
