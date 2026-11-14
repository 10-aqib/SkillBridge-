import type { ButtonHTMLAttributes } from 'react';
import { Loader2 } from 'lucide-react';
import { cn } from '@/lib/utils';

export type SbButtonVariant = 'primary' | 'secondary' | 'quiet' | 'destructive';

const variants: Record<SbButtonVariant, string> = {
  primary: 'bg-sb-primary text-sb-on-primary hover:bg-sb-primary-hover',
  secondary: 'border border-sb-border-strong bg-sb-surface text-sb-primary hover:bg-sb-primary-subtle',
  quiet: 'text-sb-primary hover:bg-sb-primary-subtle',
  destructive: 'bg-sb-error text-sb-on-error hover:opacity-90',
};

/**
 * Admin button. 40px default (44px `size="lg"` for primary page actions).
 * One primary per decision area; destructive actions open a confirmation.
 */
export function SbButton({
  variant = 'primary',
  size = 'md',
  loading = false,
  className,
  children,
  disabled,
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: SbButtonVariant;
  size?: 'md' | 'lg';
  loading?: boolean;
}) {
  return (
    <button
      {...props}
      data-sb
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      className={cn(
        'sb-focus inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-sb-control px-4 text-sm font-semibold transition-colors duration-150',
        'disabled:cursor-not-allowed disabled:bg-sb-surface-sunken disabled:text-sb-text-disabled disabled:border-transparent',
        size === 'md' ? 'h-10' : 'h-11 px-5',
        variants[variant],
        className,
      )}
    >
      {loading && <Loader2 aria-hidden className="size-4 animate-spin" />}
      {children}
    </button>
  );
}
