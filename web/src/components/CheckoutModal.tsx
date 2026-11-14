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
        className="relative w-full max-w-2xl bg-[#121824] border border-[#222b3f] rounded-[24px] p-6 sm:p-8 shadow-2xl my-auto text-start"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close Button */}
        <button
          onClick={handleClose}
          className="absolute top-5 end-5 p-2 rounded-xl bg-[#1b2232] hover:bg-[#222b3f] text-[#8e929c] hover:text-white border border-[#222b3f] transition-all cursor-pointer"
        >
          <X className="w-5 h-5" />
        </button>

        {orderComplete ? (
          /* Order Confirmation Success State */
          <div className="text-center py-8">
            <div className="w-20 h-20 bg-[#10b981]/15 rounded-full flex items-center justify-center text-[#10b981] mx-auto mb-6 shadow-xl shadow-[#10b981]/25 border border-[#10b981]/30">
              <CheckCircle className="w-10 h-10" />
            </div>
            <h3 className="text-2xl sm:text-3xl font-black text-white font-['Plus_Jakarta_Sans'] mb-2">
              {t.checkout.orderSuccessTitle}
            </h3>
            <p className="text-sm text-[#8e929c] max-w-md mx-auto leading-relaxed mb-6">
              {t.checkout.orderSuccessSub.replace('{orderId}', orderId)}
            </p>

            <div className="p-4 bg-[#1b2232] border border-[#222b3f] rounded-[18px] max-w-sm mx-auto mb-8 text-xs text-[#8e929c] space-y-1.5 text-start">
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
                <strong className="text-[#10b981]">Aura App Auto-Pair Ready</strong>
              </div>
            </div>

            <button
              onClick={handleClose}
              className="px-8 py-3.5 aura-btn-primary text-white font-bold text-sm rounded-xl shadow-lg transition-transform hover:scale-105 cursor-pointer"
            >
              {t.checkout.returnToStore}
            </button>
          </div>
        ) : (
          /* Checkout Form */
          <div>
            <div className="flex items-center gap-2 mb-1">
              <ShieldCheck className="w-5 h-5 text-[#10b981]" />
              <h2 className="text-xl font-bold text-white font-['Plus_Jakarta_Sans']">
                {t.checkout.title}
              </h2>
            </div>
            <p className="text-xs text-[#8e929c] mb-6">
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
                    <label className="block text-[11px] text-[#8e929c] mb-1">{t.checkout.fullName}</label>
                    <input
                      type="text"
                      required
                      value={fullName}
                      onChange={(e) => setFullName(e.target.value)}
                      className="w-full bg-[#1b2232] border border-[#222b3f] rounded-xl px-3 py-2 text-xs text-white outline-none focus:border-[#10b981]"
                    />
                  </div>
                  <div>
                    <label className="block text-[11px] text-[#8e929c] mb-1">{t.checkout.email}</label>
                    <input
                      type="email"
                      required
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className="w-full bg-[#1b2232] border border-[#222b3f] rounded-xl px-3 py-2 text-xs text-white outline-none focus:border-[#10b981]"
                    />
                  </div>
                </div>
                <div className="mt-3">
                  <label className="block text-[11px] text-[#8e929c] mb-1">{t.checkout.phone}</label>
                  <input
                    type="tel"
                    required
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    className="w-full bg-[#1b2232] border border-[#222b3f] rounded-xl px-3 py-2 text-xs text-white outline-none focus:border-[#10b981]"
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
                    <label className="block text-[11px] text-[#8e929c] mb-1">{t.checkout.street}</label>
                    <input
                      type="text"
                      required
                      value={street}
                      onChange={(e) => setStreet(e.target.value)}
                      className="w-full bg-[#1b2232] border border-[#222b3f] rounded-xl px-3 py-2 text-xs text-white outline-none focus:border-[#10b981]"
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block text-[11px] text-[#8e929c] mb-1">{t.checkout.city}</label>
                      <input
                        type="text"
                        required
                        value={city}
                        onChange={(e) => setCity(e.target.value)}
                        className="w-full bg-[#1b2232] border border-[#222b3f] rounded-xl px-3 py-2 text-xs text-white outline-none focus:border-[#10b981]"
                      />
                    </div>
                    <div>
                      <label className="block text-[11px] text-[#8e929c] mb-1">{t.checkout.country}</label>
                      <select
                        value={country}
                        onChange={(e) => setCountry(e.target.value)}
                        className="w-full bg-[#1b2232] border border-[#222b3f] rounded-xl px-3 py-2 text-xs text-white outline-none focus:border-[#10b981] cursor-pointer"
                      >
                        <option value="Egypt" className="bg-[#121824]">{t.checkout.egypt}</option>
                        <option value="United Arab Emirates" className="bg-[#121824]">{t.checkout.uae}</option>
                        <option value="Saudi Arabia" className="bg-[#121824]">{t.checkout.saudi}</option>
                        <option value="United States" className="bg-[#121824]">{t.checkout.usa}</option>
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
                    className={`p-3 rounded-xl border flex flex-col items-center gap-1.5 transition-all text-center cursor-pointer ${
                      paymentMethod === 'card'
                        ? 'border-[#10b981] bg-[#10b981]/15 text-white font-bold'
                        : 'border-[#222b3f] bg-[#1b2232] text-[#8e929c] hover:text-white'
                    }`}
                  >
                    <CreditCard className="w-5 h-5 text-[#10b981]" />
                    <span className="text-xs">{t.checkout.creditCard}</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setPaymentMethod('apple')}
                    className={`p-3 rounded-xl border flex flex-col items-center gap-1.5 transition-all text-center cursor-pointer ${
                      paymentMethod === 'apple'
                        ? 'border-[#10b981] bg-[#10b981]/15 text-white font-bold'
                        : 'border-[#222b3f] bg-[#1b2232] text-[#8e929c] hover:text-white'
                    }`}
                  >
                    <Smartphone className="w-5 h-5 text-[#10b981]" />
                    <span className="text-xs">{t.checkout.applePay}</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setPaymentMethod('cod')}
                    className={`p-3 rounded-xl border flex flex-col items-center gap-1.5 transition-all text-center cursor-pointer ${
                      paymentMethod === 'cod'
                        ? 'border-[#10b981] bg-[#10b981]/15 text-white font-bold'
                        : 'border-[#222b3f] bg-[#1b2232] text-[#8e929c] hover:text-white'
                    }`}
                  >
                    <Banknote className="w-5 h-5 text-[#10b981]" />
                    <span className="text-xs">{t.checkout.cashOnDelivery}</span>
                  </button>
                </div>
              </div>

              {/* Submit CTA */}
              <div className="pt-4 border-t border-[#222b3f]">
                <button
                  type="submit"
                  className="w-full py-4 rounded-xl aura-btn-primary font-bold text-sm flex items-center justify-center gap-2 shadow-lg shadow-[#10b981]/25 hover:scale-[1.01] active:scale-95 transition-all cursor-pointer"
                >
                  <ShoppingBag className="w-4 h-4 text-white" />
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
