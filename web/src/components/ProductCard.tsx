import React, { useState } from 'react';
import type { Product, ProductColor } from '../types';
import { useStore } from '../context/StoreContext';
import { Heart, Star, Eye, ShoppingBag, Check } from 'lucide-react';

export const ProductCard: React.FC<{ product: Product }> = ({ product }) => {
  const { 
    language, 
    addToCart, 
    setActiveQuickView, 
    toggleWishlist, 
    isInWishlist, 
    formatPrice,
    t
  } = useStore();

  const [selectedColor, setSelectedColor] = useState<ProductColor>(product.colors[0]);
  const [selectedSize, setSelectedSize] = useState<string>(product.sizes[0] || 'M');
  const [isHovered, setIsHovered] = useState(false);
  const [justAdded, setJustAdded] = useState(false);

  const isFavorited = isInWishlist(product.id);

  const handleAddToCart = (e: React.MouseEvent) => {
    e.stopPropagation();
    addToCart(product, selectedColor, selectedSize, 1);
    setJustAdded(true);
    setTimeout(() => setJustAdded(false), 1800);
  };

  const title = language === 'ar' ? product.titleAr : product.titleEn;
  const subtitle = language === 'ar' ? product.subtitleAr : product.subtitleEn;
  const badgeLabel = language === 'ar' ? (product.badgeAr || product.badge) : product.badge;

  // Active image: if color has specific image use it, else secondary hover image
  const displayImage = isHovered && product.images[1] ? product.images[1] : (selectedColor.image || product.images[0]);

  return (
    <div 
      className="group aura-glass-card rounded-2xl overflow-hidden flex flex-col justify-between transition-all duration-300 relative border border-white/10 hover:border-[#00e599]/40"
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      {/* Top Media Area */}
      <div className="relative aspect-[4/5] bg-[#0f1412] overflow-hidden cursor-pointer" onClick={() => setActiveQuickView(product)}>
        <img
          src={displayImage}
          alt={title}
          className="w-full h-full object-cover object-center transform transition-transform duration-700 group-hover:scale-105"
        />

        {/* Dark subtle gradient at top and bottom */}
        <div className="absolute inset-0 bg-gradient-to-t from-[#0e1411] via-transparent to-black/30 pointer-events-none" />

        {/* Badges: Top Start */}
        <div className="absolute top-3 start-3 flex flex-col gap-1.5 z-10">
          {badgeLabel && (
            <span className="bg-[#00e599] text-black text-[10px] font-black px-2.5 py-1 rounded-full uppercase tracking-wider shadow-md">
              {badgeLabel}
            </span>
          )}
          <span className="bg-black/60 backdrop-blur-md text-[#a3f3d3] border border-[#00e599]/30 text-[9px] font-bold px-2 py-0.5 rounded-full">
            {product.technologyBadge}
          </span>
        </div>

        {/* Wishlist Button: Top End */}
        <button
          onClick={(e) => {
            e.stopPropagation();
            toggleWishlist(product.id);
          }}
          className={`absolute top-3 end-3 p-2 rounded-full backdrop-blur-md transition-all z-10 ${
            isFavorited
              ? 'bg-rose-500 text-white'
              : 'bg-black/40 hover:bg-black/70 text-white hover:text-rose-400 border border-white/10'
          }`}
          title="Wishlist"
        >
          <Heart className={`w-4 h-4 ${isFavorited ? 'fill-white' : ''}`} />
        </button>

        {/* Quick View Button on Hover */}
        <div className="absolute inset-x-4 bottom-4 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-300 z-10">
          <button
            onClick={(e) => {
              e.stopPropagation();
              setActiveQuickView(product);
            }}
            className="w-full flex items-center justify-center gap-2 bg-black/80 hover:bg-black text-white text-xs font-bold py-2.5 rounded-xl border border-white/20 backdrop-blur-md shadow-lg"
          >
            <Eye className="w-3.5 h-3.5 text-[#00e599]" />
            <span>{t.product.quickView}</span>
          </button>
        </div>
      </div>

      {/* Product Content Details */}
      <div className="p-4 sm:p-5 flex flex-col flex-grow justify-between gap-3 bg-[#0e1411]">
        
        <div>
          {/* Rating */}
          <div className="flex items-center gap-1.5 text-xs text-amber-400 mb-1.5">
            <div className="flex items-center">
              <Star className="w-3.5 h-3.5 fill-amber-400 text-amber-400" />
            </div>
            <span className="font-bold text-slate-200">{product.rating}</span>
            <span className="text-[11px] text-slate-400">({product.reviewsCount})</span>
          </div>

          {/* Title & Subtitle */}
          <h3 
            onClick={() => setActiveQuickView(product)}
            className="text-sm sm:text-base font-bold text-white group-hover:text-[#00e599] transition-colors cursor-pointer line-clamp-1"
          >
            {title}
          </h3>
          <p className="text-xs text-slate-400 line-clamp-1 mt-0.5">
            {subtitle}
          </p>
        </div>

        {/* Color Swatches */}
        <div className="flex items-center gap-2 pt-1">
          {product.colors.map((color) => (
            <button
              key={color.name}
              onClick={() => setSelectedColor(color)}
              className={`w-5 h-5 rounded-full border-2 transition-all ${
                selectedColor.name === color.name
                  ? 'border-[#00e599] scale-110 shadow-sm shadow-[#00e599]'
                  : 'border-white/20 hover:scale-105'
              }`}
              style={{ backgroundColor: color.hex }}
              title={language === 'ar' ? color.nameAr : color.name}
            />
          ))}
          <span className="text-[11px] text-slate-400 ms-1 font-medium">
            {language === 'ar' ? selectedColor.nameAr : selectedColor.name}
          </span>
        </div>

        {/* Size Pills */}
        <div className="flex flex-wrap items-center gap-1.5">
          {product.sizes.map((size) => (
            <button
              key={size}
              onClick={() => setSelectedSize(size)}
              className={`text-[10px] font-bold px-2 py-1 rounded-md transition-all ${
                selectedSize === size
                  ? 'bg-white text-black font-extrabold shadow-sm'
                  : 'bg-[#18221c] text-slate-400 hover:text-white border border-white/10'
              }`}
            >
              {size}
            </button>
          ))}
        </div>

        {/* Price & Add to Bag CTA */}
        <div className="flex items-center justify-between pt-3 border-t border-white/10 mt-1">
          <div>
            <div className="text-base sm:text-lg font-black text-white font-['Space_Grotesk']">
              {formatPrice(product.priceUSD, product.priceEGP)}
            </div>
            {product.originalPriceUSD && (
              <div className="text-[11px] text-slate-500 line-through">
                {formatPrice(product.originalPriceUSD, product.originalPriceEGP || 0)}
              </div>
            )}
          </div>

          <button
            onClick={handleAddToCart}
            className={`flex items-center gap-1.5 text-xs font-bold px-3.5 py-2 rounded-xl transition-all shadow-md ${
              justAdded
                ? 'bg-emerald-600 text-white'
                : 'bg-[#00e599] hover:bg-[#00c985] text-black shadow-[#00e599]/20 hover:scale-105 active:scale-95'
            }`}
          >
            {justAdded ? (
              <>
                <Check className="w-3.5 h-3.5" />
                <span>{t.product.addedToCart}</span>
              </>
            ) : (
              <>
                <ShoppingBag className="w-3.5 h-3.5" />
                <span>{t.product.addToBag}</span>
              </>
            )}
          </button>
        </div>

      </div>
    </div>
  );
};
