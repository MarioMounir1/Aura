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
    <section className="py-20 bg-[#090c15] border-t border-[#222b3f] text-start">
      <div className="max-w-7xl mx-auto px-4 lg:px-8">
        
        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-end justify-between mb-12 gap-4">
          <div>
            <span className="text-xs font-bold text-[#10b981] tracking-wider uppercase">
              {t.lookbook.tagline}
            </span>
            <h2 className="text-3xl sm:text-4xl font-black text-white font-['Plus_Jakarta_Sans'] mt-1">
              {t.lookbook.title}
            </h2>
            <p className="text-xs sm:text-sm text-[#8e929c] mt-2 max-w-xl">
              {t.lookbook.subtitle}
            </p>
          </div>

          <a 
            href="https://instagram.com" 
            target="_blank" 
            rel="noreferrer"
            className="flex items-center gap-2 text-xs font-bold text-white hover:text-[#10b981] transition-colors"
          >
            <InstagramIcon className="w-4 h-4 text-[#10b981]" />
            <span>@aura.athletics.official</span>
          </a>
        </div>

        {/* Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {looks.map((item, idx) => (
            <div 
              key={idx}
              className="group bg-[#121824] rounded-[20px] overflow-hidden border border-[#222b3f] hover:border-[#10b981] transition-all flex flex-col justify-between hover:shadow-xl hover:shadow-[#10b981]/10"
            >
              <div className="relative aspect-[4/5] bg-[#090c15] overflow-hidden">
                <img
                  src={item.image}
                  alt={item.handle}
                  className="w-full h-full object-cover transform group-hover:scale-105 transition-transform duration-700"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-[#121824] via-transparent to-transparent" />
                <div className="absolute bottom-3 start-3 end-3 flex items-center justify-between text-white text-xs">
                  <span className="font-bold">{item.handle}</span>
                  <span className="text-[10px] text-[#10b981] font-semibold">{item.discipline}</span>
                </div>
              </div>

              <div className="p-4 bg-[#121824]">
                <div className="flex items-center gap-1 text-amber-400 mb-2">
                  {[...Array(5)].map((_, i) => (
                    <Star key={i} className="w-3.5 h-3.5 fill-amber-400" />
                  ))}
                </div>
                <p className="text-xs text-[#8e929c] italic leading-relaxed">
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
