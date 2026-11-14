import React, { createContext, useContext, useState, useEffect } from 'react';
import type { Product, CartItem, Language, Currency, ProductColor } from '../types';
import { translations } from '../data/translations';
import confetti from 'canvas-confetti';

interface StoreContextType {
  language: Language;
  setLanguage: (lang: Language) => void;
  currency: Currency;
  setCurrency: (curr: Currency) => void;
  t: typeof translations.en;
  cart: CartItem[];
  addToCart: (product: Product, color: ProductColor, size: string, quantity?: number) => void;
  removeFromCart: (productId: string, colorHex: string, size: string) => void;
  updateQuantity: (productId: string, colorHex: string, size: string, delta: number) => void;
  clearCart: () => void;
  cartCount: number;
  cartSubtotal: number;
  cartDiscount: number;
  cartTotal: number;
  promoCode: string;
  appliedPromo: string | null;
  applyPromoCode: (code: string) => boolean;
  freeShippingThreshold: number;
  isCartOpen: boolean;
  setIsCartOpen: (open: boolean) => void;
  isCheckoutOpen: boolean;
  setIsCheckoutOpen: (open: boolean) => void;
  isSizeAdvisorOpen: boolean;
  setIsSizeAdvisorOpen: (open: boolean) => void;
  activeQuickView: Product | null;
  setActiveQuickView: (product: Product | null) => void;
  wishlist: string[];
  toggleWishlist: (productId: string) => void;
  isInWishlist: (productId: string) => boolean;
  formatPrice: (usd: number, egp: number) => string;
  triggerConfetti: () => void;
}

const StoreContext = createContext<StoreContextType | undefined>(undefined);

export const StoreProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [language, setLanguageState] = useState<Language>('en');
  const [currency, setCurrency] = useState<Currency>('USD');
  const [cart, setCart] = useState<CartItem[]>([]);
  const [wishlist, setWishlist] = useState<string[]>([]);
  const [promoCode] = useState('');
  const [appliedPromo, setAppliedPromo] = useState<string | null>(null);
  const [discountPercent, setDiscountPercent] = useState<number>(0);

  const [isCartOpen, setIsCartOpen] = useState(false);
  const [isCheckoutOpen, setIsCheckoutOpen] = useState(false);
  const [isSizeAdvisorOpen, setIsSizeAdvisorOpen] = useState(false);
  const [activeQuickView, setActiveQuickView] = useState<Product | null>(null);

  const setLanguage = (lang: Language) => {
    setLanguageState(lang);
    document.documentElement.lang = lang;
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
    if (lang === 'ar' && currency === 'USD') {
      setCurrency('EGP');
    } else if (lang === 'en' && currency === 'EGP') {
      setCurrency('USD');
    }
  };

  useEffect(() => {
    document.documentElement.lang = language;
    document.documentElement.dir = language === 'ar' ? 'rtl' : 'ltr';
  }, [language]);

  const t = translations[language];

  const addToCart = (product: Product, color: ProductColor, size: string, quantity = 1) => {
    setCart((prev) => {
      const existingIndex = prev.findIndex(
        (item) => item.product.id === product.id && item.selectedColor.hex === color.hex && item.selectedSize === size
      );
      if (existingIndex > -1) {
        const next = [...prev];
        next[existingIndex].quantity += quantity;
        return next;
      }
      return [...prev, { product, selectedColor: color, selectedSize: size, quantity }];
    });
    setIsCartOpen(true);
  };

  const removeFromCart = (productId: string, colorHex: string, size: string) => {
    setCart((prev) =>
      prev.filter(
        (item) => !(item.product.id === productId && item.selectedColor.hex === colorHex && item.selectedSize === size)
      )
    );
  };

  const updateQuantity = (productId: string, colorHex: string, size: string, delta: number) => {
    setCart((prev) =>
      prev
        .map((item) => {
          if (item.product.id === productId && item.selectedColor.hex === colorHex && item.selectedSize === size) {
            const newQty = item.quantity + delta;
            return newQty > 0 ? { ...item, quantity: newQty } : null;
          }
          return item;
        })
        .filter(Boolean) as CartItem[]
    );
  };

  const clearCart = () => {
    setCart([]);
    setAppliedPromo(null);
    setDiscountPercent(0);
  };

  const cartCount = cart.reduce((acc, item) => acc + item.quantity, 0);

  const cartSubtotal = cart.reduce((acc, item) => {
    const itemPrice = currency === 'EGP' ? item.product.priceEGP : item.product.priceUSD;
    return acc + itemPrice * item.quantity;
  }, 0);

  const cartDiscount = Math.round(cartSubtotal * (discountPercent / 100));
  const cartTotal = Math.max(0, cartSubtotal - cartDiscount);

  const freeShippingThreshold = currency === 'EGP' ? 1500 : 75;

  const applyPromoCode = (code: string): boolean => {
    const clean = code.trim().toUpperCase();
    if (clean === 'AURA10') {
      setAppliedPromo('AURA10');
      setDiscountPercent(10);
      triggerConfetti();
      return true;
    }
    if (clean === 'FITNESS20' || clean === 'VIP20') {
      setAppliedPromo(clean);
      setDiscountPercent(20);
      triggerConfetti();
      return true;
    }
    return false;
  };

  const toggleWishlist = (productId: string) => {
    setWishlist((prev) =>
      prev.includes(productId) ? prev.filter((id) => id !== productId) : [...prev, productId]
    );
  };

  const isInWishlist = (productId: string) => wishlist.includes(productId);

  const formatPrice = (usd: number, egp: number) => {
    if (currency === 'EGP') {
      return `${egp.toLocaleString()} ج.م`;
    }
    if (currency === 'EUR') {
      return `€${Math.round(usd * 0.92)}`;
    }
    return `$${usd}`;
  };

  const triggerConfetti = () => {
    confetti({
      particleCount: 80,
      spread: 70,
      origin: { y: 0.6 },
      colors: ['#00e599', '#235a42', '#ffffff']
    });
  };

  return (
    <StoreContext.Provider
      value={{
        language,
        setLanguage,
        currency,
        setCurrency,
        t,
        cart,
        addToCart,
        removeFromCart,
        updateQuantity,
        clearCart,
        cartCount,
        cartSubtotal,
        cartDiscount,
        cartTotal,
        promoCode,
        appliedPromo,
        applyPromoCode,
        freeShippingThreshold,
        isCartOpen,
        setIsCartOpen,
        isCheckoutOpen,
        setIsCheckoutOpen,
        isSizeAdvisorOpen,
        setIsSizeAdvisorOpen,
        activeQuickView,
        setActiveQuickView,
        wishlist,
        toggleWishlist,
        isInWishlist,
        formatPrice,
        triggerConfetti,
      }}
    >
      {children}
    </StoreContext.Provider>
  );
};

export const useStore = () => {
  const context = useContext(StoreContext);
  if (!context) {
    throw new Error('useStore must be used within a StoreProvider');
  }
  return context;
};
