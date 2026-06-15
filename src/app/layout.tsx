import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { ThemeProvider } from "next-themes";
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

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      suppressHydrationWarning
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="flex min-h-full flex-col bg-white text-zinc-900 dark:bg-zinc-900 dark:text-zinc-100">
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
          <AuthProvider>
            <Header />
            <div className="flex-1 pb-16 md:pb-0">
              {children}
            </div>
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
