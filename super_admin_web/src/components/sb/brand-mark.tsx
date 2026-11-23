import Image from 'next/image';

/**
 * The SkillBridge mark (the "SB" monogram with the briefcase, the app icon)
 * on a white rounded tile, like the mobile app's `SbLogoMark`. The image is
 * made from the official logo by tool/brand/generate_icons.py.
 */
export function BrandMark({ size = 32, className, title }: { size?: number; className?: string; title?: string }) {
  const markWidth = Math.round(size * 0.86);
  return (
    <span
      className={`inline-flex shrink-0 items-center justify-center bg-white border border-black/[0.08] ${className ?? ''}`}
      style={{ width: size, height: size, borderRadius: size * 0.22 }}
      role={title ? 'img' : undefined}
      aria-label={title}
      aria-hidden={title ? undefined : true}
    >
      <Image src="/brand/skillbridge-mark.png" alt="" width={markWidth} height={Math.round(markWidth / (706 / 347))} />
    </span>
  );
}

/** The full logo: mark, "SkillBridge" and "Skills • Jobs • Growth". */
export function BrandLogo({ width = 280, className }: { width?: number; className?: string }) {
  return (
    <Image
      src="/brand/skillbridge-logo.png"
      alt="SkillBridge"
      width={width}
      height={Math.round(width / (973 / 603))}
      className={className}
      priority
    />
  );
}
