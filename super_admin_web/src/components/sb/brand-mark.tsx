import { useId } from 'react';

/**
 * The SkillBridge mark: the official app icon logo on a white rounded tile,
 * exactly like the mobile app's logo (`SbLogoMark`) and launch screens.
 * Shapes come from Flutter's FlutterLogo painter, the same ones
 * tool/brand/generate_icons.py draws; keep them in step.
 */
export function BrandMark({ size = 32, className, title }: { size?: number; className?: string; title?: string }) {
  const shadowId = `sb-mark-shadow-${useId()}`;
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 100 100"
      className={className}
      role={title ? 'img' : undefined}
      aria-label={title}
      aria-hidden={title ? undefined : true}
      xmlns="http://www.w3.org/2000/svg"
    >
      {title && <title>{title}</title>}
      <defs>
        <linearGradient
          id={shadowId}
          gradientUnits="userSpaceOnUse"
          x1="125.1715"
          y1="152.2773"
          x2="80.8297"
          y2="158.5341"
        >
          <stop offset="0" stopColor="#1A237E" stopOpacity="0" />
          <stop offset="1" stopColor="#1A237E" stopOpacity="0.4" />
        </linearGradient>
      </defs>
      <rect x="0.5" y="0.5" width="99" height="99" rx="22" fill="#FFFFFF" stroke="rgba(0,0,0,0.08)" />
      {/* Logo: a 202-unit square scaled to 86% of the tile, centred. */}
      <g transform="translate(7 7) scale(0.42574) translate(18 0)">
        <path d="M37.7 128.9 L9.8 101 L100.4 10.4 L156.2 10.4 Z" fill="#54C5F8" />
        <path d="M156.2 94 L100.4 94 L78.5 115.9 L106.4 143.8 Z" fill="#54C5F8" />
        <path d="M79.5 170.7 L100.4 191.6 L156.2 191.6 L107.4 142.8 Z" fill="#01579B" />
        <rect
          x="59.8"
          y="123.1"
          width="39.4"
          height="39.4"
          fill="#29B6F6"
          transform="matrix(0.7071 -0.7071 0.7071 0.7071 -77.697 98.057)"
        />
        <path d="M79.5 170.7 L120.9 156.4 L107.4 142.8 Z" fill={`url(#${shadowId})`} />
      </g>
    </svg>
  );
}
