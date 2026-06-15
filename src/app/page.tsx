'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import TabNav from '@/components/TabNav';
import TextTab from '@/components/TextTab';
import VoiceTab from '@/components/VoiceTab';
import CameraTranslate from '@/components/CameraTranslate';
import DocumentTab from '@/components/DocumentTab';
import { TabType } from '@/types';

const tabVariants = {
  initial: { opacity: 0, x: 20 },
  animate: { opacity: 1, x: 0 },
  exit: { opacity: 0, x: -20 },
};

export default function Home() {
  const [activeTab, setActiveTab] = useState<TabType>('text');

  return (
    <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col px-4 py-4 sm:py-6">
      <TabNav activeTab={activeTab} onTabChange={setActiveTab} />
      <div className="mt-4 sm:mt-6">
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

      <footer className="mt-auto pt-8 pb-4 text-center">
        <p className="text-xs text-zinc-400 dark:text-zinc-500">
          Powered by <span className="font-medium text-blue-500">tabiqchohan</span>
        </p>
      </footer>
    </main>
  );
}
