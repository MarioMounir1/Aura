import React from 'react';
import { useStore } from '../context/StoreContext';
import { Smartphone, Zap, Award, Gauge, ArrowRight, ArrowLeft } from 'lucide-react';

export const AuraEcosystemBanner: React.FC = () => {
  const { t, language } = useStore();
  const ArrowIcon = language === 'ar' ? ArrowLeft : ArrowRight;

  return (
    <section id="ecosystem-sync" className="py-20 relative overflow-hidden bg-gradient-to-b from-[#090c15] via-[#0f1422] to-[#090c15] border-y border-[#222b3f]">
      {/* Background Radial Glow */}
      <div className="absolute top-1/2 start-1/2 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[350px] bg-[#10b981]/5 rounded-full blur-[140px] pointer-events-none" />

      <div className="max-w-7xl mx-auto px-4 lg:px-8 relative z-10">
        
        {/* Section Header */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[#10b981]/10 border border-[#10b981]/30 text-[#10b981] text-xs font-bold uppercase tracking-wider mb-4">
            <Smartphone className="w-3.5 h-3.5" />
            <span>{t.ecosystem.badge}</span>
          </div>
          <h2 className="text-3xl sm:text-5xl font-black text-white font-['Plus_Jakarta_Sans'] tracking-tight">
            {t.ecosystem.title}
          </h2>
          <p className="text-[#8e929c] text-sm sm:text-base leading-relaxed mt-4">
            {t.ecosystem.description}
          </p>
        </div>

        {/* 3 Pillars Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          
          {/* Card 1: Instant Workout Sync */}
          <div className="bg-[#121824] rounded-[20px] p-6 sm:p-8 flex flex-col justify-between border border-[#222b3f] hover:border-[#10b981] transition-all text-start group">
            <div>
              <div className="w-12 h-12 rounded-xl bg-[#1b2232] border border-[#222b3f] flex items-center justify-center text-[#10b981] mb-5 group-hover:scale-105 transition-transform">
                <Zap className="w-6 h-6" />
              </div>
              <h3 className="text-lg font-bold text-white mb-2 font-['Plus_Jakarta_Sans'] group-hover:text-[#10b981] transition-colors">
                {t.ecosystem.feature1Title}
              </h3>
              <p className="text-xs sm:text-sm text-[#8e929c] leading-relaxed">
                {t.ecosystem.feature1Desc}
              </p>
            </div>
            <div className="pt-6 mt-6 border-t border-[#222b3f] flex items-center justify-between text-xs text-[#10b981] font-bold">
              <span>NFC Microchip Tag</span>
              <span>1-Tap Action</span>
            </div>
          </div>

          {/* Card 2: Exclusive Athlete Perks */}
          <div className="bg-[#121824] rounded-[20px] p-6 sm:p-8 flex flex-col justify-between border border-[#10b981]/50 bg-gradient-to-b from-[#121824] via-[#1b2232]/70 to-[#121824] transition-all text-start relative overflow-hidden shadow-xl shadow-[#10b981]/10">
            <div className="absolute top-0 end-0 aura-btn-primary text-white text-[10px] font-bold uppercase px-3 py-1 rounded-bl-xl shadow-md">
              VIP Unlocked
            </div>
            <div>
              <div className="w-12 h-12 rounded-xl aura-btn-primary text-white flex items-center justify-center font-black mb-5 shadow-lg shadow-[#10b981]/30">
                <Award className="w-6 h-6" />
              </div>
              <h3 className="text-lg font-bold text-white mb-2 font-['Plus_Jakarta_Sans'] text-[#10b981]">
                {t.ecosystem.feature2Title}
              </h3>
              <p className="text-xs sm:text-sm text-[#8e929c] leading-relaxed">
                {t.ecosystem.feature2Desc}
              </p>
            </div>
            <div className="pt-6 mt-6 border-t border-[#222b3f] flex items-center justify-between text-xs text-[#10b981] font-bold">
              <span>Aura AI Dual-Engine</span>
              <span>Gemini 2.0 + Ollama</span>
            </div>
          </div>

          {/* Card 3: Durability Counter */}
          <div className="bg-[#121824] rounded-[20px] p-6 sm:p-8 flex flex-col justify-between border border-[#222b3f] hover:border-[#10b981] transition-all text-start group">
            <div>
              <div className="w-12 h-12 rounded-xl bg-[#1b2232] border border-[#222b3f] flex items-center justify-center text-[#10b981] mb-5 group-hover:scale-105 transition-transform">
                <Gauge className="w-6 h-6" />
              </div>
              <h3 className="text-lg font-bold text-white mb-2 font-['Plus_Jakarta_Sans'] group-hover:text-[#10b981] transition-colors">
                {t.ecosystem.feature3Title}
              </h3>
              <p className="text-xs sm:text-sm text-[#8e929c] leading-relaxed">
                {t.ecosystem.feature3Desc}
              </p>
            </div>
            <div className="pt-6 mt-6 border-t border-[#222b3f] flex items-center justify-between text-xs text-[#10b981] font-bold">
              <span>Fiber Elasticity Health</span>
              <span>100+ Washes</span>
            </div>
          </div>

        </div>

        {/* CTA Bar */}
        <div className="mt-12 p-6 bg-[#121824] rounded-[20px] border border-[#222b3f] flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-3 h-3 rounded-full bg-[#10b981] animate-ping" />
            <span className="text-sm font-semibold text-slate-200">
              Compatible with iOS, Android, and all NFC-enabled mobile devices.
            </span>
          </div>
          <button 
            onClick={() => {
              window.scrollTo({ top: 0, behavior: 'smooth' });
            }}
            className="flex items-center gap-2 text-xs sm:text-sm font-bold text-[#10b981] hover:text-white transition-colors cursor-pointer"
          >
            <span>{t.ecosystem.ctaButton}</span>
            <ArrowIcon className="w-4 h-4" />
          </button>
        </div>

      </div>
    </section>
  );
};
