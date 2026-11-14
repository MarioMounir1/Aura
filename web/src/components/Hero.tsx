import React from 'react';
import { useStore } from '../context/StoreContext';
import { ArrowRight, ArrowLeft, ShieldCheck, Zap, Activity } from 'lucide-react';

export const Hero: React.FC<{ onShopClick: () => void }> = ({ onShopClick }) => {
  const { t, language } = useStore();
  const ArrowIcon = language === 'ar' ? ArrowLeft : ArrowRight;

  return (
    <div className="relative overflow-hidden bg-gradient-to-b from-[#090c15] via-[#0f1422] to-[#090c15] border-b border-[#222b3f] pt-10 pb-16 lg:py-24">
      {/* Background Subtle Emerald Glow */}
      <div className="absolute top-1/4 start-1/2 -translate-x-1/2 w-[600px] h-[600px] bg-[#10b981]/8 rounded-full blur-[150px] pointer-events-none" />
      <div className="absolute top-10 end-10 w-[400px] h-[400px] bg-[#1b2232]/40 rounded-full blur-[120px] pointer-events-none" />

      <div className="max-w-7xl mx-auto px-4 lg:px-8 relative z-10">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          
          {/* Left Text Column */}
          <div className="lg:col-span-7 flex flex-col items-start text-start">
            
            {/* Season Badge */}
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[#10b981]/10 border border-[#10b981]/30 text-[#10b981] text-xs font-bold tracking-wider uppercase mb-6 shadow-sm">
              <Zap className="w-3.5 h-3.5 animate-pulse" />
              <span>{t.hero.badge}</span>
            </div>

            {/* Main Headline */}
            <h1 className="text-4xl sm:text-6xl lg:text-7xl font-black text-white tracking-tight leading-[1.08] mb-6 font-['Plus_Jakarta_Sans']">
              {t.hero.headlineStart}{' '}
              <span className="aura-gradient-text block mt-1">
                {t.hero.headlineHighlight}
              </span>
            </h1>

            {/* Subtitle */}
            <p className="text-[#8e929c] text-base sm:text-lg leading-relaxed max-w-2xl mb-8 font-normal">
              {t.hero.subhead}
            </p>

            {/* CTAs */}
            <div className="flex flex-wrap items-center gap-4 w-full sm:w-auto">
              <button
                onClick={onShopClick}
                className="w-full sm:w-auto flex items-center justify-center gap-3 aura-btn-primary px-8 py-4 text-sm sm:text-base font-bold shadow-lg shadow-[#10b981]/20 hover:scale-105 active:scale-95 transition-all cursor-pointer"
              >
                <span>{t.hero.shopNow}</span>
                <ArrowIcon className="w-5 h-5 text-white" />
              </button>

              <a
                href="#technology"
                className="w-full sm:w-auto flex items-center justify-center gap-2 aura-btn-surface px-7 py-4 text-sm sm:text-base font-bold border border-[#222b3f] hover:border-[#374151] transition-all"
              >
                <span>{t.hero.exploreTech}</span>
              </a>
            </div>

            {/* Lab-tested Metric Badges */}
            <div className="grid grid-cols-3 gap-4 pt-10 mt-8 border-t border-[#222b3f] w-full max-w-xl">
              <div>
                <div className="text-2xl sm:text-3xl font-extrabold text-[#10b981] font-['Plus_Jakarta_Sans']">
                  {t.hero.stat1Val}
                </div>
                <div className="text-[11px] sm:text-xs text-[#8e929c] mt-1 font-medium">
                  {t.hero.stat1Label}
                </div>
              </div>
              <div>
                <div className="text-2xl sm:text-3xl font-extrabold text-white font-['Plus_Jakarta_Sans']">
                  {t.hero.stat2Val}
                </div>
                <div className="text-[11px] sm:text-xs text-[#8e929c] mt-1 font-medium">
                  {t.hero.stat2Label}
                </div>
              </div>
              <div>
                <div className="text-2xl sm:text-3xl font-extrabold text-[#10b981] font-['Plus_Jakarta_Sans']">
                  {t.hero.stat3Val}
                </div>
                <div className="text-[11px] sm:text-xs text-[#8e929c] mt-1 font-medium">
                  {t.hero.stat3Label}
                </div>
              </div>
            </div>

          </div>

          {/* Right Hero Visual Card */}
          <div className="lg:col-span-5 relative">
            <div className="relative mx-auto max-w-md lg:max-w-none">
              
              {/* Card matching Flutter BorderRadius.circular(20) and AppColors.card */}
              <div className="relative rounded-[20px] overflow-hidden p-1 bg-gradient-to-tr from-[#10b981]/30 via-[#222b3f] to-[#1b2232] shadow-2xl shadow-black/80">
                <div className="relative rounded-[18px] overflow-hidden bg-[#121824] aspect-[4/5]">
                  <img
                    src="https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=1000&q=85"
                    alt="Aura Athlete in Apex Gear"
                    className="w-full h-full object-cover object-center transform hover:scale-105 transition-transform duration-700"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-[#090c15] via-[#090c15]/20 to-transparent" />
                  
                  {/* Floating Tag Overlay */}
                  <div className="absolute bottom-5 inset-x-5 bg-[#121824]/90 backdrop-blur-md rounded-[16px] p-4 border border-[#222b3f] shadow-lg">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2.5">
                        <div className="w-8 h-8 rounded-xl bg-[#10b981]/15 flex items-center justify-center text-[#10b981]">
                          <Activity className="w-4 h-4" />
                        </div>
                        <div>
                          <div className="text-xs font-bold text-white">Apex Compression V2</div>
                          <div className="text-[10px] text-[#10b981] font-semibold">NFC Aura App Enabled</div>
                        </div>
                      </div>
                      <div className="text-end">
                        <div className="text-xs font-extrabold text-white">$48 / 1250 EGP</div>
                        <div className="text-[10px] text-[#8e929c]">Autumn Drop 01</div>
                      </div>
                    </div>
                  </div>

                  {/* Certified Bio-Mechanical Seal */}
                  <div className="absolute top-4 start-4 bg-[#121824]/85 backdrop-blur-md px-3 py-1.5 rounded-full border border-[#222b3f] flex items-center gap-1.5 text-[11px] font-semibold text-slate-200">
                    <ShieldCheck className="w-3.5 h-3.5 text-[#10b981]" />
                    <span>Bio-Mechanical Fit Certified</span>
                  </div>
                </div>
              </div>

            </div>
          </div>

        </div>
      </div>
    </div>
  );
};
