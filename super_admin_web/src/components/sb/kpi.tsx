import Link from 'next/link';
import type { LucideIcon } from 'lucide-react';
import { ArrowRight } from 'lucide-react';
import { cn } from '@/lib/utils';

/**
 * Metric tile. Every number states its scope ("Last 30 days", "All time"),
 * and a failed query shows "Unavailable" — never a silent 0.
 */
export function Kpi({
  label,
  value,
  scope,
  icon: Icon,
  href,
  hrefLabel,
  attention = false,
  unavailable = false,
}: {
  label: string;
  /** Pre-formatted (e.g. "Rs 1,24,500"). Ignored when unavailable. */
  value: string;
  scope: string;
  icon?: LucideIcon;
  href?: string;
  hrefLabel?: string;
  /** Needs action (queue > 0). Adds an amber marker, not a red alarm. */
  attention?: boolean;
  unavailable?: boolean;
}) {
  return (
    <section
      aria-label={label}
      className={cn(
        'relative flex flex-col gap-1 rounded-sb-card border border-sb-border bg-sb-surface p-4',
        attention && 'border-s-4 border-s-sb-accent',
      )}
    >
      <div className="flex items-center gap-2 text-sm font-medium text-sb-text-secondary">
        {Icon && <Icon aria-hidden className="size-4" />}
        <h2>{label}</h2>
      </div>
      {unavailable ? (
        <p className="text-base font-semibold text-sb-on-error-subtle">Unavailable</p>
      ) : (
        <p className="sb-tabular text-2xl font-bold tracking-tight text-sb-text">{value}</p>
      )}
      <p className="text-xs text-sb-text-secondary">{scope}</p>
      {href && hrefLabel && (
        <Link
          href={href}
          className="sb-focus mt-2 inline-flex w-fit items-center gap-1 rounded-sm text-sm font-semibold text-sb-primary hover:underline"
        >
          {hrefLabel}
          <ArrowRight aria-hidden className="size-3.5 rtl:rotate-180" />
        </Link>
      )}
    </section>
  );
}
