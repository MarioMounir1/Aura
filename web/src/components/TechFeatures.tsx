import React from 'react';
import { useStore } from '../context/StoreContext';
import { Wind, Shield, Layers, Compass, Cpu } from 'lucide-react';

export const TechFeatures: React.FC = () => {
  const { t } = useStore();

  const techs = [
    {
      icon: <Layers className="w-6 h-6 text-[#00e599]" />,
      title: t.tech.card1Title,
      desc: t.tech.card1Desc,
      metric: '4-Way Elastic Memory',
      accent: 'border-[#00e599]/30'
    },
    {
      icon: <Wind className="w-6 h-6 text-[#00e599]" />,
      title: t.tech.card2Title,
      desc: t.tech.card2Desc,
      metric: 'Sub-second Moisture Evaporation',
      accent: 'border-[#00e599]/30'
    },
    {
      icon: <Shield className="w-6 h-6 text-[#00e599]" />,
      title: t.tech.card3Title,
      desc: t.tech.card3Desc,
      metric: '99.9% Microbial Inhibition',
      accent: 'border-[#00e599]/30'
    },
    {
      icon: <Compass className="w-6 h-6 text-[#00e599]" />,
      title: t.tech.card4Title,
      desc: t.tech.card4Desc,
      metric: 'Zero Friction Point Seams',
      accent: 'border-[#00e599]/30'
    }
  ];

  return (
    <section id="technology" className="py-20 bg-[#0b0f0d] relative overflow-hidden">
      <div className="max-w-7xl mx-auto px-4 lg:px-8">
        
        {/* Section Title */}
        <div className="text-center max-w-2xl mx-auto mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#18261e] border border-[#00e599]/30 text-[#00e599] text-[11px] font-bold uppercase tracking-wider mb-4">
            <Cpu className="w-3.5 h-3.5" />
            <span>{t.tech.tagline}</span>
          </div>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-black text-white font-['Space_Grotesk'] tracking-tight">
            {t.tech.title}
          </h2>
          <p className="text-slate-400 text-sm sm:text-base mt-4 leading-relaxed">
            {t.tech.subhead}
          </p>
        </div>

        {/* 4 Cards Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {techs.map((item, idx) => (
            <div 
              key={idx}
              className={`aura-glass-card rounded-2xl p-6 flex flex-col justify-between border ${item.accent} hover:border-[#00e599] transition-all text-start group`}
            >
              <div>
                <div className="w-12 h-12 rounded-xl bg-[#1a2920] border border-white/10 flex items-center justify-center mb-6 group-hover:scale-110 group-hover:bg-[#00e599]/20 transition-all">
                  {item.icon}
                </div>
                <h3 className="text-base font-bold text-white mb-2 font-['Space_Grotesk'] group-hover:text-[#00e599] transition-colors">
                  {item.title}
                </h3>
                <p className="text-xs text-slate-300 leading-relaxed">
                  {item.desc}
                </p>
              </div>

              <div className="pt-5 mt-6 border-t border-white/10">
                <span className="text-[10px] font-bold text-[#00e599] uppercase tracking-wider block">
                  {item.metric}
                </span>
              </div>
            </div>
          ))}
        </div>

      </div>
    </section>
  );
};

