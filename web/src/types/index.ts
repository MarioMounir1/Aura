export type Language = 'en' | 'ar';
export type Currency = 'USD' | 'EGP' | 'EUR';

export type Category = 'all' | 'men' | 'women' | 'compression' | 'hoodies' | 'accessories';

export interface ProductColor {
  name: string;
  nameAr: string;
  hex: string;
  image: string;
}

export interface Product {
  id: string;
  titleEn: string;
  titleAr: string;
  subtitleEn: string;
  subtitleAr: string;
  category: 'men' | 'women' | 'compression' | 'hoodies' | 'accessories';
  priceUSD: number;
  priceEGP: number;
  originalPriceUSD?: number;
  originalPriceEGP?: number;
  rating: number;
  reviewsCount: number;
  badge?: 'NEW' | 'BEST SELLER' | 'LIMITED' | 'AURAFLEX™';
  badgeAr?: string;
  images: string[];
  colors: ProductColor[];
  sizes: ('XS' | 'S' | 'M' | 'L' | 'XL' | 'XXL')[];
  descriptionEn: string;
  descriptionAr: string;
  fabricEn: string;
  fabricAr: string;
  featuresEn: string[];
  featuresAr: string[];
  technologyBadge: string;
}

export interface CartItem {
  product: Product;
  selectedColor: ProductColor;
  selectedSize: string;
  quantity: number;
}

