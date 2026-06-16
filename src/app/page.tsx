'use client';

import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence, useScroll, useTransform } from 'framer-motion';
import Link from 'next/link';
import { Languages, Mic, Camera, FileText, ArrowRight, Sparkles, Shield, Globe, Users, ChevronDown, Star } from 'lucide-react';
import { useSession } from 'next-auth/react';
import TabNav from '@/components/TabNav';
import TextTab from '@/components/TextTab';
import VoiceTab from '@/components/VoiceTab';
import CameraTranslate from '@/components/CameraTranslate';
import DocumentTab from '@/components/DocumentTab';
import { TabType } from '@/types';

const features = [
  { icon: Languages, title: 'Text Translation', desc: 'Translate text between 50+ languages instantly with AI.', color: 'from-blue-500 to-cyan-500' },
  { icon: Mic, title: 'Voice Translation', desc: 'Speak naturally and get real-time translations.', color: 'from-purple-500 to-pink-500' },
  { icon: Camera, title: 'Camera Translation', desc: 'Point your camera at any text for instant translation.', color: 'from-emerald-500 to-teal-500' },
  { icon: FileText, title: 'Document Translation', desc: 'Upload PDF, Word, or images for full document translation.', color: 'from-orange-500 to-rose-500' },
];

const steps = [
  { num: '01', title: 'Choose Languages', desc: 'Select source and target languages from 50+ options.' },
  { num: '02', title: 'Enter Your Text', desc: 'Type, speak, capture, or upload the content you want to translate.' },
  { num: '03', title: 'Get Translation', desc: 'Receive accurate AI-powered translation in seconds.' },
];

const tabVariants = {
  initial: { opacity: 0, x: 20 },
  animate: { opacity: 1, x: 0 },
  exit: { opacity: 0, x: -20 },
};

