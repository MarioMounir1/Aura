import React from 'react';
import { useStore } from '../context/StoreContext';
import { Star } from 'lucide-react';

const InstagramIcon: React.FC<{ className?: string }> = ({ className }) => (
  <svg className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <rect width="20" height="20" x="2" y="2" rx="5" ry="5"/>
    <path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/>
    <line x1="17.5" x2="17.51" y1="6.5" y2="6.5"/>
  </svg>
);

export const LookbookCommunity: React.FC = () => {
  const { t } = useStore();

  const looks = [
    {
      image: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=700&q=80',
      handle: '@karim_lifts',
      caption: 'Hit a 240kg deadlift PR today in the Phantom 2-in-1 shorts. The Titan straps didn’t slip a millimeter.',
      discipline: 'Competitive Powerlifter'
    },
    {
      image: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=700&q=80',
      handle: '@nour_moves',
      caption: 'The Sculpt & Define leggings are genuinely 100% squat proof. Tested under harsh gym lighting.',
      discipline: 'HYROX & CrossFit Athlete'
    },
    {
      image: 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?auto=format&fit=crop&w=700&q=80',
      handle: '@tarek_runner',
      caption: '5am tempo run done. The DryBreeze ventilation kept me cool throughout the whole 15k.',
      discipline: 'Marathoner & Triathlete'
    },
    {
      image: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?auto=format&fit=crop&w=700&q=80',
      handle: '@salma_active',
      caption: 'Tapped my collar NFC to open Aura App and my leg day routine popped up instantly. Pure futuristic fitness.',
      discipline: 'Strength Coach'
    }
  ];

  return (
    <section className="py-20 bg-[#0d1410] border-t border-white/10 text-start">
      <div className="max-w-7xl mx-auto px-4 lg:px-8">
        
        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-12 gap-4">
          <div>
            <span className="text-xs font-bold text-[#00e599] tracking-wider uppercase">
              {t.lookbook.tagline}
            </span>
            <h2 className="text-3xl sm:text-4xl font-black text-white font-['Space_Grotesk'] mt-1">
              {t.lookbook.title}
            </h2>
            <p className="text-xs sm:text-sm text-slate-400 mt-2 max-w-xl">
              {t.lookbook.subtitle}
            </p>
          </div>

          <a 
            href="https://instagram.com" 
            target="_blank" 
            rel="noreferrer"
            className="flex items-center gap-2 text-xs font-bold text-white hover:text-[#00e599] transition-colors"
          >
            <InstagramIcon className="w-4 h-4 text-[#00e599]" />
            <span>@aura.athletics.official</span>
          </a>
        </div>

        {/* Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {looks.map((item, idx) => (
            <div 
              key={idx}
              className="group aura-glass-card rounded-2xl overflow-hidden border border-white/10 hover:border-[#00e599]/40 transition-all flex flex-col justify-between"
            >
              <div className="relative aspect-[4/5] bg-black overflow-hidden">
                <img
                  src={item.image}
                  alt={item.handle}
                  className="w-full h-full object-cover transform group-hover:scale-105 transition-transform duration-700"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent" />
                <div className="absolute bottom-3 start-3 end-3 flex items-center justify-between text-white text-xs">
                  <span className="font-bold">{item.handle}</span>
                  <span className="text-[10px] text-[#00e599] font-medium">{item.discipline}</span>
                </div>
              </div>

              <div className="p-4 bg-[#0e1411]">
                <div className="flex items-center gap-1 text-amber-400 mb-2">
                  {[...Array(5)].map((_, i) => (
                    <Star key={i} className="w-3 h-3 fill-amber-400" />
                  ))}
                </div>
                <p className="text-xs text-slate-300 italic leading-relaxed">
                  "{item.caption}"
                </p>
              </div>
            </div>
          ))}
        </div>

      </div>
    </section>
  );
};
