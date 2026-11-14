import type { Product } from '../types';

export const products: Product[] = [
  {
    id: 'aura-apex-compression-tee',
    titleEn: 'Apex Performance Compression Top',
    titleAr: 'تيشيرت ضغط عالي الأداء Apex',
    subtitleEn: 'Seamless 4-way stretch with zoned spinal cooling',
    subtitleAr: 'مرونة رباعية الاتجاهات مع تهوية مخصصة للعمود الفقري',
    category: 'compression',
    priceUSD: 48,
    priceEGP: 1250,
    originalPriceUSD: 58,
    originalPriceEGP: 1450,
    rating: 4.9,
    reviewsCount: 142,
    badge: 'BEST SELLER',
    badgeAr: 'الأكثر مبيعاً',
    images: [
      'https://images.unsplash.com/photo-1581655353564-df123a1eb820?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1578768079052-aa76e520028b?auto=format&fit=crop&w=900&q=80'
    ],
    colors: [
      { name: 'Aura Emerald', nameAr: 'زمردي أورا', hex: '#1e3a2b', image: 'https://images.unsplash.com/photo-1581655353564-df123a1eb820?auto=format&fit=crop&w=900&q=80' },
      { name: 'Stealth Carbon', nameAr: 'كربون فحمي', hex: '#141416', image: 'https://images.unsplash.com/photo-1578768079052-aa76e520028b?auto=format&fit=crop&w=900&q=80' },
      { name: 'Titanium Ice', nameAr: 'جليدي تيتانيوم', hex: '#94a3b8', image: 'https://images.unsplash.com/photo-1618354691373-d851c5c3a990?auto=format&fit=crop&w=900&q=80' }
    ],
    sizes: ['S', 'M', 'L', 'XL', 'XXL'],
    descriptionEn: 'Engineered for relentless upper body training. The Apex Compression Top provides medical-grade localized muscular compression to diminish fatigue while laser-cut micro-pores along the spine expel heat before it accumulates.',
    descriptionAr: 'مصمم خصيصاً لتدريبات الجزء العلوي الشاقة. يمنحك تيشيرت Apex دعماً عضلياً فائقاً يقلل من الإجهاد العضلي، بينما تعمل فتحات التهوية الدقيقة المقصوصة بالليزر على طرد الحرارة والعرق فورياً.',
    fabricEn: '82% Recycled AuraPoly, 18% Elastane with SilverGuard™ anti-odor finish',
    fabricAr: '82% بوليستر أورا معاد تدويره، 18% إيلاستين مرن مع معالجة SilverGuard™ المضادة للروائح',
    featuresEn: [
      'Targeted thoracic & deltoid compression support',
      'Laser-welded seams for completely chafing-free lifts',
      'Integrated hem NFC chip for 1-tap Aura workout sync',
      'UPF 50+ UV solar protection for outdoor sprints'
    ],
    featuresAr: [
      'دعم ضغط مستهدف للصدر وعضلات الكتف والظهر',
      'درزات ملحومة بالليزر لمنع أي احتكاك أثناء التمرين',
      'شريحة NFC مدمجة لبدء جدول التمرين بلمسة واحدة في تطبيق أورا',
      'حماية كاملة من أشعة الشمس UPF 50+ للركض الخارجي'
    ],
    technologyBadge: 'AuraStretch 360™'
  },
  {
    id: 'aura-sculpt-high-waist-leggings',
    titleEn: 'Sculpt & Define High-Waisted Leggings',
    titleAr: 'ليجنز نحت عالي الخصر Sculpt & Define',
    subtitleEn: '100% squat-proof seamless contouring fabric',
    subtitleAr: 'قماش انسيابي مقاوم للسكوات 100% بدون أي شفافية',
    category: 'women',
    priceUSD: 54,
    priceEGP: 1400,
    originalPriceUSD: 65,
    originalPriceEGP: 1680,
    rating: 5.0,
    reviewsCount: 218,
    badge: 'BEST SELLER',
    badgeAr: 'الأكثر مبيعاً',
    images: [
      'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=900&q=80'
    ],
    colors: [
      { name: 'Forest Green', nameAr: 'أخضر غابات أورا', hex: '#235a42', image: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=900&q=80' },
      { name: 'Midnight Onyx', nameAr: 'أسود أونيكس', hex: '#0f1412', image: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=900&q=80' },
      { name: 'Sage Mist', nameAr: 'ميرمية هادئة', hex: '#a3b899', image: 'https://images.unsplash.com/photo-1552196563-5527e3abbd73?auto=format&fit=crop&w=900&q=80' }
    ],
    sizes: ['XS', 'S', 'M', 'L', 'XL'],
    descriptionEn: 'The ultimate compression legging designed with dual-tier waistband tension that holds firmly during high-intensity intervals and heavy squats without rolling down. Butter-smooth texture with zero friction.',
    descriptionAr: 'الليجنز الرياضي المثالي بخصر مزدوج محكم يثبت في مكانه تماماً أثناء تمارين الهيت والسكوات دون أي انزلاق. ملمس ناعم كالحرير يوفر لكِ أقصى درجات الثقة والدعم طوال اليوم.',
    fabricEn: '78% AuraMicroNylon, 22% Spandex (Squat-proof 320 GSM density)',
    fabricAr: '78% أورا مايكرو نايلون، 22% سباندكس (كثافة عالية 320 GSM غير شفافة نهائياً)',
    featuresEn: [
      'Guaranteed 100% squat-proof under heavy gym lighting',
      'Ribbed high waistband prevents slip and roll-down',
      'Hidden phone pocket along back inner waistband',
      'Gusseted inner crotch panel for maximum flexibility'
    ],
    featuresAr: [
      'مضمون 100% ضد الشفافية أثناء السكوات تحت إضاءة الجيم القوية',
      'حزام خصر مضلع يمنع الانزلاق والالتواء تماماً',
      'جيب سري مخفي في الحزام الخلفي للهاتف الذكي',
      'تصميم داخلي معزز يمنحك أقصى درجات التمدد والانسيابية'
    ],
    technologyBadge: 'SculptSeam™ Fit'
  },
  {
    id: 'aura-phantom-2in1-training-shorts',
    titleEn: 'Phantom 2-in-1 Performance Shorts 7"',
    titleAr: 'شورت تدريب 2 في 1 Phantom مقاس 7 إنش',
    subtitleEn: 'Built-in compression liner with phone stash pocket',
    subtitleAr: 'شورت داخلي ضاغط مدمج مع جيب محكم للهاتف',
    category: 'men',
    priceUSD: 44,
    priceEGP: 1150,
    rating: 4.8,
    reviewsCount: 96,
    badge: 'NEW',
    badgeAr: 'وصل حديثاً',
    images: [
      'https://images.unsplash.com/photo-1594381898411-846e7d193883?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=900&q=80'
    ],
    colors: [
      { name: 'Matte Charcoal', nameAr: 'فحمي غير لامع', hex: '#1c2420', image: 'https://images.unsplash.com/photo-1594381898411-846e7d193883?auto=format&fit=crop&w=900&q=80' },
      { name: 'Olive Green', nameAr: 'زيتي عسكري', hex: '#2b3e32', image: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=900&q=80' }
    ],
    sizes: ['S', 'M', 'L', 'XL', 'XXL'],
    descriptionEn: 'Combining ultra-lightweight outer shell with an elastic compression inner liner that locks your quad muscles in place and stops groin chafing during running, boxing, and heavy leg presses.',
    descriptionAr: 'يجمع بين طبقة خارجية فائقة الخفة وبطانة داخلية ضاغطة تثبت عضلات الفخذ وتمنع الاحتكاك تماماً أثناء الجري والملاكمة وتمارين الأرجل القاسية.',
    fabricEn: 'Shell: 90% Ultra-light Poly, 10% Elastane. Liner: 85% Breathable Nylon, 15% Spandex',
    fabricAr: 'الخارجي: 90% بوليستر خفيف، 10% إيلاستين. الداخلي: 85% نايلون مسامي، 15% سباندكس',
    featuresEn: [
      'No-bounce internal compression phone pocket',
      'Towel/shirt retention loop on back waistband',
      'Laser-perforated side hem slits for sprint mobility',
      'Water-repellent DWR outer coating against sweat stains'
    ],
    featuresAr: [
      'جيب داخلي ضاغط يثبت الهاتف بدون أي ارتداد أثناء الركض',
      'حلقة مخصصة في الحزام لتعليق المنشفة أو التيشيرت',
      'فتحات جانبية مقصوصة بالليزر لحرية تامة في الركض والقفز',
      'طلاء DWR خارجي عازل للبقع ومقاوم للرطوبة'
    ],
    technologyBadge: 'DryBreeze™ Aeration'
  },
  {
    id: 'aura-heavyweight-oversized-pump-cover',
    titleEn: 'Relentless Heavyweight Oversized Hoodie',
    titleAr: 'هودي وبمب كفر ثقيل أوفرسايز Relentless',
    subtitleEn: '460 GSM organic combed cotton with structured drop-shoulder',
    subtitleAr: 'قطن عضوي فاخر 460 GSM بقصة أكتاف عريضة مريحة',
    category: 'hoodies',
    priceUSD: 68,
    priceEGP: 1750,
    originalPriceUSD: 80,
    originalPriceEGP: 2050,
    rating: 4.9,
    reviewsCount: 164,
    badge: 'AURAFLEX™',
    badgeAr: 'أورا فليكس',
    images: [
      'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1509967419530-da38b4704bc6?auto=format&fit=crop&w=900&q=80'
    ],
    colors: [
      { name: 'Aura Deep Moss', nameAr: 'طحلبي داكن', hex: '#162b20', image: 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?auto=format&fit=crop&w=900&q=80' },
      { name: 'Pitch Black', nameAr: 'أسود قاتم', hex: '#111211', image: 'https://images.unsplash.com/photo-1509967419530-da38b4704bc6?auto=format&fit=crop&w=900&q=80' },
      { name: 'Bone White', nameAr: 'أبيض عاجي', hex: '#eae6df', image: 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?auto=format&fit=crop&w=900&q=80' }
    ],
    sizes: ['S', 'M', 'L', 'XL', 'XXL'],
    descriptionEn: 'The quintessential pump cover. Crafted from dense 460 GSM organic French Terry cotton that keeps joints warm through cold warm-ups before being dropped to unleash your physique. Features a double-layered structured hood.',
    descriptionAr: 'البمب كفر الأساسي لكل لاعب كمال أجسام. مصنوع من قطن فرينش تيري عضوي فائق الكثافة 460 GSM يحافظ على حرارة المفاصل في الإحماء، مع قبعة مزدوجة الطبقات وتصميم أكتاف منسدل.',
    fabricEn: '100% Combed Organic Cotton (460 GSM Heavyweight Terry)',
    fabricAr: '100% قطن عضوي ممشط فاخر (كثافة ثقيلة 460 GSM)',
    featuresEn: [
      'Double-ply crossover hood with zero drawstrings for clean aesthetic',
      'Hidden kangaroo pouch interior zipper for keys and AirPods',
      'Pre-shrunk fabric ensures no shrinkage after high heat wash',
      'Signature Aura Athletics silicon tonal badge on chest'
    ],
    featuresAr: [
      'قبعة مزدوجة بدون حبال لإطلالة عصرية أنيقة',
      'سحاب داخلي مخفي في جيب الكنغر للمفاتيح وسماعات الأذن',
      'معالج ضد الانكماش ليحافظ على مقاسه تماماً بعد الغسيل',
      'شعار أورا أثلتيكس السيليكوني البارز على الصدر'
    ],
    technologyBadge: 'ThermalLock Cotton™'
  },
  {
    id: 'aura-infinity-seamless-sports-bra',
    titleEn: 'Infinity Seamless Medium-Impact Sports Bra',
    titleAr: 'برا رياضي انسيابي بدون خياطة Infinity',
    subtitleEn: 'Contoured ribbing with removable memory-foam pads',
    subtitleAr: 'دعم متوسط مع بطانة ميموري فوم قابلة للإزالة',
    category: 'women',
    priceUSD: 36,
    priceEGP: 950,
    rating: 4.7,
    reviewsCount: 88,
    badge: 'NEW',
    badgeAr: 'وصل حديثاً',
    images: [
      'https://images.unsplash.com/photo-1518310383802-640c2de311b2?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&w=900&q=80'
    ],
    colors: [
      { name: 'Emerald', nameAr: 'زمردي', hex: '#235a42', image: 'https://images.unsplash.com/photo-1518310383802-640c2de311b2?auto=format&fit=crop&w=900&q=80' },
      { name: 'Smoky Slate', nameAr: 'رمادي دخاني', hex: '#4b5563', image: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&w=900&q=80' }
    ],
    sizes: ['XS', 'S', 'M', 'L'],
    descriptionEn: 'Engineered for fluid movement. Provides dependable medium support for weight training, spinning, and Pilates with crisscross back straps designed to free up shoulder blade rotation.',
    descriptionAr: 'مصمم لحرية الحركة المطلقة. يوفر دعماً متوسطاً مثالياً لتمارين الحديد، السيكل، والبيسكلات مع ظهر مفتوح بشرائط متقاطعة تمنح لوح الكتف حرية دوران كاملة.',
    fabricEn: '75% AuraSeam Poly, 25% Lycra',
    fabricAr: '75% بوليستر أورا سيملس، 25% لايكرا مرنة',
    featuresEn: [
      'Removable contoured memory-foam cups',
      'Wider under-bust band prevents digging and roll-up',
      'Sweat-wicking micro-channels for quick drying'
    ],
    featuresAr: [
      'وسادات ميموري فوم مريحة قابلة للإزالة',
      'حزام دعم عريض تحت الصدر يمنع الضغط أو الالتواء',
      'قنوات نسيجية دقيقة لسحب العرق والتجفيف السريع'
    ],
    technologyBadge: 'SculptSeam™ Fit'
  },
  {
    id: 'aura-titan-pro-lifting-straps',
    titleEn: 'Titan-Grip Silicone Infused Lifting Straps',
    titleAr: 'أحزمة رفع أثقال Titan-Grip معززة بالسيليكون',
    subtitleEn: 'Industrial heavy cotton webbing with Neoprene wrist cushions',
    subtitleAr: 'حياكة قطنية فائقة التحمل مع وسادة نيوبرين للمعصم',
    category: 'accessories',
    priceUSD: 22,
    priceEGP: 580,
    rating: 4.9,
    reviewsCount: 310,
    badge: 'BEST SELLER',
    badgeAr: 'الأكثر مبيعاً',
    images: [
      'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=900&q=80',
      'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?auto=format&fit=crop&w=900&q=80'
    ],
    colors: [
      { name: 'Aura Green & Black', nameAr: 'أخضر أورا وأسود', hex: '#1e3a2b', image: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&w=900&q=80' }
    ],
    sizes: ['M'],
    descriptionEn: 'Eliminate grip failure during heavy deadlifts and barbell rows. Infused with dual rubberized silicone tracks that bite into the knurling of any barbell and hold up to 450 kg (1000 lbs).',
    descriptionAr: 'تخلص من ضعف قبضة اليد أثناء الديدليفت وسحب البار الثقيل. معززة بخطوط سيليكون مطاطية تمسك بتسنن البار بإحكام وتتحمل حتى 450 كجم، مع وسادة نيوبرين سميكة لحماية المعصم.',
    fabricEn: '100% Reinforced Military-Grade Cotton Webbing with Neoprene Foam',
    fabricAr: '100% قطن عسكري مقوى مع رغوة النيوبرين لراحة المعصم',
    featuresEn: [
      'Holds up to 1,000 lbs (450 kg) tensile test rating',
      '5mm thick neoprene pad eliminates wrist bruising',
      'Dual silicone grip pattern locks onto any knurling'
    ],
    featuresAr: [
      'قوة تحمل مختبرة تصل إلى 450 كجم',
      'وسادة نيوبرين بسماكة 5 مم تمنع كدمات وضغط المعصم',
      'خطوط سيليكون مزدوجة تمسك بالبار بإحكام لا يتزحزح'
    ],
    technologyBadge: 'TitanGrip™'
  },
  {
    id: 'aura-thermo-matte-steel-shaker',
    titleEn: 'Aura ThermoMatte™ Insulated Steel Shaker 800ml',
    titleAr: 'شيكر حراري أورا ستيل عازل 800 مل',
    subtitleEn: 'Double-wall vacuum insulation keeps liquids cold for 24h',
    subtitleAr: 'عازل تفريغي مزدوج الجدار يحافظ على البرودة 24 ساعة',
    category: 'accessories',
    priceUSD: 28,
    priceEGP: 750,
    rating: 4.8,
    reviewsCount: 125,
    badge: 'LIMITED',
    badgeAr: 'إصدار محدود',
    images: [
      'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=900&q=80'
    ],
    colors: [
      { name: 'Matte Emerald', nameAr: 'زمردي مطفي', hex: '#162b20', image: 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=900&q=80' },
      { name: 'Stealth Black', nameAr: 'أسود مطفي', hex: '#111211', image: 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=900&q=80' }
    ],
    sizes: ['M'],
    descriptionEn: 'The last gym shaker you will ever need. Kitchen-grade 18/8 stainless steel that never absorbs whey protein odors. Integrated silent whisk mesh guarantees lump-free shakes without rattling noise.',
    descriptionAr: 'الشيكر الأخير الذي ستحتاجه في رحلتك الرياضية. ستانلس ستيل غذائي 18/8 لا يمتص روائح الواي بروتين نهائياً. شبكة خفق صامتة مدمجة تضمن خفقاً ناعماً بدون صوت طقطقة.',
    fabricEn: 'Double-wall vacuum insulated 18/8 Stainless Steel (BPA Free)',
    fabricAr: 'ستانلس ستيل 18/8 مزدوج معزول بالتفريغ (خالٍ من مادة BPA)',
    featuresEn: [
      'Keeps pre-workout ice cold for 24+ hours',
      'Zero odor retention even with overnight protein shakes',
      '100% leak-proof twist cap with silicone gasket'
    ],
    featuresAr: [
      'يحافظ على المكملات والماء بارداً كالثلج لأكثر من 24 ساعة',
      'لا يحتفظ برائحة البروتين نهائياً بفضل الستانلس ستيل الصحي',
      'غطاء لولبي محكم الإغلاق ومقاوم للتسريب بنسبة 100%'
    ],
    technologyBadge: 'ThermoMatte™'
  },
  {
    id: 'aura-tempo-dryvent-stringer',
    titleEn: 'Tempo Ultra-Breathable Training Stringer',
    titleAr: 'سترينجر تدريب خفيف فائق التهوية Tempo',
    subtitleEn: 'Deep-cut armholes and curved hem for maximum pump freedom',
    subtitleAr: 'فتحات جانبية واسعة وحافة منحنية تبرز عضلات الجسم',
    category: 'men',
    priceUSD: 32,
    priceEGP: 850,
    rating: 4.8,
    reviewsCount: 74,
    badge: 'NEW',
    badgeAr: 'وصل حديثاً',
    images: [
      'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?auto=format&fit=crop&w=900&q=80'
    ],
    colors: [
      { name: 'Aura Green', nameAr: 'أخضر أورا', hex: '#235a42', image: 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?auto=format&fit=crop&w=900&q=80' },
      { name: 'Charcoal', nameAr: 'فحمي', hex: '#1c2420', image: 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?auto=format&fit=crop&w=900&q=80' }
    ],
    sizes: ['S', 'M', 'L', 'XL'],
    descriptionEn: 'Engineered for dedicated lifters. Cut generously around the lats and chest to prevent any restriction during overhead presses and lat pulldowns.',
    descriptionAr: 'مصمم خصيصاً للاعبي كمال الأجسام. قَصة مريحة حول عضلات الظهر والصدر تمنحك حرية مطلقة أثناء تمارين السحب والضغط دون أي إعاقة.',
    fabricEn: '92% AirMesh Poly, 8% Spandex',
    fabricAr: '92% بوليستر إيرمش فائق التهوية، 8% سباندكس',
    featuresEn: [
      'Featherweight 130 GSM construction',
      'Deep lat taper accentuates upper body V-taper',
      'Reflective neon Aura Athletics logo on upper spine'
    ],
    featuresAr: [
      'وزن خفيف كالريشة 130 GSM',
      'قَصة مصممة لإبراز شكل الـ V للظهر والأكتاف',
      'شعار أورا العاكس للإضاءة في الجزء العلوي للظهر'
    ],
    technologyBadge: 'DryBreeze™ Aeration'
  }
];
