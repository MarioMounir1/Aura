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
    <footer className="bg-[#080c0a] border-t border-white/10 text-start">
      
      {/* Newsletter VIP Banner */}
      <div className="border-b border-white/10 py-16 bg-gradient-to-r from-[#0d1612] via-[#14231b] to-[#0d1612] relative overflow-hidden">
        <div className="max-w-4xl mx-auto px-4 text-center relative z-10">
          <h3 className="text-2xl sm:text-3xl font-black text-white font-['Space_Grotesk'] mb-2">
            {t.newsletter.title}
          </h3>
          <p className="text-xs sm:text-sm text-slate-300 max-w-lg mx-auto mb-6">
            {t.newsletter.subtitle}
          </p>

          {subscribed ? (
            <div className="p-4 bg-[#00e599]/15 border border-[#00e599]/40 rounded-2xl max-w-md mx-auto text-xs font-bold text-[#00e599] flex items-center justify-center gap-2">
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
                className="flex-1 bg-[#141c18] border border-white/20 rounded-xl px-4 py-3 text-xs text-white placeholder-slate-500 outline-none focus:border-[#00e599]"
              />
              <button
                type="submit"
                className="px-6 py-3 bg-[#00e599] hover:bg-[#00c985] text-black font-extrabold text-xs rounded-xl shadow-lg transition-transform hover:scale-105 active:scale-95 flex items-center justify-center gap-1.5"
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
            <div className="flex items-center gap-2 mb-4">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-[#00e599] to-[#1e3a2b] flex items-center justify-center font-black text-black">
                A
              </div>
              <span className="font-black text-lg text-white font-['Space_Grotesk']">{t.brandName}</span>
              <span className="text-xs font-bold text-[#00e599] uppercase bg-[#00e599]/10 px-1.5 py-0.5 rounded border border-[#00e599]/30">
                {t.brandSuffix}
              </span>
            </div>
            <p className="text-xs text-slate-400 leading-relaxed mb-6 max-w-sm">
              {t.footer.aboutText}
            </p>
            <div className="flex items-center gap-2 text-xs text-slate-400">
              <Shield className="w-4 h-4 text-[#00e599]" />
              <span>Bio-Mechanically Tested & Athlete Verified</span>
            </div>
          </div>

          {/* Column: Shop */}
          <div className="md:col-span-3">
            <h4 className="text-xs font-bold text-white uppercase tracking-wider mb-4 font-['Space_Grotesk']">
              {t.footer.shopLinks}
            </h4>
            <ul className="space-y-2 text-xs text-slate-400">
              <li><a href="#" className="hover:text-[#00e599] transition-colors">{t.categories.all}</a></li>
              <li><a href="#" className="hover:text-[#00e599] transition-colors">{t.categories.men}</a></li>
              <li><a href="#" className="hover:text-[#00e599] transition-colors">{t.categories.women}</a></li>
              <li><a href="#" className="hover:text-[#00e599] transition-colors">{t.categories.compression}</a></li>
              <li><a href="#" className="hover:text-[#00e599] transition-colors">{t.categories.hoodies}</a></li>
              <li><a href="#" className="hover:text-[#00e599] transition-colors">{t.categories.accessories}</a></li>
            </ul>
          </div>

          {/* Column: Care & Shipping */}
          <div className="md:col-span-3">
            <h4 className="text-xs font-bold text-white uppercase tracking-wider mb-4 font-['Space_Grotesk']">
              {t.footer.helpLinks}
            </h4>
            <ul className="space-y-2 text-xs text-slate-400">
              <li><a href="#" className="hover:text-[#00e599] transition-colors">{t.footer.shippingInfo}</a></li>
              <li><a href="#" className="hover:text-[#00e599] transition-colors">{t.footer.returns}</a></li>
              <li><a href="#" className="hover:text-[#00e599] transition-colors">{t.nav.sizeAdvisor}</a></li>
              <li><a href="#" className="hover:text-[#00e599] transition-colors">{t.footer.privacy}</a></li>
              <li><a href="#" className="hover:text-[#00e599] transition-colors">{t.footer.terms}</a></li>
            </ul>
          </div>

          {/* Column: App Integration */}
          <div className="md:col-span-2">
            <h4 className="text-xs font-bold text-white uppercase tracking-wider mb-4 font-['Space_Grotesk']">
              Aura App
            </h4>
            <p className="text-[11px] text-slate-400 leading-relaxed mb-3">
              Scan your garment label with the Aura Mobile App to sync workouts and track macro goals.
            </p>
            <div className="inline-block bg-[#14231b] border border-[#00e599]/30 text-[#00e599] text-[10px] font-bold px-2.5 py-1 rounded-md">
              Google Play & App Store
            </div>
          </div>

        </div>

        {/* Bottom Bar */}
        <div className="pt-10 mt-10 border-t border-white/10 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-slate-500">
          <p>{t.footer.copyright}</p>
          <div className="flex items-center gap-3 text-slate-400">
            <span>Powered by Gemini 2.0 & Ollama</span>
            <span>•</span>
            <span className="flex items-center gap-1 text-[#00e599]">
              <span>Made with</span>
              <Heart className="w-3 h-3 fill-current" />
              <span>for Athletes</span>
            </span>
          </div>
        </div>

      </div>
    </footer>
  );
};

