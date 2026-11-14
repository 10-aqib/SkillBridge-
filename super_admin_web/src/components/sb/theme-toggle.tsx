'use client';

import { useEffect, useState } from 'react';
import { Monitor, Moon, Sun } from 'lucide-react';
import { cn } from '@/lib/utils';

type ThemeChoice = 'light' | 'dark' | 'system';
const KEY = 'sb-admin-theme';

function apply(choice: ThemeChoice) {
  const dark =
    choice === 'dark' ||
    (choice === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches);
  document.documentElement.classList.toggle('dark', dark);
}

function readChoice(): ThemeChoice {
  try {
    const saved = localStorage.getItem(KEY);
    if (saved === 'light' || saved === 'dark' || saved === 'system') return saved;
  } catch {
    // Storage blocked (private mode): use the default.
  }
  return 'light';
}

/**
 * Light / dark / system switch for the admin console. The choice is a per-browser
 * preference (localStorage); the root layout applies it before first paint.
 */
export function ThemeToggle({ className }: { className?: string }) {
  // null until mounted, so server and client render the same markup.
  const [choice, setChoice] = useState<ThemeChoice | null>(null);

  useEffect(() => {
    // Sync from storage once on mount; the pre-paint script already applied it.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setChoice(readChoice());
  }, []);

  useEffect(() => {
    if (choice !== 'system') return;
    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    const onChange = () => apply('system');
    mq.addEventListener('change', onChange);
    return () => mq.removeEventListener('change', onChange);
  }, [choice]);

  const select = (next: ThemeChoice) => {
    setChoice(next);
    try {
      localStorage.setItem(KEY, next);
    } catch {
      // Preference just won't persist.
    }
    apply(next);
  };

  const options: { value: ThemeChoice; label: string; Icon: typeof Sun }[] = [
    { value: 'light', label: 'Light theme', Icon: Sun },
    { value: 'dark', label: 'Dark theme', Icon: Moon },
    { value: 'system', label: 'Use system theme', Icon: Monitor },
  ];

  return (
    <div
      role="radiogroup"
      aria-label="Colour theme"
      className={cn('flex items-center gap-0.5 rounded-sb-control bg-sb-surface-sunken p-0.5', className)}
    >
      {options.map(({ value, label, Icon }) => {
        const selected = choice === value;
        return (
          <button
            key={value}
            type="button"
            role="radio"
            aria-checked={selected}
            aria-label={label}
            title={label}
            onClick={() => select(value)}
            className={cn(
              'sb-focus flex h-8 w-8 items-center justify-center rounded-[6px] transition-colors',
              selected
                ? 'bg-sb-surface text-sb-text shadow-xs'
                : 'text-sb-text-secondary hover:text-sb-text',
            )}
          >
            <Icon aria-hidden className="size-4" />
          </button>
        );
      })}
    </div>
  );
}
