import React from 'react';
import { useStore } from '../context/StoreContext';
import { Wind, Shield, Layers, Compass, Cpu } from 'lucide-react';

export const TechFeatures: React.FC = () => {
  const { t } = useStore();

  const techs = [
    {
      icon: <Layers className="w-6 h-6 text-[#10b981]" />,
      title: t.tech.card1Title,
      desc: t.tech.card1Desc,
      metric: '4-Way Elastic Memory',
    },
    {
      icon: <Wind className="w-6 h-6 text-[#10b981]" />,
      title: t.tech.card2Title,
      desc: t.tech.card2Desc,
      metric: 'Sub-second Moisture Evaporation',
    },
    {
      icon: <Shield className="w-6 h-6 text-[#10b981]" />,
      title: t.tech.card3Title,
      desc: t.tech.card3Desc,
      metric: '99.9% Microbial Inhibition',
    },
    {
      icon: <Compass className="w-6 h-6 text-[#10b981]" />,
      title: t.tech.card4Title,
      desc: t.tech.card4Desc,
      metric: 'Zero Friction Point Seams',
    }
  ];

  return (
    <section id="technology" className="py-20 bg-[#090c15] relative overflow-hidden">
      <div className="max-w-7xl mx-auto px-4 lg:px-8">
        
        {/* Section Title */}
        <div className="text-center max-w-2xl mx-auto mb-16">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[#10b981]/10 border border-[#10b981]/30 text-[#10b981] text-[11px] font-bold uppercase tracking-wider mb-4">
            <Cpu className="w-3.5 h-3.5" />
            <span>{t.tech.tagline}</span>
          </div>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-black text-white font-['Plus_Jakarta_Sans'] tracking-tight">
            {t.tech.title}
          </h2>
          <p className="text-[#8e929c] text-sm sm:text-base mt-4 leading-relaxed">
            {t.tech.subhead}
          </p>
        </div>

        {/* 4 Cards Grid with Material 3 20px radius */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {techs.map((item, idx) => (
            <div 
              key={idx}
              className="bg-[#121824] rounded-[20px] p-6 flex flex-col justify-between border border-[#222b3f] hover:border-[#10b981] transition-all text-start group hover:shadow-xl hover:shadow-[#10b981]/10"
            >
              <div>
                <div className="w-12 h-12 rounded-xl bg-[#1b2232] border border-[#222b3f] flex items-center justify-center mb-6 group-hover:scale-110 group-hover:bg-[#10b981]/15 transition-all">
                  {item.icon}
                </div>
                <h3 className="text-base font-bold text-white mb-2 font-['Plus_Jakarta_Sans'] group-hover:text-[#10b981] transition-colors">
                  {item.title}
                </h3>
                <p className="text-xs text-[#8e929c] leading-relaxed">
                  {item.desc}
                </p>
              </div>

              <div className="pt-5 mt-6 border-t border-[#222b3f]">
                <span className="text-[10px] font-bold text-[#10b981] uppercase tracking-wider block">
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
