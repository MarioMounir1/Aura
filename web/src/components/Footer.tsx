import React, { useState } from 'react';
import { useStore } from '../context/StoreContext';
import { Send, CheckCircle2, Shield, Heart } from 'lucide-react';

export const Footer: React.FC = () => {
  const { t, triggerConfetti } = useStore();
  const [email, setEmail] = useState('');
  const [subscribed, setSubscribed] = useState(false);

  const handleSubscribe = (e: React.FormEvent) => {
    e.preventDefault();
    if (!email) return;
    setSubscribed(true);
    triggerConfetti();
    setEmail('');
  };

  return (
    <footer className="bg-[#090c15] border-t border-[#222b3f] text-start">
      
      {/* Newsletter VIP Banner */}
      <div className="border-b border-[#222b3f] py-16 bg-[#121824] relative overflow-hidden">
        <div className="max-w-4xl mx-auto px-4 text-center relative z-10">
          <h3 className="text-2xl sm:text-3xl font-black text-white font-['Plus_Jakarta_Sans'] mb-2">
            {t.newsletter.title}
          </h3>
          <p className="text-xs sm:text-sm text-[#8e929c] max-w-lg mx-auto mb-6">
            {t.newsletter.subtitle}
          </p>

          {subscribed ? (
            <div className="p-4 bg-[#10b981]/15 border border-[#10b981]/30 rounded-2xl max-w-md mx-auto text-xs font-bold text-[#10b981] flex items-center justify-center gap-2">
              <CheckCircle2 className="w-4 h-4" />
              <span>{t.newsletter.success}</span>
            </div>
          ) : (
            <form onSubmit={handleSubscribe} className="flex flex-col sm:flex-row gap-2 max-w-md mx-auto">
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder={t.newsletter.placeholder}
                className="flex-1 bg-[#1b2232] border border-[#222b3f] rounded-xl px-4 py-3 text-xs text-white placeholder-[#5d616b] outline-none focus:border-[#10b981]"
              />
              <button
                type="submit"
                className="px-6 py-3 aura-btn-primary text-white font-bold text-xs rounded-xl shadow-lg transition-transform hover:scale-105 active:scale-95 flex items-center justify-center gap-1.5 cursor-pointer"
              >
                <span>{t.newsletter.subscribe}</span>
                <Send className="w-3.5 h-3.5" />
              </button>
            </form>
          )}
        </div>
      </div>

      {/* Main Footer Links */}
      <div className="max-w-7xl mx-auto px-4 lg:px-8 py-16">
        <div className="grid grid-cols-1 md:grid-cols-12 gap-10">
          
          {/* Brand Info */}
          <div className="md:col-span-4">
            <div className="flex items-center gap-3 mb-4">
              <img 
                src="/aura_logo.png" 
                alt="Aura Logo" 
                className="h-8 w-auto object-contain filter drop-shadow" 
                onError={(e) => {
                  (e.target as HTMLElement).style.display = 'none';
                }}
              />
              <div className="flex items-center gap-1.5">
                <span className="font-extrabold text-lg text-white font-['Plus_Jakarta_Sans']">{t.brandName}</span>
                <span className="text-xs font-bold text-[#10b981] uppercase bg-[#10b981]/15 px-1.5 py-0.5 rounded border border-[#10b981]/30">
                  {t.brandSuffix}
                </span>
              </div>
            </div>
            <p className="text-xs text-[#8e929c] leading-relaxed mb-6 max-w-sm">
              {t.footer.aboutText}
            </p>
            <div className="flex items-center gap-2 text-xs text-[#8e929c]">
              <Shield className="w-4 h-4 text-[#10b981]" />
              <span>Bio-Mechanically Tested & Athlete Verified</span>
            </div>
          </div>

          {/* Column: Shop */}
          <div className="md:col-span-3">
            <h4 className="text-xs font-bold text-white uppercase tracking-wider mb-4 font-['Plus_Jakarta_Sans']">
              {t.footer.shopLinks}
            </h4>
            <ul className="space-y-2.5 text-xs text-[#8e929c]">
              <li><a href="#" className="hover:text-[#10b981] transition-colors">{t.categories.all}</a></li>
              <li><a href="#" className="hover:text-[#10b981] transition-colors">{t.categories.men}</a></li>
              <li><a href="#" className="hover:text-[#10b981] transition-colors">{t.categories.women}</a></li>
              <li><a href="#" className="hover:text-[#10b981] transition-colors">{t.categories.compression}</a></li>
              <li><a href="#" className="hover:text-[#10b981] transition-colors">{t.categories.hoodies}</a></li>
              <li><a href="#" className="hover:text-[#10b981] transition-colors">{t.categories.accessories}</a></li>
            </ul>
          </div>

          {/* Column: Care & Shipping */}
          <div className="md:col-span-3">
            <h4 className="text-xs font-bold text-white uppercase tracking-wider mb-4 font-['Plus_Jakarta_Sans']">
              {t.footer.helpLinks}
            </h4>
            <ul className="space-y-2.5 text-xs text-[#8e929c]">
              <li><a href="#" className="hover:text-[#10b981] transition-colors">{t.footer.shippingInfo}</a></li>
              <li><a href="#" className="hover:text-[#10b981] transition-colors">{t.footer.returns}</a></li>
              <li><a href="#" className="hover:text-[#10b981] transition-colors">{t.nav.sizeAdvisor}</a></li>
              <li><a href="#" className="hover:text-[#10b981] transition-colors">{t.footer.privacy}</a></li>
              <li><a href="#" className="hover:text-[#10b981] transition-colors">{t.footer.terms}</a></li>
            </ul>
          </div>

          {/* Column: App Integration */}
          <div className="md:col-span-2">
            <h4 className="text-xs font-bold text-white uppercase tracking-wider mb-4 font-['Plus_Jakarta_Sans']">
              Aura App
            </h4>
            <p className="text-[11px] text-[#8e929c] leading-relaxed mb-3">
              Scan your garment label with the Aura Mobile App to sync workouts and track macro goals.
            </p>
            <div className="inline-block bg-[#1b2232] border border-[#222b3f] text-[#10b981] text-[10px] font-bold px-2.5 py-1 rounded-md">
              Google Play & App Store
            </div>
          </div>

        </div>

        {/* Bottom Bar */}
        <div className="pt-8 mt-10 border-t border-[#222b3f] flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-[#5d616b]">
          <p>{t.footer.copyright}</p>
          <div className="flex items-center gap-3 text-[#8e929c]">
            <span>Powered by Gemini 2.0 Flash</span>
            <span>•</span>
            <span className="flex items-center gap-1 text-[#10b981]">
              <span>Engineered for Athletes</span>
              <Heart className="w-3 h-3 fill-current" />
            </span>
          </div>
        </div>

      </div>
    </footer>
  );
};
