import React from 'react';
import { useStore } from '../context/StoreContext';
import type { Category } from '../types';
import { SlidersHorizontal } from 'lucide-react';

interface CategoryFilterProps {
  selectedCategory: Category;
  setSelectedCategory: (cat: Category) => void;
  sortBy: string;
  setSortBy: (sort: string) => void;
  itemCount: number;
}

export const CategoryFilter: React.FC<CategoryFilterProps> = ({
  selectedCategory,
  setSelectedCategory,
  sortBy,
  setSortBy,
  itemCount,
}) => {
  const { t } = useStore();

  const categories: { id: Category; label: string }[] = [
    { id: 'all', label: t.categories.all },
    { id: 'men', label: t.categories.men },
    { id: 'women', label: t.categories.women },
    { id: 'compression', label: t.categories.compression },
    { id: 'hoodies', label: t.categories.hoodies },
    { id: 'accessories', label: t.categories.accessories },
  ];

  return (
    <div className="py-6 border-b border-[#222b3f] mb-8">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        
        {/* Horizontal Category Pill Tabs */}
        <div className="flex items-center gap-2.5 overflow-x-auto pb-2 md:pb-0 scrollbar-none">
          {categories.map((cat) => {
            const isActive = selectedCategory === cat.id;
            return (
              <button
                key={cat.id}
                onClick={() => setSelectedCategory(cat.id)}
                className={`whitespace-nowrap px-4 py-2 rounded-xl text-xs sm:text-sm font-semibold transition-all cursor-pointer ${
                  isActive
                    ? 'aura-btn-primary text-white shadow-md shadow-[#10b981]/25 scale-105'
                    : 'bg-[#1b2232] hover:bg-[#222b3f] text-[#8e929c] hover:text-white border border-[#222b3f]'
                }`}
              >
                {cat.label}
              </button>
            );
          })}
        </div>

        {/* Sort & Count Controls */}
        <div className="flex items-center justify-between md:justify-end gap-3 shrink-0">
          <span className="text-xs text-[#8e929c] font-medium">
            <span className="text-[#10b981] font-bold">{itemCount}</span> {t.filter.resultsCount}
          </span>

          <div className="flex items-center gap-2 bg-[#1b2232] border border-[#222b3f] rounded-xl px-3 py-2 text-xs text-slate-300">
            <SlidersHorizontal className="w-3.5 h-3.5 text-[#8e929c]" />
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              className="bg-transparent text-xs font-semibold text-white outline-none cursor-pointer"
            >
              <option value="featured" className="bg-[#121824] text-white">{t.filter.featured}</option>
              <option value="price-asc" className="bg-[#121824] text-white">{t.filter.priceLowHigh}</option>
              <option value="price-desc" className="bg-[#121824] text-white">{t.filter.priceHighLow}</option>
              <option value="rating" className="bg-[#121824] text-white">{t.filter.rating}</option>
            </select>
          </div>
        </div>

      </div>
    </div>
  );
};
