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
    <div className="py-6 border-b border-white/10 mb-8">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        
        {/* Horizontal Category Pill Tabs */}
        <div className="flex items-center gap-2 overflow-x-auto pb-2 md:pb-0 scrollbar-none">
          {categories.map((cat) => {
            const isActive = selectedCategory === cat.id;
            return (
              <button
                key={cat.id}
                onClick={() => setSelectedCategory(cat.id)}
                className={`whitespace-nowrap px-4 py-2 rounded-full text-xs sm:text-sm font-semibold transition-all ${
                  isActive
                    ? 'bg-[#00e599] text-black shadow-lg shadow-[#00e599]/20 font-bold scale-105'
                    : 'bg-[#141c18] hover:bg-white/10 text-slate-300 border border-white/10'
                }`}
              >
                {cat.label}
              </button>
            );
          })}
        </div>

        {/* Sort & Count Controls */}
        <div className="flex items-center justify-between md:justify-end gap-3 shrink-0">
          <span className="text-xs text-slate-400 font-medium">
            <span className="text-[#00e599] font-bold">{itemCount}</span> {t.filter.resultsCount}
          </span>

          <div className="flex items-center gap-2 bg-[#141c18] border border-white/10 rounded-xl px-3 py-1.5 text-xs text-slate-300">
            <SlidersHorizontal className="w-3.5 h-3.5 text-slate-400" />
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              className="bg-transparent text-xs font-semibold text-white outline-none cursor-pointer"
            >
              <option value="featured" className="bg-[#141c18] text-white">{t.filter.featured}</option>
              <option value="price-asc" className="bg-[#141c18] text-white">{t.filter.priceLowHigh}</option>
              <option value="price-desc" className="bg-[#141c18] text-white">{t.filter.priceHighLow}</option>
              <option value="rating" className="bg-[#141c18] text-white">{t.filter.rating}</option>
            </select>
          </div>
        </div>

      </div>
    </div>
  );
};
