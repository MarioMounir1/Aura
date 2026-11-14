import { useState, useMemo, useRef } from 'react';
import { StoreProvider, useStore } from './context/StoreContext';
import { products } from './data/products';
import type { Category } from './types';
import { Navbar } from './components/Navbar';
import { Hero } from './components/Hero';
import { CategoryFilter } from './components/CategoryFilter';
import { ProductCard } from './components/ProductCard';
import { ProductModal } from './components/ProductModal';
import { SizeAdvisorModal } from './components/SizeAdvisorModal';
import { CartDrawer } from './components/CartDrawer';
import { CheckoutModal } from './components/CheckoutModal';
import { AuraEcosystemBanner } from './components/AuraEcosystemBanner';
import { TechFeatures } from './components/TechFeatures';
import { LookbookCommunity } from './components/LookbookCommunity';
import { Footer } from './components/Footer';

function StoreMain() {
  const { currency } = useStore();
  const [selectedCategory, setSelectedCategory] = useState<Category>('all');
  const [sortBy, setSortBy] = useState<string>('featured');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const collectionRef = useRef<HTMLDivElement>(null);

  const scrollToCollection = () => {
    collectionRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  // Filtered and Sorted Products
  const filteredProducts = useMemo(() => {
    let list = [...products];

    // Filter by Category
    if (selectedCategory !== 'all') {
      list = list.filter((p) => p.category === selectedCategory);
    }

    // Filter by Search Query
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase().trim();
      list = list.filter((p) => {
        return (
          p.titleEn.toLowerCase().includes(q) ||
          p.titleAr.toLowerCase().includes(q) ||
          p.subtitleEn.toLowerCase().includes(q) ||
          p.subtitleAr.toLowerCase().includes(q) ||
          p.descriptionEn.toLowerCase().includes(q) ||
          p.descriptionAr.toLowerCase().includes(q) ||
          p.technologyBadge.toLowerCase().includes(q)
        );
      });
    }

    // Sorting
    if (sortBy === 'price-asc') {
      list.sort((a, b) => {
        const pA = currency === 'EGP' ? a.priceEGP : a.priceUSD;
        const pB = currency === 'EGP' ? b.priceEGP : b.priceUSD;
        return pA - pB;
      });
    } else if (sortBy === 'price-desc') {
      list.sort((a, b) => {
        const pA = currency === 'EGP' ? a.priceEGP : a.priceUSD;
        const pB = currency === 'EGP' ? b.priceEGP : b.priceUSD;
        return pB - pA;
      });
    } else if (sortBy === 'rating') {
      list.sort((a, b) => b.rating - a.rating);
    }

    return list;
  }, [selectedCategory, searchQuery, sortBy, currency]);

  return (
    <div className="min-h-screen flex flex-col bg-[#090c15] text-white selection:bg-[#10b981] selection:text-white">
      {/* Sticky Header */}
      <Navbar
        searchQuery={searchQuery}
        setSearchQuery={setSearchQuery}
        selectedCategory={selectedCategory}
        setSelectedCategory={setSelectedCategory}
      />

      <main className="flex-1">
        {/* Hero Section */}
        <Hero onShopClick={scrollToCollection} />

        {/* Product Catalog Section */}
        <section ref={collectionRef} className="py-12 max-w-7xl mx-auto px-4 lg:px-8">
          <CategoryFilter
            selectedCategory={selectedCategory}
            setSelectedCategory={setSelectedCategory}
            sortBy={sortBy}
            setSortBy={setSortBy}
            itemCount={filteredProducts.length}
          />

          {filteredProducts.length === 0 ? (
            <div className="text-center py-20 bg-[#121824] rounded-[20px] border border-[#222b3f] my-8">
              <h3 className="text-xl font-bold text-white mb-2 font-['Plus_Jakarta_Sans']">No matching sportswear found</h3>
              <p className="text-xs text-[#8e929c] mb-6">Try searching for compression, leggings, hoodies, or clear the search query.</p>
              <button
                onClick={() => {
                  setSearchQuery('');
                  setSelectedCategory('all');
                }}
                className="px-6 py-2.5 aura-btn-primary text-white font-bold text-xs rounded-xl cursor-pointer"
              >
                Reset Filters
              </button>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              {filteredProducts.map((product) => (
                <ProductCard key={product.id} product={product} />
              ))}
            </div>
          )}
        </section>

        {/* Connected Activewear Ecosystem Banner */}
        <AuraEcosystemBanner />

        {/* Laboratory & Technical Innovation Grid */}
        <TechFeatures />

        {/* Athletes & Community Lookbook */}
        <LookbookCommunity />
      </main>

      {/* Footer */}
      <Footer />

      {/* Global Modals & Drawers */}
      <ProductModal />
      <SizeAdvisorModal />
      <CartDrawer />
      <CheckoutModal />
    </div>
  );
}

export default function App() {
  return (
    <StoreProvider>
      <StoreMain />
    </StoreProvider>
  );
}
