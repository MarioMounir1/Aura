import React, { useState } from 'react';
import { useStore } from '../context/StoreContext';
import { X, Ruler, CheckCircle2 } from 'lucide-react';

export const SizeAdvisorModal: React.FC = () => {
  const { isSizeAdvisorOpen, setIsSizeAdvisorOpen, t } = useStore();

  const [height, setHeight] = useState<number>(178);
  const [weight, setWeight] = useState<number>(78);
  const [fit, setFit] = useState<'compression' | 'athletic' | 'relaxed'>('athletic');
  const [calculatedSize, setCalculatedSize] = useState<string>('L');

  if (!isSizeAdvisorOpen) return null;

  const calculateSize = () => {
    // Bio-mechanical size estimation
    let baseScore = (height * 0.4) + (weight * 0.6);
    if (fit === 'compression') baseScore -= 5;
    if (fit === 'relaxed') baseScore += 5;

    let res = 'M';
    if (baseScore < 105) res = 'S';
    else if (baseScore < 118) res = 'M';
    else if (baseScore < 130) res = 'L';
    else if (baseScore < 142) res = 'XL';
    else res = 'XXL';

    setCalculatedSize(res);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/85 backdrop-blur-md animate-in fade-in">
      <div 
        className="relative w-full max-w-lg bg-[#121824] border border-[#222b3f] rounded-[24px] p-6 sm:p-8 shadow-2xl text-start"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close Button */}
        <button
          onClick={() => setIsSizeAdvisorOpen(false)}
          className="absolute top-5 end-5 p-2 rounded-xl bg-[#1b2232] hover:bg-[#222b3f] text-[#8e929c] hover:text-white border border-[#222b3f] transition-all cursor-pointer"
        >
          <X className="w-5 h-5" />
        </button>

        {/* Header */}
        <div className="flex items-center gap-3 mb-2">
          <div className="w-10 h-10 rounded-xl bg-[#1b2232] border border-[#222b3f] flex items-center justify-center text-[#10b981]">
            <Ruler className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-xl font-bold text-white font-['Plus_Jakarta_Sans']">
              {t.sizeAdvisor.title}
            </h3>
            <p className="text-xs text-[#8e929c]">
              {t.sizeAdvisor.subtitle}
            </p>
          </div>
        </div>

        {/* Sliders & Inputs */}
        <div className="space-y-5 my-6">
          
          {/* Height */}
          <div>
            <div className="flex items-center justify-between text-xs font-bold text-slate-200 mb-2">
              <span>{t.sizeAdvisor.height}</span>
              <span className="text-[#10b981] font-bold font-['Plus_Jakarta_Sans'] text-sm">{height} cm</span>
            </div>
            <input
              type="range"
              min="150"
              max="210"
              value={height}
              onChange={(e) => {
                setHeight(Number(e.target.value));
                calculateSize();
              }}
              className="w-full accent-[#10b981] bg-[#1b2232] h-2 rounded-lg cursor-pointer"
            />
          </div>

          {/* Weight */}
          <div>
            <div className="flex items-center justify-between text-xs font-bold text-slate-200 mb-2">
              <span>{t.sizeAdvisor.weight}</span>
              <span className="text-[#10b981] font-bold font-['Plus_Jakarta_Sans'] text-sm">{weight} kg</span>
            </div>
            <input
              type="range"
              min="45"
              max="140"
              value={weight}
              onChange={(e) => {
                setWeight(Number(e.target.value));
                calculateSize();
              }}
              className="w-full accent-[#10b981] bg-[#1b2232] h-2 rounded-lg cursor-pointer"
            />
          </div>

          {/* Fit Preference */}
          <div>
            <label className="block text-xs font-bold text-slate-200 mb-2">
              {t.sizeAdvisor.fitPreference}
            </label>
            <div className="grid grid-cols-3 gap-2">
              {[
                { id: 'compression', label: 'Compression' },
                { id: 'athletic', label: 'Athletic Fit' },
                { id: 'relaxed', label: 'Relaxed / Pump' },
              ].map((opt) => (
                <button
                  key={opt.id}
                  onClick={() => {
                    setFit(opt.id as any);
                    calculateSize();
                  }}
                  className={`py-2 px-1 text-center rounded-xl text-xs font-bold transition-all border cursor-pointer ${
                    fit === opt.id
                      ? 'aura-btn-primary text-white border-transparent shadow-md shadow-[#10b981]/20'
                      : 'bg-[#1b2232] text-[#8e929c] hover:text-white border-[#222b3f]'
                  }`}
                >
                  {opt.label}
                </button>
              ))}
            </div>
          </div>

        </div>

        {/* Calculation Result Callout */}
        <div className="p-4 bg-[#1b2232] rounded-[18px] border border-[#222b3f] flex items-center justify-between">
          <div>
            <span className="text-xs font-bold text-white block">
              {t.sizeAdvisor.recommendedSize}
            </span>
            <span className="text-xs text-[#10b981] flex items-center gap-1 mt-0.5 font-medium">
              <CheckCircle2 className="w-3.5 h-3.5" />
              <span>{t.sizeAdvisor.confidence}</span>
            </span>
          </div>

          <div className="w-14 h-14 rounded-2xl aura-btn-primary text-white font-extrabold text-2xl flex items-center justify-center font-['Plus_Jakarta_Sans'] shadow-lg shadow-[#10b981]/25">
            {calculatedSize}
          </div>
        </div>

        {/* Close CTA */}
        <div className="mt-6">
          <button
            onClick={() => setIsSizeAdvisorOpen(false)}
            className="w-full py-3 aura-btn-surface text-slate-200 hover:text-white font-bold text-xs rounded-xl transition-colors cursor-pointer"
          >
            {t.sizeAdvisor.close}
          </button>
        </div>

      </div>
    </div>
  );
};
