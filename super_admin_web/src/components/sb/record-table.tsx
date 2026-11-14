import type { ReactNode } from 'react';
import { cn } from '@/lib/utils';

export type RecordColumn<T> = {
  key: string;
  header: string;
  cell: (row: T) => ReactNode;
  /** Right-align numbers and amounts. */
  numeric?: boolean;
  /** Hidden in the stacked (narrow) layout — keep identity and status visible. */
  hideWhenStacked?: boolean;
  className?: string;
};

/**
 * Responsive record table: a real <table> from md up, stacked label/value
 * records on narrow screens. Caller supplies empty/error/loading states via
 * `emptyState` so "no rows" and "query failed" are never the same thing.
 */
export function RecordTable<T>({
  caption,
  columns,
  rows,
  rowKey,
  rowHref,
  emptyState,
  footer,
}: {
  /** Visually hidden table caption for screen readers. */
  caption: string;
  columns: RecordColumn<T>[];
  rows: T[];
  rowKey: (row: T) => string;
  rowHref?: (row: T) => string;
  emptyState?: ReactNode;
  /** Pagination / count line. */
  footer?: ReactNode;
}) {
  if (rows.length === 0 && emptyState) {
    return <div className="rounded-sb-card border border-sb-border bg-sb-surface">{emptyState}</div>;
  }
  return (
    <div className="overflow-hidden rounded-sb-card border border-sb-border bg-sb-surface">
      <table className="hidden w-full text-sm md:table">
        <caption className="sr-only">{caption}</caption>
        <thead className="bg-sb-canvas text-left text-xs font-semibold text-sb-text-secondary">
          <tr>
            {columns.map((c) => (
              <th key={c.key} scope="col" className={cn('px-4 py-2.5', c.numeric && 'text-right', c.className)}>
                {c.header}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-sb-border">
          {rows.map((row) => (
            <tr key={rowKey(row)} className="text-sb-text hover:bg-sb-canvas">
              {columns.map((c, i) => {
                const content = c.cell(row);
                const href = i === 0 && rowHref ? rowHref(row) : undefined;
                return (
                  <td key={c.key} className={cn('px-4 py-3 align-middle', c.numeric && 'sb-tabular text-right', c.className)}>
                    {href ? (
                      <a href={href} className="sb-focus rounded-sm font-medium text-sb-text hover:text-sb-primary hover:underline">
                        {content}
                      </a>
                    ) : (
                      content
                    )}
                  </td>
                );
              })}
            </tr>
          ))}
        </tbody>
      </table>

      <ul className="divide-y divide-sb-border md:hidden" aria-label={caption}>
        {rows.map((row) => {
          const [first, ...rest] = columns;
          const href = rowHref?.(row);
          return (
            <li key={rowKey(row)} className="p-4">
              <div className="font-medium text-sb-text">
                {href ? (
                  <a href={href} className="sb-focus rounded-sm hover:text-sb-primary hover:underline">
                    {first.cell(row)}
                  </a>
                ) : (
                  first.cell(row)
                )}
              </div>
              <dl className="mt-2 grid grid-cols-[auto_1fr] gap-x-4 gap-y-1.5 text-sm">
                {rest
                  .filter((c) => !c.hideWhenStacked)
                  .map((c) => (
                    <div key={c.key} className="contents">
                      <dt className="text-sb-text-secondary">{c.header}</dt>
                      <dd className={cn('text-sb-text', c.numeric && 'sb-tabular')}>{c.cell(row)}</dd>
                    </div>
                  ))}
              </dl>
            </li>
          );
        })}
      </ul>
      {footer && (
        <div className="flex items-center justify-between border-t border-sb-border px-4 py-3 text-sm text-sb-text-secondary">
          {footer}
        </div>
      )}
    </div>
  );
}
