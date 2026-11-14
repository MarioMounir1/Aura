import React, { useState } from 'react';
import { useStore } from '../context/StoreContext';
import { 
  ShoppingBag, 
  Heart, 
  Globe, 
  Search, 
  Sparkles, 
  Ruler, 
  Menu, 
  X,
  Flame
} from 'lucide-react';

interface NavbarProps {
  searchQuery: string;
  setSearchQuery: (q: string) => void;
  selectedCategory: string;
  setSelectedCategory: (cat: any) => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  searchQuery,
  setSearchQuery,
  selectedCategory,
  setSelectedCategory,
}) => {
  const { 
    language, 
    setLanguage, 
    currency, 
    setCurrency, 
    t, 
    cartCount, 
    setIsCartOpen, 
    setIsSizeAdvisorOpen,
    wishlist 
  } = useStore();

  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [showSearchInput, setShowSearchInput] = useState(false);

  const toggleLanguage = () => {
    setLanguage(language === 'en' ? 'ar' : 'en');
  };

  return (
    <header className="sticky top-0 z-40 w-full">
      {/* Top Announcement Bar */}
      <div className="bg-gradient-to-r from-[#14231b] via-[#1e3a2b] to-[#14231b] text-xs py-2 px-4 text-center font-medium border-b border-[#00e599]/20 text-[#a8f5d7] flex items-center justify-center gap-2">
        <Sparkles className="w-3.5 h-3.5 text-[#00e599] animate-pulse" />
        <span>{t.announcement}</span>
      </div>

      {/* Main Glass Navigation Bar */}
      <nav className="aura-glass border-b border-white/10 px-4 lg:px-8 py-3.5 transition-all">
        <div className="max-w-7xl mx-auto flex items-center justify-between gap-4">
          
          {/* Mobile Hamburger + Brand Logo */}
          <div className="flex items-center gap-3">
            <button 
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="lg:hidden text-slate-300 hover:text-white p-1"
              aria-label="Toggle menu"
            >
              {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>

            {/* Logo */}
            <a href="#" className="flex items-center gap-2.5 group">
              <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-[#00e599] to-[#1e3a2b] flex items-center justify-center shadow-lg shadow-[#00e599]/20 group-hover:scale-105 transition-transform">
                <span className="font-extrabold text-black text-lg tracking-tighter">A</span>
              </div>
              <div className="flex flex-col">
                <div className="flex items-center gap-1.5 leading-none">
                  <span className="font-black text-lg tracking-wider text-white font-['Space_Grotesk']">{t.brandName}</span>
                  <span className="text-[11px] font-bold tracking-widest text-[#00e599] uppercase bg-[#00e599]/10 px-1.5 py-0.5 rounded border border-[#00e599]/30">
                    {t.brandSuffix}
                  </span>
                </div>
                <span className="text-[9px] tracking-wider text-slate-400 font-medium uppercase mt-0.5">
                  Sportswear & Activewear
                </span>
              </div>
            </a>
          </div>

          {/* Desktop Nav Links */}
          <div className="hidden lg:flex items-center gap-7 text-sm font-medium">
            <button
              onClick={() => { setSelectedCategory('all'); }}
              className={`transition-colors hover:text-[#00e599] ${selectedCategory === 'all' ? 'text-[#00e599] font-bold' : 'text-slate-300'}`}
            >
              {t.nav.newDrops}
            </button>
            <button
              onClick={() => setSelectedCategory('men')}
              className={`transition-colors hover:text-[#00e599] ${selectedCategory === 'men' ? 'text-[#00e599] font-bold' : 'text-slate-300'}`}
            >
              {t.nav.men}
            </button>
            <button
              onClick={() => setSelectedCategory('women')}
              className={`transition-colors hover:text-[#00e599] ${selectedCategory === 'women' ? 'text-[#00e599] font-bold' : 'text-slate-300'}`}
            >
              {t.nav.women}
            </button>
            <button
              onClick={() => setSelectedCategory('compression')}
              className={`flex items-center gap-1 transition-colors hover:text-[#00e599] ${selectedCategory === 'compression' ? 'text-[#00e599] font-bold' : 'text-slate-300'}`}
            >
              <Flame className="w-3.5 h-3.5 text-[#00e599]" />
              {t.nav.compression}
            </button>
            <a
              href="#ecosystem-sync"
              className="text-slate-300 hover:text-[#00e599] transition-colors"
            >
              {t.nav.appSync}
            </a>
            <a
              href="#technology"
              className="text-slate-300 hover:text-[#00e599] transition-colors"
            >
              {t.nav.technology}
            </a>
          </div>

          {/* Controls: Search, Size Advisor, Currency, Language, Wishlist, Cart */}
          <div className="flex items-center gap-2.5 sm:gap-3.5">
            {/* Search Input / Toggle */}
            <div className="relative">
              {showSearchInput ? (
                <div className="flex items-center bg-[#141c18] border border-[#00e599]/40 rounded-full px-3 py-1.5 w-44 sm:w-60 transition-all">
                  <Search className="w-4 h-4 text-slate-400 shrink-0" />
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder={t.nav.searchPlaceholder}
                    className="bg-transparent border-none outline-none text-xs text-white placeholder-slate-500 w-full px-2"
                    autoFocus
                  />
                  <button onClick={() => { setShowSearchInput(false); setSearchQuery(''); }} className="text-slate-400 hover:text-white text-xs">
                    ✕
                  </button>
                </div>
              ) : (
                <button
                  onClick={() => setShowSearchInput(true)}
                  className="p-2 text-slate-300 hover:text-[#00e599] hover:bg-white/5 rounded-full transition-colors"
                  title="Search"
                >
                  <Search className="w-4.5 h-4.5" />
                </button>
              )}
            </div>

            {/* Smart Size Advisor Trigger */}
            <button
              onClick={() => setIsSizeAdvisorOpen(true)}
              className="hidden md:flex items-center gap-1.5 text-xs font-semibold bg-[#1a2c22] hover:bg-[#233f30] text-[#00e599] px-3 py-1.5 rounded-full border border-[#00e599]/30 transition-all shadow-sm"
            >
              <Ruler className="w-3.5 h-3.5" />
              <span>{t.nav.sizeAdvisor}</span>
            </button>

            {/* Currency Selector */}
            <select
              value={currency}
              onChange={(e) => setCurrency(e.target.value as any)}
              className="bg-[#141c18] text-xs font-semibold text-slate-300 hover:text-white border border-white/10 rounded-lg px-2 py-1 outline-none cursor-pointer"
            >
              <option value="USD">USD ($)</option>
              <option value="EGP">EGP (ج.م)</option>
              <option value="EUR">EUR (€)</option>
            </select>

            {/* Language Toggle */}
            <button
              onClick={toggleLanguage}
              className="flex items-center gap-1 text-xs font-bold bg-[#141c18] hover:bg-white/10 text-slate-300 hover:text-white border border-white/10 px-2.5 py-1 rounded-lg transition-colors"
              title="Switch Language"
            >
              <Globe className="w-3.5 h-3.5 text-[#00e599]" />
              <span>{language === 'en' ? 'عربي' : 'EN'}</span>
            </button>

            {/* Wishlist */}
            <div className="relative">
              <button
                className="p-2 text-slate-300 hover:text-[#00e599] hover:bg-white/5 rounded-full transition-colors"
                title={t.nav.wishlist}
              >
                <Heart className="w-5 h-5" />
                {wishlist.length > 0 && (
                  <span className="absolute top-1 right-1 w-4 h-4 bg-rose-500 text-white rounded-full text-[10px] font-bold flex items-center justify-center">
                    {wishlist.length}
                  </span>
                )}
              </button>
            </div>

            {/* Cart Button */}
            <button
              onClick={() => setIsCartOpen(true)}
              className="relative flex items-center gap-2 bg-[#00e599] hover:bg-[#00c985] text-black font-bold text-xs px-3.5 py-2 rounded-xl transition-all shadow-md shadow-[#00e599]/20 hover:scale-105 active:scale-95"
            >
              <ShoppingBag className="w-4 h-4" />
              <span className="hidden sm:inline">{t.nav.cart}</span>
              <span className="bg-black text-[#00e599] rounded-full text-[11px] px-1.5 py-0.2 min-w-4 text-center font-black">
                {cartCount}
              </span>
            </button>
          </div>
        </div>

        {/* Mobile Dropdown Menu */}
        {mobileMenuOpen && (
          <div className="lg:hidden border-t border-white/10 mt-3 pt-3 flex flex-col gap-2.5 pb-2 animate-in fade-in slide-in-from-top-2">
            <button
              onClick={() => { setSelectedCategory('all'); setMobileMenuOpen(false); }}
              className={`text-start px-3 py-2 rounded-lg text-sm font-medium ${selectedCategory === 'all' ? 'bg-[#1e3a2b] text-[#00e599]' : 'text-slate-300'}`}
            >
              {t.nav.newDrops}
            </button>
            <button
              onClick={() => { setSelectedCategory('men'); setMobileMenuOpen(false); }}
              className={`text-start px-3 py-2 rounded-lg text-sm font-medium ${selectedCategory === 'men' ? 'bg-[#1e3a2b] text-[#00e599]' : 'text-slate-300'}`}
            >
              {t.nav.men}
            </button>
            <button
              onClick={() => { setSelectedCategory('women'); setMobileMenuOpen(false); }}
              className={`text-start px-3 py-2 rounded-lg text-sm font-medium ${selectedCategory === 'women' ? 'bg-[#1e3a2b] text-[#00e599]' : 'text-slate-300'}`}
            >
              {t.nav.women}
            </button>
            <button
              onClick={() => { setSelectedCategory('compression'); setMobileMenuOpen(false); }}
              className={`text-start px-3 py-2 rounded-lg text-sm font-medium ${selectedCategory === 'compression' ? 'bg-[#1e3a2b] text-[#00e599]' : 'text-slate-300'}`}
            >
              {t.nav.compression}
            </button>
            <button
              onClick={() => { setIsSizeAdvisorOpen(true); setMobileMenuOpen(false); }}
              className="text-start px-3 py-2 rounded-lg text-sm font-semibold text-[#00e599] flex items-center gap-2"
            >
              <Ruler className="w-4 h-4" />
              {t.nav.sizeAdvisor}
            </button>
          </div>
        )}
      </nav>
    </header>
  );
};

