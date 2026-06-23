import Link from 'next/link';
import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { ThemeProvider } from "next-themes";
import { auth } from "@/auth";
import AuthProvider from "@/components/AuthProvider";
import Header from "@/components/Header";
import BottomNav from "@/components/BottomNav";
import ToastContainer from "@/components/Toast";
import AppRating from "@/components/AppRating";
import Onboarding from "@/components/Onboarding";
import ServiceWorkerRegistration from "@/components/ServiceWorkerRegistration";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Translater - Text, Voice & Document Translation",
  description: "Free translator app powered by AI. Translate text, voice, and documents.",
  manifest: "/manifest.webmanifest",
  appleWebApp: {
    capable: true,
    statusBarStyle: 'default',
    title: 'Translater',
  },
  icons: {
    icon: '/icon-192.png',
    apple: '/icon-512.png',
  },
};

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const session = await auth();

  return (
    <html
      lang="en"
      suppressHydrationWarning
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="flex min-h-full flex-col bg-white text-zinc-900 dark:bg-zinc-900 dark:text-zinc-100">
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
          <AuthProvider session={session}>
            <Header />
            <div className="flex-1 pb-16 md:pb-0">
              {children}
            </div>
            <footer className="hidden md:block border-t border-zinc-200 dark:border-zinc-700 py-3 text-center text-xs text-zinc-400">
              <Link href="/privacy" className="hover:text-zinc-600 dark:hover:text-zinc-300">Privacy Policy</Link>
              <span className="mx-2">·</span>
              Powered by tabiqchohan
            </footer>
            <BottomNav />
            <ToastContainer />
            <AppRating />
            <Onboarding />
            <ServiceWorkerRegistration />
          </AuthProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
