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
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md animate-in fade-in">
      <div 
        className="relative w-full max-w-lg bg-[#0e1411] border border-white/15 rounded-3xl p-6 sm:p-8 shadow-2xl text-start"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close Button */}
        <button
          onClick={() => setIsSizeAdvisorOpen(false)}
          className="absolute top-5 end-5 p-2 rounded-full bg-black/40 hover:bg-black/80 text-slate-300 hover:text-white border border-white/10"
        >
          <X className="w-5 h-5" />
        </button>

        {/* Header */}
        <div className="flex items-center gap-3 mb-2">
          <div className="w-10 h-10 rounded-xl bg-[#00e599]/20 flex items-center justify-center text-[#00e599]">
            <Ruler className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-xl font-black text-white font-['Space_Grotesk']">
              {t.sizeAdvisor.title}
            </h3>
            <p className="text-xs text-slate-400">
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
              <span className="text-[#00e599] font-black font-['Space_Grotesk'] text-sm">{height} cm</span>
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
              className="w-full accent-[#00e599] bg-[#1a2620] h-2 rounded-lg cursor-pointer"
            />
          </div>

          {/* Weight */}
          <div>
            <div className="flex items-center justify-between text-xs font-bold text-slate-200 mb-2">
              <span>{t.sizeAdvisor.weight}</span>
              <span className="text-[#00e599] font-black font-['Space_Grotesk'] text-sm">{weight} kg</span>
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
              className="w-full accent-[#00e599] bg-[#1a2620] h-2 rounded-lg cursor-pointer"
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
                  className={`py-2 px-1 text-center rounded-xl text-xs font-bold transition-all border ${
                    fit === opt.id
                      ? 'bg-[#00e599] text-black border-[#00e599] shadow-md shadow-[#00e599]/20'
                      : 'bg-[#141c18] text-slate-400 hover:text-white border-white/10'
                  }`}
                >
                  {opt.label}
                </button>
              ))}
            </div>
          </div>

        </div>

        {/* Calculation Result Callout */}
        <div className="p-4 bg-gradient-to-r from-[#14231b] via-[#1a2f23] to-[#14231b] rounded-2xl border border-[#00e599]/30 flex items-center justify-between">
          <div>
            <span className="text-xs font-bold text-slate-300 block">
              {t.sizeAdvisor.recommendedSize}
            </span>
            <span className="text-xs text-[#00e599] flex items-center gap-1 mt-0.5">
              <CheckCircle2 className="w-3.5 h-3.5" />
              <span>{t.sizeAdvisor.confidence}</span>
            </span>
          </div>

          <div className="w-14 h-14 rounded-2xl bg-[#00e599] text-black font-black text-2xl flex items-center justify-center font-['Space_Grotesk'] shadow-lg shadow-[#00e599]/30">
            {calculatedSize}
          </div>
        </div>

        {/* Close CTA */}
        <div className="mt-6">
          <button
            onClick={() => setIsSizeAdvisorOpen(false)}
            className="w-full py-3 bg-[#18261e] hover:bg-[#203429] text-white font-bold text-xs rounded-xl border border-white/10 transition-colors"
          >
            {t.sizeAdvisor.close}
          </button>
        </div>

      </div>
    </div>
  );
};
