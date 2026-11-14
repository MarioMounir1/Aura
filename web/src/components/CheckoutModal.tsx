import React, { useState } from 'react';
import { useStore } from '../context/StoreContext';
import { 
  X, 
  ShieldCheck, 
  CreditCard, 
  Smartphone, 
  Banknote, 
  CheckCircle,
  ShoppingBag
} from 'lucide-react';

export const CheckoutModal: React.FC = () => {
  const {
    isCheckoutOpen,
    setIsCheckoutOpen,
    cartTotal,
    clearCart,
    formatPrice,
    triggerConfetti,
    t
  } = useStore();

  const [fullName, setFullName] = useState('Omar El-Sayed');
  const [email, setEmail] = useState('athlete@aura.fit');
  const [phone, setPhone] = useState('+20 100 234 5678');
  const [street, setStreet] = useState('90th Street North, Fifth Settlement');
  const [city, setCity] = useState('Cairo');
  const [country, setCountry] = useState('Egypt');
  const [paymentMethod, setPaymentMethod] = useState<'card' | 'apple' | 'cod'>('card');
  const [orderComplete, setOrderComplete] = useState(false);
  const [orderId, setOrderId] = useState('');

  if (!isCheckoutOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const generatedId = 'AUR-' + Math.floor(100000 + Math.random() * 900000);
    setOrderId(generatedId);
    setOrderComplete(true);
    triggerConfetti();
    clearCart();
  };

  const handleClose = () => {
    setIsCheckoutOpen(false);
    setOrderComplete(false);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/85 backdrop-blur-md overflow-y-auto animate-in fade-in">
      <div 
        className="relative w-full max-w-2xl bg-[#0e1411] border border-white/15 rounded-3xl p-6 sm:p-8 shadow-2xl my-auto text-start"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close Button */}
        <button
          onClick={handleClose}
          className="absolute top-5 end-5 p-2 rounded-full bg-black/40 hover:bg-black/80 text-slate-300 hover:text-white border border-white/10"
        >
          <X className="w-5 h-5" />
        </button>

        {orderComplete ? (
          /* Order Confirmation Success State */
          <div className="text-center py-8">
            <div className="w-20 h-20 bg-[#00e599]/20 rounded-full flex items-center justify-center text-[#00e599] mx-auto mb-6 shadow-xl shadow-[#00e599]/30">
              <CheckCircle className="w-10 h-10" />
            </div>
            <h3 className="text-2xl sm:text-3xl font-black text-white font-['Space_Grotesk'] mb-2">
              {t.checkout.orderSuccessTitle}
            </h3>
            <p className="text-sm text-slate-300 max-w-md mx-auto leading-relaxed mb-6">
              {t.checkout.orderSuccessSub.replace('{orderId}', orderId)}
            </p>

            <div className="p-4 bg-[#14231b] border border-[#00e599]/30 rounded-2xl max-w-sm mx-auto mb-8 text-xs text-slate-300 space-y-1 text-start">
              <div className="flex justify-between">
                <span>Confirmation Email:</span>
                <strong className="text-white">{email}</strong>
              </div>
              <div className="flex justify-between">
                <span>Shipping To:</span>
                <strong className="text-white">{city}, {country}</strong>
              </div>
              <div className="flex justify-between">
                <span>NFC Apparel Tag:</span>
                <strong className="text-[#00e599]">Aura App Auto-Pair Ready</strong>
              </div>
            </div>

            <button
              onClick={handleClose}
              className="px-8 py-3.5 bg-[#00e599] hover:bg-[#00c985] text-black font-extrabold text-sm rounded-xl shadow-lg transition-transform hover:scale-105"
            >
              {t.checkout.returnToStore}
            </button>
          </div>
        ) : (
          /* Checkout Form */
          <div>
            <div className="flex items-center gap-2 mb-1">
              <ShieldCheck className="w-5 h-5 text-[#00e599]" />
              <h2 className="text-xl font-black text-white font-['Space_Grotesk']">
                {t.checkout.title}
              </h2>
            </div>
            <p className="text-xs text-slate-400 mb-6">
              {t.checkout.subtitle}
            </p>

            <form onSubmit={handleSubmit} className="space-y-6">
              
              {/* Contact Information */}
              <div>
                <h3 className="text-xs font-bold text-slate-300 uppercase tracking-wider mb-3">
                  {t.checkout.contactInfo}
                </h3>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block text-[11px] text-slate-400 mb-1">{t.checkout.fullName}</label>
                    <input
                      type="text"
                      required
                      value={fullName}
                      onChange={(e) => setFullName(e.target.value)}
                      className="w-full bg-[#141c18] border border-white/10 rounded-xl px-3 py-2 text-xs text-white outline-none focus:border-[#00e599]"
                    />
                  </div>
                  <div>
                    <label className="block text-[11px] text-slate-400 mb-1">{t.checkout.email}</label>
                    <input
                      type="email"
                      required
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className="w-full bg-[#141c18] border border-white/10 rounded-xl px-3 py-2 text-xs text-white outline-none focus:border-[#00e599]"
                    />
                  </div>
                </div>
                <div className="mt-3">
                  <label className="block text-[11px] text-slate-400 mb-1">{t.checkout.phone}</label>
                  <input
                    type="tel"
                    required
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    className="w-full bg-[#141c18] border border-white/10 rounded-xl px-3 py-2 text-xs text-white outline-none focus:border-[#00e599]"
                  />
                </div>
              </div>

              {/* Shipping Address */}
              <div>
                <h3 className="text-xs font-bold text-slate-300 uppercase tracking-wider mb-3">
                  {t.checkout.shippingAddress}
                </h3>
                <div className="space-y-3">
                  <div>
                    <label className="block text-[11px] text-slate-400 mb-1">{t.checkout.street}</label>
                    <input
                      type="text"
                      required
                      value={street}
                      onChange={(e) => setStreet(e.target.value)}
                      className="w-full bg-[#141c18] border border-white/10 rounded-xl px-3 py-2 text-xs text-white outline-none focus:border-[#00e599]"
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block text-[11px] text-slate-400 mb-1">{t.checkout.city}</label>
                      <input
                        type="text"
                        required
                        value={city}
                        onChange={(e) => setCity(e.target.value)}
                        className="w-full bg-[#141c18] border border-white/10 rounded-xl px-3 py-2 text-xs text-white outline-none focus:border-[#00e599]"
                      />
                    </div>
                    <div>
                      <label className="block text-[11px] text-slate-400 mb-1">{t.checkout.country}</label>
                      <select
                        value={country}
                        onChange={(e) => setCountry(e.target.value)}
                        className="w-full bg-[#141c18] border border-white/10 rounded-xl px-3 py-2 text-xs text-white outline-none focus:border-[#00e599]"
                      >
                        <option value="Egypt">{t.checkout.egypt}</option>
                        <option value="United Arab Emirates">{t.checkout.uae}</option>
                        <option value="Saudi Arabia">{t.checkout.saudi}</option>
                        <option value="United States">{t.checkout.usa}</option>
                      </select>
                    </div>
                  </div>
                </div>
              </div>

              {/* Payment Methods */}
              <div>
                <h3 className="text-xs font-bold text-slate-300 uppercase tracking-wider mb-3">
                  {t.checkout.paymentMethod}
                </h3>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5">
                  <button
                    type="button"
                    onClick={() => setPaymentMethod('card')}
                    className={`p-3 rounded-xl border flex flex-col items-center gap-1.5 transition-all text-center ${
                      paymentMethod === 'card'
                        ? 'border-[#00e599] bg-[#00e599]/10 text-white font-bold'
                        : 'border-white/10 bg-[#141c18] text-slate-400 hover:text-white'
                    }`}
                  >
                    <CreditCard className="w-5 h-5 text-[#00e599]" />
                    <span className="text-xs">{t.checkout.creditCard}</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setPaymentMethod('apple')}
                    className={`p-3 rounded-xl border flex flex-col items-center gap-1.5 transition-all text-center ${
                      paymentMethod === 'apple'
                        ? 'border-[#00e599] bg-[#00e599]/10 text-white font-bold'
                        : 'border-white/10 bg-[#141c18] text-slate-400 hover:text-white'
                    }`}
                  >
                    <Smartphone className="w-5 h-5 text-[#00e599]" />
                    <span className="text-xs">{t.checkout.applePay}</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setPaymentMethod('cod')}
                    className={`p-3 rounded-xl border flex flex-col items-center gap-1.5 transition-all text-center ${
                      paymentMethod === 'cod'
                        ? 'border-[#00e599] bg-[#00e599]/10 text-white font-bold'
                        : 'border-white/10 bg-[#141c18] text-slate-400 hover:text-white'
                    }`}
                  >
                    <Banknote className="w-5 h-5 text-[#00e599]" />
                    <span className="text-xs">{t.checkout.cashOnDelivery}</span>
                  </button>
                </div>
              </div>

              {/* Submit CTA */}
              <div className="pt-4 border-t border-white/10">
                <button
                  type="submit"
                  className="w-full py-4 rounded-xl bg-[#00e599] hover:bg-[#00c985] text-black font-black text-sm flex items-center justify-center gap-2 shadow-lg shadow-[#00e599]/25 hover:scale-[1.01] active:scale-95 transition-all"
                >
                  <ShoppingBag className="w-4 h-4" />
                  <span>{t.checkout.placeOrder} ({formatPrice(cartTotal, cartTotal)})</span>
                </button>
              </div>

            </form>
          </div>
        )}

      </div>
    </div>
  );
};
