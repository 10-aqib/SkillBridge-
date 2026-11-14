import Link from 'next/link';
import { ChevronRight } from 'lucide-react';
import type { ReactNode } from 'react';

export type Crumb = { label: string; href?: string };

/**
 * Admin page header: breadcrumb, title, one-line purpose, and page actions.
 * One h1 per page; sections below use h2.
 */
export function PageHeader({
  title,
  description,
  breadcrumbs,
  actions,
  meta,
}: {
  title: string;
  description?: string;
  breadcrumbs?: Crumb[];
  actions?: ReactNode;
  /** Scope / freshness note, e.g. <FreshnessNote />. */
  meta?: ReactNode;
}) {
  return (
    <header className="flex flex-col gap-4 border-b border-sb-border pb-5 md:flex-row md:items-end md:justify-between">
      <div className="min-w-0">
        {breadcrumbs && breadcrumbs.length > 0 && (
          <nav aria-label="Breadcrumb" className="mb-2">
            <ol className="flex flex-wrap items-center gap-1 text-sm text-sb-text-secondary">
              {breadcrumbs.map((c, i) => (
                <li key={`${c.label}-${i}`} className="flex items-center gap-1">
                  {i > 0 && <ChevronRight aria-hidden className="size-3.5" />}
                  {c.href ? (
                    <Link href={c.href} className="sb-focus rounded-sm hover:text-sb-primary hover:underline">
                      {c.label}
                    </Link>
                  ) : (
                    <span aria-current="page">{c.label}</span>
                  )}
                </li>
              ))}
            </ol>
          </nav>
        )}
        <h1 className="text-2xl font-bold tracking-tight text-sb-text">{title}</h1>
        {description && <p className="mt-1 max-w-2xl text-sm text-sb-text-secondary">{description}</p>}
        {meta && <div className="mt-2">{meta}</div>}
      </div>
      {actions && <div className="flex shrink-0 flex-wrap items-center gap-2">{actions}</div>}
    </header>
  );
}
