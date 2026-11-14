import React from 'react';
import { useStore } from '../context/StoreContext';
import { ArrowRight, ArrowLeft, ShieldCheck, Zap, Activity } from 'lucide-react';

export const Hero: React.FC<{ onShopClick: () => void }> = ({ onShopClick }) => {
  const { t, language } = useStore();
  const ArrowIcon = language === 'ar' ? ArrowLeft : ArrowRight;

  return (
    <div className="relative overflow-hidden bg-gradient-to-b from-[#0b100d] via-[#101914] to-[#0b0f0d] border-b border-white/10 pt-8 pb-16 lg:py-24">
      {/* Background Decorative Neon Glow Orbs */}
      <div className="absolute top-1/4 start-1/2 -translate-x-1/2 w-[550px] h-[550px] bg-[#00e599]/10 rounded-full blur-[140px] pointer-events-none" />
      <div className="absolute top-10 end-10 w-[350px] h-[350px] bg-[#1e3a2b]/30 rounded-full blur-[100px] pointer-events-none" />

      <div className="max-w-7xl mx-auto px-4 lg:px-8 relative z-10">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          
          {/* Left Text Column */}
          <div className="lg:col-span-7 flex flex-col items-start text-start">
            
            {/* Season Badge */}
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[#1e3a2b]/60 border border-[#00e599]/40 text-[#00e599] text-xs font-bold tracking-wider uppercase mb-6 shadow-sm">
              <Zap className="w-3.5 h-3.5 animate-pulse" />
              <span>{t.hero.badge}</span>
            </div>

            {/* Main Headline */}
            <h1 className="text-4xl sm:text-6xl lg:text-7xl font-black text-white tracking-tight leading-[1.08] mb-6 font-['Space_Grotesk']">
              {t.hero.headlineStart}{' '}
              <span className="aura-gradient-text block mt-1">
                {t.hero.headlineHighlight}
              </span>
            </h1>

            {/* Subtitle */}
            <p className="text-slate-300 text-base sm:text-lg leading-relaxed max-w-2xl mb-8 font-normal">
              {t.hero.subhead}
            </p>

            {/* CTAs */}
            <div className="flex flex-wrap items-center gap-4 w-full sm:w-auto">
              <button
                onClick={onShopClick}
                className="w-full sm:w-auto flex items-center justify-center gap-3 bg-[#00e599] hover:bg-[#00c985] text-black font-extrabold text-sm sm:text-base px-8 py-4 rounded-xl shadow-lg shadow-[#00e599]/25 hover:scale-105 active:scale-95 transition-all"
              >
                <span>{t.hero.shopNow}</span>
                <ArrowIcon className="w-5 h-5" />
              </button>

              <a
                href="#technology"
                className="w-full sm:w-auto flex items-center justify-center gap-2 bg-[#141c18] hover:bg-white/10 text-white font-bold text-sm sm:text-base px-7 py-4 rounded-xl border border-white/15 transition-all hover:border-[#00e599]/50"
              >
                <span>{t.hero.exploreTech}</span>
              </a>
            </div>

            {/* Lab-tested Metric Badges */}
            <div className="grid grid-cols-3 gap-4 pt-10 mt-8 border-t border-white/10 w-full max-w-xl">
              <div>
                <div className="text-2xl sm:text-3xl font-black text-[#00e599] font-['Space_Grotesk']">
                  {t.hero.stat1Val}
                </div>
                <div className="text-[11px] sm:text-xs text-slate-400 mt-1 font-medium">
                  {t.hero.stat1Label}
                </div>
              </div>
              <div>
                <div className="text-2xl sm:text-3xl font-black text-white font-['Space_Grotesk']">
                  {t.hero.stat2Val}
                </div>
                <div className="text-[11px] sm:text-xs text-slate-400 mt-1 font-medium">
                  {t.hero.stat2Label}
                </div>
              </div>
              <div>
                <div className="text-2xl sm:text-3xl font-black text-[#00e599] font-['Space_Grotesk']">
                  {t.hero.stat3Val}
                </div>
                <div className="text-[11px] sm:text-xs text-slate-400 mt-1 font-medium">
                  {t.hero.stat3Label}
                </div>
              </div>
            </div>

          </div>

          {/* Right Hero Visual Card */}
          <div className="lg:col-span-5 relative">
            <div className="relative mx-auto max-w-md lg:max-w-none">
              
              {/* Outer Glow Border Frame */}
              <div className="relative rounded-3xl overflow-hidden p-1 bg-gradient-to-tr from-[#00e599]/40 via-white/10 to-[#1e3a2b]/50 shadow-2xl shadow-black/80">
                <div className="relative rounded-[22px] overflow-hidden bg-[#0d1410] aspect-[4/5]">
                  <img
                    src="https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=1000&q=85"
                    alt="Aura Athlete in Apex Gear"
                    className="w-full h-full object-cover object-center transform hover:scale-105 transition-transform duration-700"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/20 to-transparent" />
                  
                  {/* Floating Tag Overlay */}
                  <div className="absolute bottom-5 inset-x-5 aura-glass rounded-2xl p-4 border border-white/15">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2.5">
                        <div className="w-8 h-8 rounded-full bg-[#00e599]/20 flex items-center justify-center text-[#00e599]">
                          <Activity className="w-4 h-4" />
                        </div>
                        <div>
                          <div className="text-xs font-bold text-white">Apex Compression V2</div>
                          <div className="text-[10px] text-[#00e599] font-semibold">NFC Aura App Enabled</div>
                        </div>
                      </div>
                      <div className="text-end">
                        <div className="text-xs font-black text-white">$48 / 1250 EGP</div>
                        <div className="text-[10px] text-slate-400">Autumn Drop 01</div>
                      </div>
                    </div>
                  </div>

                  {/* Certified Bio-Mechanical Seal */}
                  <div className="absolute top-4 start-4 bg-black/60 backdrop-blur-md px-3 py-1.5 rounded-full border border-white/20 flex items-center gap-1.5 text-[11px] font-semibold text-slate-200">
                    <ShieldCheck className="w-3.5 h-3.5 text-[#00e599]" />
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

