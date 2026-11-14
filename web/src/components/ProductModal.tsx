import React, { useState } from 'react';
import { useStore } from '../context/StoreContext';
import { 
  X, 
  Star, 
  ShoppingBag, 
  Check, 
  Sparkles, 
  Truck, 
  RotateCcw,
  Ruler
} from 'lucide-react';
import type { ProductColor } from '../types';

export const ProductModal: React.FC = () => {
  const { 
    activeQuickView, 
    setActiveQuickView, 
    language, 
    addToCart, 
    formatPrice,
    setIsSizeAdvisorOpen,
    t 
  } = useStore();

  if (!activeQuickView) return null;

  const product = activeQuickView;
  const [selectedImage, setSelectedImage] = useState<string>(product.images[0]);
  const [selectedColor, setSelectedColor] = useState<ProductColor>(product.colors[0]);
  const [selectedSize, setSelectedSize] = useState<string>(product.sizes[0] || 'M');
  const [quantity, setQuantity] = useState<number>(1);
  const [showSizeTable, setShowSizeTable] = useState<boolean>(false);
  const [added, setAdded] = useState<boolean>(false);

  const title = language === 'ar' ? product.titleAr : product.titleEn;
  const subtitle = language === 'ar' ? product.subtitleAr : product.subtitleEn;
  const description = language === 'ar' ? product.descriptionAr : product.descriptionEn;
  const fabric = language === 'ar' ? product.fabricAr : product.fabricEn;
  const features = language === 'ar' ? product.featuresAr : product.featuresEn;

  const handleAdd = () => {
    addToCart(product, selectedColor, selectedSize, quantity);
    setAdded(true);
    setTimeout(() => {
      setAdded(false);
      setActiveQuickView(null);
    }, 1200);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 overflow-y-auto bg-black/85 backdrop-blur-md animate-in fade-in">
      <div 
        className="relative w-full max-w-4xl bg-[#121824] border border-[#222b3f] rounded-[24px] overflow-hidden shadow-2xl my-auto text-start"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close Button */}
        <button
          onClick={() => setActiveQuickView(null)}
          className="absolute top-4 end-4 z-20 p-2 rounded-xl bg-[#1b2232] hover:bg-[#222b3f] text-[#8e929c] hover:text-white border border-[#222b3f] transition-all cursor-pointer"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="grid grid-cols-1 md:grid-cols-2 max-h-[85vh] overflow-y-auto">
          
          {/* Left Column: Image Gallery */}
          <div className="p-6 bg-[#090c15] flex flex-col gap-4">
            <div className="relative aspect-[4/5] rounded-[20px] overflow-hidden bg-[#121824] border border-[#222b3f]">
              <img
                src={selectedImage}
                alt={title}
                className="w-full h-full object-cover"
              />
              <div className="absolute top-3 start-3">
                <span className="bg-[#1b2232]/90 backdrop-blur-md text-[#10b981] border border-[#222b3f] text-[10px] font-bold px-3 py-1 rounded-full uppercase tracking-wider">
                  {product.technologyBadge}
                </span>
              </div>
            </div>

            {/* Thumbnail selector */}
            <div className="flex items-center gap-2 overflow-x-auto pb-1">
              {product.images.map((img, idx) => (
                <button
                  key={idx}
                  onClick={() => setSelectedImage(img)}
                  className={`w-16 h-20 rounded-xl overflow-hidden border-2 transition-all cursor-pointer ${
                    selectedImage === img ? 'border-[#10b981] scale-105' : 'border-[#222b3f] opacity-70 hover:opacity-100'
                  }`}
                >
                  <img src={img} alt={`thumb-${idx}`} className="w-full h-full object-cover" />
                </button>
              ))}
            </div>

            {/* Guarantees */}
            <div className="grid grid-cols-2 gap-3 pt-3 border-t border-[#222b3f] text-[11px] text-[#8e929c]">
              <div className="flex items-center gap-2">
                <Truck className="w-4 h-4 text-[#10b981]" />
                <span>Express Worldwide Shipping</span>
              </div>
              <div className="flex items-center gap-2">
                <RotateCcw className="w-4 h-4 text-[#10b981]" />
                <span>30-Day Free Athletic Trial</span>
              </div>
            </div>
          </div>

          {/* Right Column: Specifications & Add to Cart */}
          <div className="p-6 md:p-8 flex flex-col justify-between gap-5 bg-[#121824]">
            <div>
              {/* Rating */}
              <div className="flex items-center gap-1.5 text-xs text-amber-400 mb-2">
                <Star className="w-4 h-4 fill-amber-400 text-amber-400" />
                <span className="font-bold text-white">{product.rating}</span>
                <span className="text-[#8e929c]">({product.reviewsCount} {t.product.reviews})</span>
              </div>

              {/* Title & Subtitle */}
              <h2 className="text-2xl font-black text-white font-['Plus_Jakarta_Sans'] leading-tight">
                {title}
              </h2>
              <p className="text-xs text-[#10b981] font-semibold mt-1">
                {subtitle}
              </p>

              {/* Pricing */}
              <div className="flex items-baseline gap-3 my-4">
                <span className="text-2xl font-black text-white font-['Plus_Jakarta_Sans']">
                  {formatPrice(product.priceUSD, product.priceEGP)}
                </span>
                {product.originalPriceUSD && (
                  <span className="text-sm text-[#5d616b] line-through">
                    {formatPrice(product.originalPriceUSD, product.originalPriceEGP || 0)}
                  </span>
                )}
              </div>

              {/* Description */}
              <p className="text-xs text-[#8e929c] leading-relaxed mb-4">
                {description}
              </p>

              {/* Color Picker */}
              <div className="mb-4">
                <div className="text-xs font-semibold text-slate-200 mb-2 flex items-center justify-between">
                  <span>{t.product.color}: <strong className="text-[#10b981]">{language === 'ar' ? selectedColor.nameAr : selectedColor.name}</strong></span>
                </div>
                <div className="flex items-center gap-2.5">
                  {product.colors.map((color) => (
                    <button
                      key={color.name}
                      onClick={() => {
                        setSelectedColor(color);
                        if (color.image) setSelectedImage(color.image);
                      }}
                      className={`w-7 h-7 rounded-full border-2 transition-all cursor-pointer ${
                        selectedColor.name === color.name
                          ? 'border-[#10b981] scale-110 shadow-md shadow-[#10b981]/30'
                          : 'border-white/20 hover:scale-105'
                      }`}
                      style={{ backgroundColor: color.hex }}
                    />
                  ))}
                </div>
              </div>

              {/* Size Picker + Size Advisor Shortcut */}
              <div className="mb-4">
                <div className="text-xs font-semibold text-slate-200 mb-2 flex items-center justify-between">
                  <span>{t.product.size}: <strong className="text-white">{selectedSize}</strong></span>
                  <div className="flex items-center gap-3">
                    <button
                      onClick={() => setShowSizeTable(!showSizeTable)}
                      className="text-[11px] text-[#8e929c] hover:text-white underline cursor-pointer"
                    >
                      {t.product.sizeGuideTitle}
                    </button>
                    <button
                      onClick={() => {
                        setActiveQuickView(null);
                        setIsSizeAdvisorOpen(true);
                      }}
                      className="text-[11px] text-[#10b981] hover:underline flex items-center gap-1 cursor-pointer"
                    >
                      <Ruler className="w-3 h-3" />
                      <span>{t.nav.sizeAdvisor}</span>
                    </button>
                  </div>
                </div>

                <div className="flex flex-wrap items-center gap-2">
                  {product.sizes.map((sz) => (
                    <button
                      key={sz}
                      onClick={() => setSelectedSize(sz)}
                      className={`px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                        selectedSize === sz
                          ? 'aura-btn-primary text-white shadow-md'
                          : 'bg-[#1b2232] text-[#8e929c] hover:text-white border border-[#222b3f]'
                      }`}
                    >
                      {sz}
                    </button>
                  ))}
                </div>

                {/* Inline Size Chart Drawer */}
                {showSizeTable && (
                  <div className="mt-3 p-3 bg-[#090c15] rounded-xl border border-[#222b3f] text-[11px] animate-in fade-in">
                    <table className="w-full text-center text-[#8e929c]">
                      <thead>
                        <tr className="border-b border-[#222b3f] text-white font-bold">
                          <th className="py-1">Size</th>
                          <th>Chest (cm)</th>
                          <th>Waist (cm)</th>
                          <th>Hips (cm)</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-[#222b3f]/50">
                        <tr><td className="py-1 font-bold text-[#10b981]">S</td><td>90-95</td><td>75-80</td><td>90-95</td></tr>
                        <tr><td className="py-1 font-bold text-[#10b981]">M</td><td>96-102</td><td>81-86</td><td>96-101</td></tr>
                        <tr><td className="py-1 font-bold text-[#10b981]">L</td><td>103-109</td><td>87-93</td><td>102-108</td></tr>
                        <tr><td className="py-1 font-bold text-[#10b981]">XL</td><td>110-118</td><td>94-102</td><td>109-116</td></tr>
                      </tbody>
                    </table>
                  </div>
                )}
              </div>

              {/* Quantity */}
              <div className="flex items-center gap-3 mb-5">
                <span className="text-xs text-[#8e929c] font-medium">Quantity:</span>
                <div className="flex items-center border border-[#222b3f] rounded-xl bg-[#1b2232] overflow-hidden">
                  <button
                    onClick={() => setQuantity((q) => Math.max(1, q - 1))}
                    className="px-3 py-1.5 text-[#8e929c] hover:text-white text-xs font-bold cursor-pointer"
                  >
                    -
                  </button>
                  <span className="px-3 text-xs font-black text-white">{quantity}</span>
                  <button
                    onClick={() => setQuantity((q) => q + 1)}
                    className="px-3 py-1.5 text-[#8e929c] hover:text-white text-xs font-bold cursor-pointer"
                  >
                    +
                  </button>
                </div>
              </div>

              {/* Key Features List */}
              <div className="p-3 bg-[#1b2232] rounded-xl border border-[#222b3f] mb-4">
                <div className="text-[11px] font-bold text-[#10b981] uppercase tracking-wider mb-1.5 flex items-center gap-1.5">
                  <Sparkles className="w-3.5 h-3.5" />
                  <span>{t.product.keyHighlights}</span>
                </div>
                <ul className="space-y-1 text-[11px] text-[#8e929c]">
                  {features.map((feat, idx) => (
                    <li key={idx} className="flex items-start gap-1.5">
                      <span className="text-[#10b981] font-bold">✓</span>
                      <span>{feat}</span>
                    </li>
                  ))}
                </ul>
              </div>

              {/* Fabric Details */}
              <div className="text-[11px] text-[#8e929c]">
                <strong className="text-slate-300">{t.product.fabricAndCare}:</strong> {fabric}
              </div>
            </div>

            {/* Add to Bag Action */}
            <div className="pt-4 border-t border-[#222b3f]">
              <button
                onClick={handleAdd}
                className={`w-full py-4 rounded-xl font-black text-sm flex items-center justify-center gap-2 shadow-lg transition-all cursor-pointer ${
                  added
                    ? 'bg-emerald-600 text-white'
                    : 'aura-btn-primary hover:scale-[1.02] active:scale-95'
                }`}
              >
                {added ? (
                  <>
                    <Check className="w-5 h-5 text-white" />
                    <span className="text-white">{t.product.addedToCart}</span>
                  </>
                ) : (
                  <>
                    <ShoppingBag className="w-5 h-5 text-white" />
                    <span className="text-white">{t.product.addToBag} — {formatPrice(product.priceUSD * quantity, product.priceEGP * quantity)}</span>
                  </>
                )}
              </button>
            </div>

          </div>

        </div>
      </div>
    </div>
  );
};
