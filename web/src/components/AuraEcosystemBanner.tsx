import React from 'react';
import { useStore } from '../context/StoreContext';
import { Smartphone, Zap, Award, Gauge, ArrowRight, ArrowLeft } from 'lucide-react';

export const AuraEcosystemBanner: React.FC = () => {
  const { t, language } = useStore();
  const ArrowIcon = language === 'ar' ? ArrowLeft : ArrowRight;

  return (
    <section id="ecosystem-sync" className="py-20 relative overflow-hidden bg-gradient-to-b from-[#0b0f0d] via-[#111914] to-[#0b0f0d] border-y border-white/10">
      {/* Background Radial Glow */}
      <div className="absolute top-1/2 start-1/2 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[350px] bg-[#00e599]/8 rounded-full blur-[140px] pointer-events-none" />

      <div className="max-w-7xl mx-auto px-4 lg:px-8 relative z-10">
        
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[#1e3a2b]/70 border border-[#00e599]/40 text-[#00e599] text-xs font-bold uppercase tracking-wider mb-4">
            <Smartphone className="w-3.5 h-3.5" />
            <span>{t.ecosystem.badge}</span>
          </div>
          <h2 className="text-3xl sm:text-5xl font-black text-white font-['Space_Grotesk'] tracking-tight">
            {t.ecosystem.title}
          </h2>
          <p className="text-slate-300 text-sm sm:text-base leading-relaxed mt-4">
            {t.ecosystem.description}
          </p>
        </div>

        {/* 3 Pillars Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          
          {/* Card 1: Instant Workout Sync */}
          <div className="aura-glass-card rounded-2xl p-6 sm:p-8 flex flex-col justify-between border border-white/10 hover:border-[#00e599]/40 transition-all text-start">
            <div>
              <div className="w-12 h-12 rounded-xl bg-[#00e599]/15 border border-[#00e599]/30 flex items-center justify-center text-[#00e599] mb-5">
                <Zap className="w-6 h-6" />
              </div>
              <h3 className="text-lg font-bold text-white mb-2 font-['Space_Grotesk']">
                {t.ecosystem.feature1Title}
              </h3>
              <p className="text-xs sm:text-sm text-slate-300 leading-relaxed">
                {t.ecosystem.feature1Desc}
              </p>
            </div>
            <div className="pt-6 mt-6 border-t border-white/10 flex items-center justify-between text-xs text-[#00e599] font-bold">
              <span>NFC Microchip Tag</span>
              <span>1-Tap Action</span>
            </div>
          </div>

          {/* Card 2: Exclusive Athlete Perks */}
          <div className="aura-glass-card rounded-2xl p-6 sm:p-8 flex flex-col justify-between border border-[#00e599]/40 bg-gradient-to-b from-[#14231b] to-[#0e1612] transition-all text-start relative overflow-hidden shadow-xl shadow-[#00e599]/10">
            <div className="absolute top-0 end-0 bg-[#00e599] text-black text-[10px] font-black uppercase px-3 py-1 rounded-bl-xl">
              VIP Unlocked
            </div>
            <div>
              <div className="w-12 h-12 rounded-xl bg-[#00e599] text-black flex items-center justify-center font-black mb-5 shadow-lg shadow-[#00e599]/30">
                <Award className="w-6 h-6" />
              </div>
              <h3 className="text-lg font-bold text-white mb-2 font-['Space_Grotesk']">
                {t.ecosystem.feature2Title}
              </h3>
              <p className="text-xs sm:text-sm text-slate-300 leading-relaxed">
                {t.ecosystem.feature2Desc}
              </p>
            </div>
            <div className="pt-6 mt-6 border-t border-white/10 flex items-center justify-between text-xs text-[#00e599] font-bold">
              <span>Aura AI Dual-Engine</span>
              <span>Gemini + Ollama</span>
            </div>
          </div>

          {/* Card 3: Durability Counter */}
          <div className="aura-glass-card rounded-2xl p-6 sm:p-8 flex flex-col justify-between border border-white/10 hover:border-[#00e599]/40 transition-all text-start">
            <div>
              <div className="w-12 h-12 rounded-xl bg-[#00e599]/15 border border-[#00e599]/30 flex items-center justify-center text-[#00e599] mb-5">
                <Gauge className="w-6 h-6" />
              </div>
              <h3 className="text-lg font-bold text-white mb-2 font-['Space_Grotesk']">
                {t.ecosystem.feature3Title}
              </h3>
              <p className="text-xs sm:text-sm text-slate-300 leading-relaxed">
                {t.ecosystem.feature3Desc}
              </p>
            </div>
            <div className="pt-6 mt-6 border-t border-white/10 flex items-center justify-between text-xs text-[#00e599] font-bold">
              <span>Fiber Elasticity Health</span>
              <span>100+ Washes</span>
            </div>
          </div>

        </div>

        {/* CTA Bar */}
        <div className="mt-12 p-6 aura-glass rounded-2xl border border-white/10 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-3 h-3 rounded-full bg-[#00e599] animate-ping" />
            <span className="text-sm font-semibold text-slate-200">
              Compatible with iOS, Android, and all NFC-enabled mobile devices.
            </span>
          </div>
          <button 
            onClick={() => {
              window.scrollTo({ top: 0, behavior: 'smooth' });
            }}
            className="flex items-center gap-2 text-xs sm:text-sm font-bold text-[#00e599] hover:text-white transition-colors"
          >
            <span>{t.ecosystem.ctaButton}</span>
            <ArrowIcon className="w-4 h-4" />
          </button>
        </div>

      </div>
    </section>
  );
};

