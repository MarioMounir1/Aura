import React, { useState } from 'react';
import { useStore } from '../context/StoreContext';
import { 
  X, 
  Trash2, 
  Plus, 
  Minus, 
  ShoppingBag, 
  Truck, 
  Tag, 
  ArrowRight, 
  ArrowLeft,
  Check
} from 'lucide-react';

export const CartDrawer: React.FC = () => {
  const {
    isCartOpen,
    setIsCartOpen,
    cart,
    removeFromCart,
    updateQuantity,
    cartCount,
    cartSubtotal,
    cartDiscount,
    cartTotal,
    appliedPromo,
    applyPromoCode,
    freeShippingThreshold,
    setIsCheckoutOpen,
    formatPrice,
    currency,
    language,
    t
  } = useStore();

  const [inputCode, setInputCode] = useState('');
  const [codeError, setCodeError] = useState(false);
  const ArrowIcon = language === 'ar' ? ArrowLeft : ArrowRight;

  if (!isCartOpen) return null;

  const currentSpend = currency === 'EGP' ? cartSubtotal : cartSubtotal;
  const isFreeShipping = currentSpend >= freeShippingThreshold;
  const remainingForFreeShipping = Math.max(0, freeShippingThreshold - currentSpend);
  const progressPercent = Math.min(100, (currentSpend / freeShippingThreshold) * 100);

  const handleApplyPromo = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputCode.trim()) return;
    const ok = applyPromoCode(inputCode);
    if (!ok) {
      setCodeError(true);
      setTimeout(() => setCodeError(false), 2500);
    } else {
      setInputCode('');
    }
  };

  const handleProceedCheckout = () => {
    setIsCartOpen(false);
    setIsCheckoutOpen(true);
  };

  return (
    <div className="fixed inset-0 z-50 overflow-hidden bg-black/70 backdrop-blur-sm animate-in fade-in">
      <div 
        className="fixed inset-y-0 end-0 max-w-full flex pl-10"
        onClick={() => setIsCartOpen(false)}
      >
        <div 
          className="w-screen max-w-md bg-[#0e1411] border-s border-white/15 flex flex-col justify-between shadow-2xl text-start"
          onClick={(e) => e.stopPropagation()}
        >
          {/* Header */}
          <div className="p-5 border-b border-white/10 flex items-center justify-between bg-[#111914]">
            <div className="flex items-center gap-2">
              <ShoppingBag className="w-5 h-5 text-[#00e599]" />
              <h2 className="text-base font-black text-white font-['Space_Grotesk']">
                {t.cart.title}
              </h2>
              <span className="text-xs font-bold text-slate-400 bg-black/40 px-2 py-0.5 rounded-full border border-white/10">
                {cartCount}
              </span>
            </div>
            <button
              onClick={() => setIsCartOpen(false)}
              className="p-1.5 rounded-full text-slate-400 hover:text-white hover:bg-white/10 transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Free Shipping Dynamic Progress Tracker */}
          <div className="p-4 bg-[#14231b] border-b border-[#00e599]/20">
            <div className="flex items-center gap-2 text-xs font-bold mb-2">
              <Truck className="w-4 h-4 text-[#00e599] shrink-0" />
              {isFreeShipping ? (
                <span className="text-[#00e599]">{t.cart.freeShippingUnlocked}</span>
              ) : (
                <span className="text-slate-300">
                  {t.cart.freeShippingAlert.replace(
                    '{amount}', 
                    formatPrice(remainingForFreeShipping, remainingForFreeShipping)
                  )}
                </span>
              )}
            </div>
            <div className="w-full bg-black/40 rounded-full h-1.5 overflow-hidden">
              <div 
                className="bg-gradient-to-r from-[#1e3a2b] to-[#00e599] h-full transition-all duration-500 rounded-full"
                style={{ width: `${progressPercent}%` }}
              />
            </div>
          </div>

          {/* Cart Items List */}
          <div className="flex-1 overflow-y-auto p-5 divide-y divide-white/10">
            {cart.length === 0 ? (
              <div className="h-full flex flex-col items-center justify-center text-center p-6">
                <div className="w-16 h-16 rounded-full bg-[#142018] flex items-center justify-center text-slate-500 mb-4">
                  <ShoppingBag className="w-8 h-8" />
                </div>
                <h3 className="text-base font-bold text-white mb-1">
                  {t.cart.emptyTitle}
                </h3>
                <p className="text-xs text-slate-400 max-w-xs mb-6">
                  {t.cart.emptySub}
                </p>
                <button
                  onClick={() => setIsCartOpen(false)}
                  className="px-6 py-2.5 bg-[#00e599] text-black font-extrabold text-xs rounded-xl shadow-md"
                >
                  {t.cart.startShopping}
                </button>
              </div>
            ) : (
              cart.map((item, idx) => {
                const title = language === 'ar' ? item.product.titleAr : item.product.titleEn;
                const itemPrice = currency === 'EGP' ? item.product.priceEGP : item.product.priceUSD;

                return (
                  <div key={idx} className="py-4 first:pt-0 flex gap-4">
                    {/* Item Image */}
                    <div className="w-20 h-24 rounded-xl overflow-hidden bg-black shrink-0 border border-white/10 relative">
                      <img
                        src={item.selectedColor.image || item.product.images[0]}
                        alt={title}
                        className="w-full h-full object-cover"
                      />
                    </div>

                    {/* Info */}
                    <div className="flex-1 flex flex-col justify-between">
                      <div>
                        <div className="flex items-start justify-between gap-2">
                          <h4 className="text-xs font-bold text-white line-clamp-1">
                            {title}
                          </h4>
                          <button
                            onClick={() => removeFromCart(item.product.id, item.selectedColor.hex, item.selectedSize)}
                            className="text-slate-500 hover:text-rose-400 transition-colors p-0.5"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>

                        {/* Specs Pill */}
                        <div className="flex items-center gap-2 mt-1">
                          <span className="w-3 h-3 rounded-full border border-white/20" style={{ backgroundColor: item.selectedColor.hex }} />
                          <span className="text-[11px] text-slate-400">
                            {language === 'ar' ? item.selectedColor.nameAr : item.selectedColor.name}
                          </span>
                          <span className="text-slate-600">•</span>
                          <span className="text-[11px] font-bold text-slate-300 bg-white/5 px-1.5 py-0.2 rounded">
                            {item.selectedSize}
                          </span>
                        </div>
                      </div>

                      {/* Quantity & Item Subtotal */}
                      <div className="flex items-center justify-between mt-3">
                        <div className="flex items-center border border-white/15 rounded-lg bg-[#141c18]">
                          <button
                            onClick={() => updateQuantity(item.product.id, item.selectedColor.hex, item.selectedSize, -1)}
                            className="px-2 py-1 text-slate-400 hover:text-white text-xs"
                          >
                            <Minus className="w-3 h-3" />
                          </button>
                          <span className="px-2 text-xs font-bold text-white">{item.quantity}</span>
                          <button
                            onClick={() => updateQuantity(item.product.id, item.selectedColor.hex, item.selectedSize, 1)}
                            className="px-2 py-1 text-slate-400 hover:text-white text-xs"
                          >
                            <Plus className="w-3 h-3" />
                          </button>
                        </div>

                        <span className="text-xs font-black text-white font-['Space_Grotesk']">
                          {formatPrice(itemPrice * item.quantity, itemPrice * item.quantity)}
                        </span>
                      </div>
                    </div>
                  </div>
                );
              })
            )}
          </div>

          {/* Footer & Order Summary */}
          {cart.length > 0 && (
            <div className="p-5 border-t border-white/10 bg-[#111914] space-y-4">
              
              {/* Promo Code Form */}
              <form onSubmit={handleApplyPromo} className="flex gap-2">
                <div className="relative flex-1">
                  <Tag className="w-3.5 h-3.5 text-slate-400 absolute top-1/2 -translate-y-1/2 start-3" />
                  <input
                    type="text"
                    value={inputCode}
                    onChange={(e) => setInputCode(e.target.value)}
                    placeholder={t.cart.promoCodePlaceholder}
                    className="w-full bg-[#18241e] border border-white/15 rounded-xl text-xs text-white placeholder-slate-500 py-2.5 ps-9 pe-3 outline-none focus:border-[#00e599]"
                  />
                </div>
                <button
                  type="submit"
                  className="px-4 py-2 bg-[#1e3a2b] hover:bg-[#284f3a] text-[#00e599] font-bold text-xs rounded-xl border border-[#00e599]/30 transition-colors"
                >
                  {t.cart.apply}
                </button>
              </form>

              {appliedPromo && (
                <div className="text-xs text-[#00e599] font-semibold flex items-center gap-1.5 bg-[#00e599]/10 px-3 py-1.5 rounded-lg border border-[#00e599]/20">
                  <Check className="w-3.5 h-3.5" />
                  <span>Promo <strong>{appliedPromo}</strong> applied (-{cartDiscount > 0 ? formatPrice(cartDiscount, cartDiscount) : '10%'})</span>
                </div>
              )}

              {codeError && (
                <div className="text-xs text-rose-400 font-semibold">
                  Invalid coupon. Try: <strong>AURA10</strong> or <strong>FITNESS20</strong>
                </div>
              )}

              {/* Price Breakdown */}
              <div className="space-y-1.5 text-xs text-slate-300 pt-2 border-t border-white/10">
                <div className="flex justify-between">
                  <span>{t.cart.subtotal}</span>
                  <span className="font-semibold text-white">{formatPrice(cartSubtotal, cartSubtotal)}</span>
                </div>
                <div className="flex justify-between">
                  <span>{t.cart.shipping}</span>
                  <span className="font-semibold text-[#00e599]">
                    {isFreeShipping ? t.cart.free : formatPrice(10, 150)}
                  </span>
                </div>
                {cartDiscount > 0 && (
                  <div className="flex justify-between text-[#00e599]">
                    <span>{t.cart.discount}</span>
                    <span>-{formatPrice(cartDiscount, cartDiscount)}</span>
                  </div>
                )}
                <div className="flex justify-between text-sm font-black text-white pt-2 border-t border-white/10">
                  <span>{t.cart.total}</span>
                  <span className="text-[#00e599] font-['Space_Grotesk'] text-base">
                    {formatPrice(cartTotal, cartTotal)}
                  </span>
                </div>
              </div>

              {/* Checkout Button */}
              <button
                onClick={handleProceedCheckout}
                className="w-full py-4 rounded-xl bg-[#00e599] hover:bg-[#00c985] text-black font-black text-sm flex items-center justify-center gap-2 shadow-lg shadow-[#00e599]/25 hover:scale-[1.02] active:scale-95 transition-all"
              >
                <span>{t.cart.checkoutBtn}</span>
                <ArrowIcon className="w-4 h-4" />
              </button>

            </div>
          )}

        </div>
      </div>
    </div>
  );
};