export default function Home() {
  const { data: session } = useSession();
  const [activeTab, setActiveTab] = useState<TabType>('text');
  const [showTranslate, setShowTranslate] = useState(false);
  const featuresRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll();
  const heroOpacity = useTransform(scrollYProgress, [0, 0.15], [1, 0]);

  return (
    <main className="mx-auto flex w-full max-w-5xl flex-1 flex-col">
      {/* Hero Section */}
      <motion.section style={{ opacity: heroOpacity }} className="relative flex min-h-[85vh] flex-col items-center justify-center overflow-hidden px-4 text-center">
        <div className="pointer-events-none absolute inset-0 bg-gradient-to-br from-blue-600/10 via-purple-600/10 to-cyan-600/10 dark:from-blue-600/20 dark:via-purple-600/20 dark:to-cyan-600/20" />
        <div className="pointer-events-none absolute inset-0 bg-grid" />

        <motion.div initial={{ opacity: 0, y: 30 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.8 }} className="relative z-10 flex max-w-3xl flex-col items-center">
          <motion.div animate={{ y: [0, -8, 0] }} transition={{ repeat: Infinity, duration: 3 }} className="mb-6 flex h-20 w-20 items-center justify-center rounded-2xl bg-gradient-to-br from-blue-500 to-indigo-600 shadow-xl shadow-blue-500/30">
            <Languages size={36} className="text-white" />
          </motion.div>

          <h1 className="bg-gradient-to-r from-zinc-800 via-blue-600 to-indigo-600 bg-clip-text text-4xl font-extrabold leading-tight text-transparent dark:from-zinc-100 dark:via-blue-400 dark:to-indigo-400 sm:text-5xl md:text-6xl">
            Translate Anything,
            <br />
            <span className="text-blue-600 dark:text-blue-400">Anywhere</span>
          </h1>

          <p className="mt-6 max-w-xl text-base text-zinc-500 dark:text-zinc-400 sm:text-lg">
            Break language barriers with AI-powered translation. Text, voice, camera, and documents — all in one app.
          </p>

          <div className="mt-8 flex flex-wrap items-center justify-center gap-3">
            <motion.div whileHover={{ scale: 1.03 }} whileTap={{ scale: 0.97 }}>
              <Link
                href={session ? '#translate' : '/login'}
                onClick={(e) => { if (session) { e.preventDefault(); document.getElementById('translate')?.scrollIntoView({ behavior: 'smooth' }); setShowTranslate(true); } }}
                className="group flex items-center gap-2 rounded-xl bg-gradient-to-r from-blue-600 to-indigo-600 px-6 py-3 text-sm font-semibold text-white shadow-lg shadow-blue-500/30 transition-all hover:shadow-xl hover:shadow-blue-500/40"
              >
                {session ? 'Start Translating' : 'Get Started'}
                <ArrowRight size={16} className="transition-transform group-hover:translate-x-0.5" />
              </Link>
            </motion.div>

            {!session && (
              <motion.div whileHover={{ scale: 1.03 }} whileTap={{ scale: 0.97 }}>
                <Link
                  href="/login"
                  className="flex items-center gap-2 rounded-xl border border-zinc-200 bg-white/80 px-6 py-3 text-sm font-semibold text-zinc-700 backdrop-blur-sm transition-all hover:bg-zinc-50 dark:border-zinc-700 dark:bg-zinc-800/80 dark:text-zinc-300 dark:hover:bg-zinc-700"
                >
                  Sign In
                </Link>
              </motion.div>
            )}
          </div>

          <div className="mt-12 flex items-center gap-8 text-sm text-zinc-400 dark:text-zinc-500">
            <div className="flex items-center gap-2">
              <Globe size={16} className="text-blue-500" />
              <span>50+ Languages</span>
            </div>
            <div className="flex items-center gap-2">
              <Sparkles size={16} className="text-purple-500" />
              <span>AI Powered</span>
            </div>
            <div className="flex items-center gap-2">
              <Shield size={16} className="text-emerald-500" />
              <span>Free & Secure</span>
            </div>
          </div>
        </motion.div>

        <motion.button
          initial={{ opacity: 0 }}
          animate={{ opacity: 1, y: [0, 6, 0] }}
          transition={{ opacity: { delay: 1.5 }, y: { repeat: Infinity, duration: 2 } }}
          onClick={() => featuresRef.current?.scrollIntoView({ behavior: 'smooth' })}
          className="absolute bottom-8 text-zinc-400 hover:text-zinc-600 dark:hover:text-zinc-300"
        >
          <ChevronDown size={24} />
        </motion.button>
      </motion.section>

      {/* Features Section */}
      <section ref={featuresRef} className="relative px-4 py-20">
        <div className="mx-auto max-w-5xl">
          <motion.div initial={{ opacity: 0, y: 20 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="mb-12 text-center">
            <h2 className="text-3xl font-bold text-zinc-800 dark:text-zinc-100">Powerful Translation Features</h2>
            <p className="mt-3 text-zinc-500 dark:text-zinc-400">Four ways to translate anything, anytime.</p>
          </motion.div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            {features.map((feature, i) => (
              <motion.div
                key={feature.title}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1 }}
                whileHover={{ y: -4 }}
                className="group relative overflow-hidden rounded-xl border border-zinc-200 bg-white p-5 transition-shadow hover:shadow-lg dark:border-zinc-700 dark:bg-zinc-800/50"
              >
                <div className={`mb-4 flex h-12 w-12 items-center justify-center rounded-lg bg-gradient-to-br ${feature.color} shadow-lg`}>
                  <feature.icon size={20} className="text-white" />
                </div>
                <h3 className="mb-1.5 text-base font-semibold text-zinc-800 dark:text-zinc-100">{feature.title}</h3>
                <p className="text-xs leading-relaxed text-zinc-500 dark:text-zinc-400">{feature.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* How It Works */}
      <section className="relative px-4 py-20">
        <div className="mx-auto max-w-5xl">
          <motion.div initial={{ opacity: 0, y: 20 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="mb-12 text-center">
            <h2 className="text-3xl font-bold text-zinc-800 dark:text-zinc-100">How It Works</h2>
            <p className="mt-3 text-zinc-500 dark:text-zinc-400">Three simple steps to translate anything.</p>
          </motion.div>

          <div className="relative grid gap-8 md:grid-cols-3">
            {steps.map((step, i) => (
              <motion.div
                key={step.num}
                initial={{ opacity: 0, x: i === 1 ? 0 : i === 0 ? -30 : 30 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.15 }}
                className="relative flex flex-col items-center text-center"
              >
                <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-gradient-to-br from-blue-500 to-indigo-600 text-lg font-bold text-white shadow-lg">
                  {step.num}
                </div>
                <h3 className="mb-1.5 text-base font-semibold text-zinc-800 dark:text-zinc-100">{step.title}</h3>
                <p className="max-w-xs text-xs text-zinc-500 dark:text-zinc-400">{step.desc}</p>
                {i < steps.length - 1 && (
                  <div className="absolute -right-4 top-7 hidden text-zinc-300 md:block dark:text-zinc-600">
                    <ArrowRight size={20} />
                  </div>
                )}
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Stats */}
      <section className="relative px-4 py-16">
        <div className="mx-auto max-w-4xl">
          <div className="rounded-2xl bg-gradient-to-r from-blue-600/5 via-purple-600/5 to-cyan-600/5 p-8 dark:from-blue-600/10 dark:via-purple-600/10 dark:to-cyan-600/10">
            <div className="grid grid-cols-2 gap-8 md:grid-cols-4">
              {[
                { icon: Globe, value: '50+', label: 'Languages' },
                { icon: Users, value: '10K+', label: 'Active Users' },
                { icon: Sparkles, value: '100K+', label: 'Translations' },
                { icon: Star, value: '4.8', label: 'App Rating' },
              ].map((stat, i) => (
                <motion.div
                  key={stat.label}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: i * 0.1 }}
                  className="flex flex-col items-center text-center"
                >
                  <stat.icon size={22} className="mb-2 text-blue-500" />
                  <span className="text-2xl font-bold text-zinc-800 dark:text-zinc-100">{stat.value}</span>
                  <span className="text-xs text-zinc-500 dark:text-zinc-400">{stat.label}</span>
                </motion.div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Translation Section */}
      <section id="translate" className="relative px-4 py-8">
        <div className="mx-auto max-w-3xl">
          <motion.div initial={{ opacity: 0, y: 20 }} whileInView={{ opacity: 1, y: 0 }} viewport={{ once: true }} className="mb-6 text-center">
            <h2 className="text-2xl font-bold text-zinc-800 dark:text-zinc-100">Try It Now</h2>
            <p className="mt-1 text-sm text-zinc-500 dark:text-zinc-400">Select a mode and start translating.</p>
          </motion.div>

          <TabNav activeTab={activeTab} onTabChange={setActiveTab} />
          <div className="mt-4">
            <AnimatePresence mode="wait">
              <motion.div
                key={activeTab}
                variants={tabVariants}
                initial="initial"
                animate="animate"
                exit="exit"
                transition={{ duration: 0.2 }}
              >
                {activeTab === 'text' && <TextTab />}
                {activeTab === 'voice' && <VoiceTab />}
                {activeTab === 'camera' && <CameraTranslate />}
                {activeTab === 'documents' && <DocumentTab />}
              </motion.div>
            </AnimatePresence>
          </div>
        </div>
      </section>

      {/* CTA */}
      {!session && (
        <section className="relative px-4 py-20">
          <motion.div initial={{ opacity: 0, scale: 0.95 }} whileInView={{ opacity: 1, scale: 1 }} viewport={{ once: true }} className="mx-auto max-w-2xl text-center">
            <div className="rounded-2xl bg-gradient-to-r from-blue-600 to-indigo-600 p-10 shadow-xl">
              <h2 className="text-2xl font-bold text-white">Ready to Break Language Barriers?</h2>
              <p className="mt-3 text-sm text-blue-100">Join thousands of users who translate with Translater every day.</p>
              <motion.div whileHover={{ scale: 1.03 }} whileTap={{ scale: 0.97 }} className="mt-6 inline-block">
                <Link
                  href="/register"
                  className="inline-flex items-center gap-2 rounded-xl bg-white px-8 py-3 text-sm font-semibold text-blue-700 shadow-lg transition-all hover:bg-blue-50"
                >
                  Create Free Account
                  <ArrowRight size={16} />
                </Link>
              </motion.div>
            </div>
          </motion.div>
        </section>
      )}

      {/* Footer */}
      <footer className="border-t border-zinc-200 px-4 py-8 dark:border-zinc-700">
        <div className="mx-auto flex max-w-5xl flex-col items-center gap-4 text-center sm:flex-row sm:justify-between">
          <div className="flex items-center gap-2 text-sm text-zinc-500 dark:text-zinc-400">
            <Languages size={16} className="text-blue-500" />
            Translater
          </div>
          <div className="flex items-center gap-4 text-xs text-zinc-400">
            <Link href="/privacy" className="hover:text-zinc-600 dark:hover:text-zinc-300">Privacy Policy</Link>
            <Link href="/terms" className="hover:text-zinc-600 dark:hover:text-zinc-300">Terms of Service</Link>
            <Link href="/favorites" className="hover:text-zinc-600 dark:hover:text-zinc-300">Favorites</Link>
            <Link href="/history" className="hover:text-zinc-600 dark:hover:text-zinc-300">History</Link>
          </div>
          <p className="text-xs text-zinc-400">
            Powered by <span className="font-medium text-blue-500">tabiqchohan</span>
          </p>
        </div>
      </footer>
    </main>
  );
}
