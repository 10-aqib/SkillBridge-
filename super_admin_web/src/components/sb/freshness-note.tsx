import { Clock } from 'lucide-react';

/**
 * Honest data-scope label for dashboards and tables, e.g.
 * "Latest 100 jobs · loaded 14:02" or "Last 30 days · all cities".
 * Use instead of "Live" unless the view is a real-time listener.
 */
export function FreshnessNote({ scope, loadedAt }: { scope: string; loadedAt?: Date }) {
  const time = loadedAt
    ? new Intl.DateTimeFormat('en-PK', { hour: '2-digit', minute: '2-digit' }).format(loadedAt)
    : null;
  return (
    <p className="inline-flex items-center gap-1.5 text-xs text-sb-text-secondary">
      <Clock aria-hidden className="size-3.5" />
      <span>{scope}</span>
      {time && (
        <>
          <span aria-hidden>·</span>
          <span>
            loaded <time dateTime={loadedAt!.toISOString()}>{time}</time>
          </span>
        </>
      )}
    </p>
  );
}
