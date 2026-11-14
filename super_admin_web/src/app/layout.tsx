import type { Metadata } from "next";
import { Noto_Sans, Noto_Nastaliq_Urdu } from "next/font/google";
import "./globals.css";

// SkillBridge type: Noto Sans for the console, Noto Nastaliq Urdu for any Urdu
// content (loaded only when used).
const notoSans = Noto_Sans({
  variable: "--font-noto-sans",
  subsets: ["latin", "latin-ext"],
  display: "swap",
});

const notoUrdu = Noto_Nastaliq_Urdu({
  variable: "--font-noto-urdu",
  subsets: ["arabic"],
  weight: ["400", "600", "700"],
  display: "swap",
  preload: false,
});

export const metadata: Metadata = {
  title: "SkillBridge Admin Console",
  description: "Secure platform operations and marketplace administration.",
};

// Applies the saved theme before first paint so there is no light/dark flash.
// Default (nothing saved) is light, matching the console's previous look;
// "system" follows the OS setting.
const themeInit = `(function(){try{var t=localStorage.getItem('sb-admin-theme');var d=t==='dark'||(t==='system'&&matchMedia('(prefers-color-scheme: dark)').matches);document.documentElement.classList.toggle('dark',d);}catch(e){}})();`;

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="en"
      suppressHydrationWarning
      className={`${notoSans.variable} ${notoUrdu.variable} h-full antialiased`}
    >
      <head>
        <script dangerouslySetInnerHTML={{ __html: themeInit }} />
      </head>
      <body className="min-h-full flex flex-col bg-sb-canvas text-sb-text font-sans">{children}</body>
    </html>
  );
}
