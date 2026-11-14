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
      <div className="bg-[#090c15] text-xs py-2 px-4 text-center font-medium border-b border-[#222b3f] text-[#8e929c] flex items-center justify-center gap-2">
        <Sparkles className="w-3.5 h-3.5 text-[#10b981] animate-pulse" />
        <span className="text-slate-300">{t.announcement}</span>
      </div>

      {/* Main Glass Navigation Bar */}
      <nav className="bg-[#121824]/90 backdrop-blur-md border-b border-[#222b3f] px-4 lg:px-8 py-3 transition-all">
        <div className="max-w-7xl mx-auto flex items-center justify-between gap-4">
          
          {/* Mobile Hamburger + Brand Logo */}
          <div className="flex items-center gap-3">
            <button 
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="lg:hidden text-[#8e929c] hover:text-white p-1"
              aria-label="Toggle menu"
            >
              {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>

            {/* Official Aura Logo from Mobile App */}
            <a href="#" className="flex items-center gap-3 group">
              <img 
                src="/aura_logo.png" 
                alt="Aura Logo" 
                className="h-9 w-auto object-contain filter drop-shadow group-hover:scale-105 transition-transform" 
                onError={(e) => {
                  // Fallback if image path differs
                  (e.target as HTMLElement).style.display = 'none';
                }}
              />
              <div className="flex flex-col">
                <div className="flex items-center gap-1.5 leading-none">
                  <span className="font-extrabold text-lg tracking-wider text-white font-['Plus_Jakarta_Sans']">
                    {t.brandName}
                  </span>
                  <span className="text-[10px] font-bold tracking-widest text-[#10b981] uppercase bg-[#10b981]/15 px-1.5 py-0.5 rounded border border-[#10b981]/30">
                    {t.brandSuffix}
                  </span>
                </div>
                <span className="text-[9px] tracking-wider text-[#8e929c] font-medium uppercase mt-0.5">
                  Nutrition & Fitness Activewear
                </span>
              </div>
            </a>
          </div>

          {/* Desktop Nav Links */}
          <div className="hidden lg:flex items-center gap-7 text-sm font-medium">
            <button
              onClick={() => { setSelectedCategory('all'); }}
              className={`transition-colors hover:text-[#10b981] ${selectedCategory === 'all' ? 'text-[#10b981] font-bold' : 'text-[#8e929c]'}`}
            >
              {t.nav.newDrops}
            </button>
            <button
              onClick={() => setSelectedCategory('men')}
              className={`transition-colors hover:text-[#10b981] ${selectedCategory === 'men' ? 'text-[#10b981] font-bold' : 'text-[#8e929c]'}`}
            >
              {t.nav.men}
            </button>
            <button
              onClick={() => setSelectedCategory('women')}
              className={`transition-colors hover:text-[#10b981] ${selectedCategory === 'women' ? 'text-[#10b981] font-bold' : 'text-[#8e929c]'}`}
            >
              {t.nav.women}
            </button>
            <button
              onClick={() => setSelectedCategory('compression')}
              className={`flex items-center gap-1 transition-colors hover:text-[#10b981] ${selectedCategory === 'compression' ? 'text-[#10b981] font-bold' : 'text-[#8e929c]'}`}
            >
              <Flame className="w-3.5 h-3.5 text-[#10b981]" />
              {t.nav.compression}
            </button>
            <a
              href="#ecosystem-sync"
              className="text-[#8e929c] hover:text-[#10b981] transition-colors"
            >
              {t.nav.appSync}
            </a>
            <a
              href="#technology"
              className="text-[#8e929c] hover:text-[#10b981] transition-colors"
            >
              {t.nav.technology}
            </a>
          </div>

          {/* Controls: Search, Size Advisor, Currency, Language, Wishlist, Cart */}
          <div className="flex items-center gap-2.5 sm:gap-3.5">
            {/* Search Input / Toggle */}
            <div className="relative">
              {showSearchInput ? (
                <div className="flex items-center bg-[#1b2232] border border-[#222b3f] rounded-xl px-3 py-1.5 w-44 sm:w-60 transition-all focus-within:border-[#10b981]">
                  <Search className="w-4 h-4 text-[#8e929c] shrink-0" />
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder={t.nav.searchPlaceholder}
                    className="bg-transparent border-none outline-none text-xs text-white placeholder-[#5d616b] w-full px-2"
                    autoFocus
                  />
                  <button onClick={() => { setShowSearchInput(false); setSearchQuery(''); }} className="text-[#8e929c] hover:text-white text-xs">
                    ✕
                  </button>
                </div>
              ) : (
                <button
                  onClick={() => setShowSearchInput(true)}
                  className="p-2 text-[#8e929c] hover:text-[#10b981] hover:bg-[#1b2232] rounded-xl transition-colors border border-transparent hover:border-[#222b3f]"
                  title="Search"
                >
                  <Search className="w-4.5 h-4.5" />
                </button>
              )}
            </div>

            {/* Smart Size Advisor Trigger */}
            <button
              onClick={() => setIsSizeAdvisorOpen(true)}
              className="hidden md:flex items-center gap-1.5 text-xs font-semibold bg-[#1b2232] hover:bg-[#222b3f] text-[#10b981] px-3.5 py-2 rounded-xl border border-[#222b3f] transition-all shadow-sm"
            >
              <Ruler className="w-3.5 h-3.5" />
              <span>{t.nav.sizeAdvisor}</span>
            </button>

            {/* Currency Selector */}
            <select
              value={currency}
              onChange={(e) => setCurrency(e.target.value as any)}
              className="bg-[#1b2232] text-xs font-semibold text-slate-200 hover:text-white border border-[#222b3f] rounded-xl px-2.5 py-1.5 outline-none cursor-pointer"
            >
              <option value="USD" className="bg-[#121824] text-white">USD ($)</option>
              <option value="EGP" className="bg-[#121824] text-white">EGP (ج.م)</option>
              <option value="EUR" className="bg-[#121824] text-white">EUR (€)</option>
            </select>

            {/* Language Toggle */}
            <button
              onClick={toggleLanguage}
              className="flex items-center gap-1.5 text-xs font-bold bg-[#1b2232] hover:bg-[#222b3f] text-slate-200 hover:text-white border border-[#222b3f] px-2.5 py-1.5 rounded-xl transition-colors"
              title="Switch Language"
            >
              <Globe className="w-3.5 h-3.5 text-[#10b981]" />
              <span>{language === 'en' ? 'عربي' : 'EN'}</span>
            </button>

            {/* Wishlist */}
            <div className="relative">
              <button
                className="p-2 text-[#8e929c] hover:text-[#10b981] hover:bg-[#1b2232] rounded-xl transition-colors border border-transparent hover:border-[#222b3f]"
                title={t.nav.wishlist}
              >
                <Heart className="w-4.5 h-4.5" />
                {wishlist.length > 0 && (
                  <span className="absolute top-1 right-1 w-4 h-4 bg-rose-500 text-white rounded-full text-[10px] font-bold flex items-center justify-center">
                    {wishlist.length}
                  </span>
                )}
              </button>
            </div>

            {/* Cart Button with Aura Snap Meal Gradient */}
            <button
              onClick={() => setIsCartOpen(true)}
              className="relative flex items-center gap-2 aura-btn-primary px-3.5 py-2 text-xs font-bold shadow-md hover:scale-105 active:scale-95 transition-all"
            >
              <ShoppingBag className="w-4 h-4 text-white" />
              <span className="hidden sm:inline text-white">{t.nav.cart}</span>
              <span className="bg-black/40 text-white rounded-full text-[11px] px-1.5 py-0.2 min-w-4 text-center font-bold">
                {cartCount}
              </span>
            </button>
          </div>
        </div>

        {/* Mobile Dropdown Menu */}
        {mobileMenuOpen && (
          <div className="lg:hidden border-t border-[#222b3f] mt-3 pt-3 flex flex-col gap-2 pb-2">
            <button
              onClick={() => { setSelectedCategory('all'); setMobileMenuOpen(false); }}
              className={`text-start px-3 py-2 rounded-xl text-sm font-medium ${selectedCategory === 'all' ? 'bg-[#1b2232] text-[#10b981] font-bold' : 'text-[#8e929c]'}`}
            >
              {t.nav.newDrops}
            </button>
            <button
              onClick={() => { setSelectedCategory('men'); setMobileMenuOpen(false); }}
              className={`text-start px-3 py-2 rounded-xl text-sm font-medium ${selectedCategory === 'men' ? 'bg-[#1b2232] text-[#10b981] font-bold' : 'text-[#8e929c]'}`}
            >
              {t.nav.men}
            </button>
            <button
              onClick={() => { setSelectedCategory('women'); setMobileMenuOpen(false); }}
              className={`text-start px-3 py-2 rounded-xl text-sm font-medium ${selectedCategory === 'women' ? 'bg-[#1b2232] text-[#10b981] font-bold' : 'text-[#8e929c]'}`}
            >
              {t.nav.women}
            </button>
            <button
              onClick={() => { setSelectedCategory('compression'); setMobileMenuOpen(false); }}
              className={`text-start px-3 py-2 rounded-xl text-sm font-medium ${selectedCategory === 'compression' ? 'bg-[#1b2232] text-[#10b981] font-bold' : 'text-[#8e929c]'}`}
            >
              {t.nav.compression}
            </button>
            <button
              onClick={() => { setIsSizeAdvisorOpen(true); setMobileMenuOpen(false); }}
              className="text-start px-3 py-2 rounded-xl text-sm font-semibold text-[#10b981] flex items-center gap-2"
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
