from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from backend.models import (
    Category, Subcategory, Product,
    HomeBanner, HomeFlashSale, HomeHotRank, HomeRecommend, HomeNewArrival, HomePromotion,
    SpecGroup, SpecValue, SKU,
    Address, CartItem, Order, OrderProduct, UserCoupon,
    UserProfile, AdminProfile, Review, ProductDetail,
)
from decimal import Decimal
from datetime import datetime


class Command(BaseCommand):
    help = 'Initialize all seed data for the ecommerce database'

    def add_arguments(self, parser):
        parser.add_argument('--reset', action='store_true', help='Reset database before seeding')

    def handle(self, *args, **options):
        if options['reset']:
            self.stdout.write('Resetting database...')
            self._reset_data()

        self.stdout.write('Starting seed data...')

        self._create_users()
        self._create_categories()
        self._create_subcategories()
        self._create_products()
        self._create_product_details()
        self._create_specs_and_skus()
        self._create_reviews()
        self._create_home_content()
        self._create_addresses()
        self._create_cart_items()
        self._create_orders()
        self._create_coupons()

        self.stdout.write(self.style.SUCCESS('\n=== Seed data complete! ==='))
        self.stdout.write(f'Categories: {Category.objects.count()}')
        self.stdout.write(f'Subcategories: {Subcategory.objects.count()}')
        self.stdout.write(f'Products: {Product.objects.count()}')
        self.stdout.write(f'SpecGroups: {SpecGroup.objects.count()}')
        self.stdout.write(f'SKUs: {SKU.objects.count()}')
        self.stdout.write(f'Reviews: {Review.objects.count()}')
        self.stdout.write(f'Addresses: {Address.objects.count()}')
        self.stdout.write(f'CartItems: {CartItem.objects.count()}')
        self.stdout.write(f'Orders: {Order.objects.count()}')

    def _reset_data(self):
        OrderProduct.objects.all().delete()
        Order.objects.all().delete()
        CartItem.objects.all().delete()
        Address.objects.all().delete()
        UserCoupon.objects.all().delete()
        SKU.objects.all().delete()
        SpecValue.objects.all().delete()
        SpecGroup.objects.all().delete()
        ProductDetail.objects.all().delete()
        Review.objects.all().delete()
        HomeFlashSale.products.through.objects.all().delete()
        HomeHotRank.products.through.objects.all().delete()
        HomeRecommend.products.through.objects.all().delete()
        HomeNewArrival.products.through.objects.all().delete()
        HomePromotion.objects.all().delete()
        HomeNewArrival.objects.all().delete()
        HomeRecommend.objects.all().delete()
        HomeHotRank.objects.all().delete()
        HomeFlashSale.objects.all().delete()
        HomeBanner.objects.all().delete()
        Product.objects.all().delete()
        Subcategory.objects.all().delete()
        Category.objects.all().delete()
        UserProfile.objects.all().delete()
        AdminProfile.objects.all().delete()
        User.objects.filter(username__in=['testuser', 'admin']).delete()

    def _get_media(self, original_name):
        from mediafiles.models import MediaFile
        return MediaFile.objects.filter(original_name=original_name).first()

    def _create_users(self):
        self.stdout.write('\nCreating users...')
        testuser, _ = User.objects.get_or_create(username='testuser')
        UserProfile.objects.get_or_create(user=testuser, defaults={'user_type': 'user', 'phone': '13800138000'})
        self.stdout.write(f'  testuser: {testuser.username}')

        admin, created = User.objects.get_or_create(username='admin')
        if created:
            admin.set_password('admin123')
            admin.email = 'admin@example.com'
            admin.save()
        UserProfile.objects.get_or_create(user=admin, defaults={'user_type': 'admin', 'phone': '13900139000'})
        AdminProfile.objects.get_or_create(user=admin, defaults={'permissions': {'can_manage_orders': True, 'can_manage_products': True}})
        self.stdout.write(f'  admin: {admin.username} (password: admin123)')

    def _create_categories(self):
        self.stdout.write('\nCreating categories...')
        category_image_map = {
            '女装': ('icon-fashion-01.webp', 'banner-1-summer-1710.webp'),
            '男装': ('icon-mens-02.webp', 'banner-2-newarrival-1710.webp'),
            '美妆护肤': ('icon-skincare-03.webp', 'banner-3-discount-1710.webp'),
            '数码电子': ('icon-phone-04.webp', 'banner-1-summer-1710.webp'),
            '家居生活': ('icon-home-05.webp', 'banner-2-newarrival-1710.webp'),
            '运动户外': ('icon-sport-06.webp', 'banner-3-discount-1710.webp'),
            '食品生鲜': ('icon-food-07.webp', 'banner-1-summer-1710.webp'),
            '潮流配饰': ('icon-beauty-08.webp', 'banner-2-newarrival-1710.webp'),
        }
        self.categories = {}
        for name in category_image_map.keys():
            cat, created = Category.objects.get_or_create(name=name)
            icon_name, banner_name = category_image_map[name]
            icon_media = self._get_media(icon_name)
            banner_media = self._get_media(banner_name)
            if icon_media:
                cat.icon = icon_media
            if banner_media:
                cat.banner = banner_media
            cat.save()
            self.categories[name] = cat
            self.stdout.write(f'  {"Created" if created else "Exists"}: {name}')

    def _create_subcategories(self):
        self.stdout.write('\nCreating subcategories...')
        subcategories_data = {
            '女装': ['连衣裙', 'T恤', '衬衫', '牛仔裤', '半身裙'],
            '男装': ['T恤', '衬衫', '裤装', '外套', '卫衣'],
            '美妆护肤': ['护肤', '彩妆', '香水', '个护', '面膜'],
            '数码电子': ['手机', '耳机', '音箱', '配件', '智能穿戴'],
            '家居生活': ['家纺', '收纳', '厨具', '家装', '清洁'],
            '运动户外': ['运动鞋', '健身', '户外', '箱包', '运动服饰'],
            '食品生鲜': ['零食', '茶叶', '水果', '粮油', '生鲜'],
            '潮流配饰': ['腕表', '眼镜', '包包', '首饰', '帽子'],
        }
        self.subcategories = {}
        for cat_name, subcat_list in subcategories_data.items():
            for subcat_name in subcat_list:
                subcat, created = Subcategory.objects.get_or_create(
                    name=subcat_name,
                    category=self.categories[cat_name]
                )
                key = f"{cat_name}:{subcat_name}"
                self.subcategories[key] = subcat
                self.stdout.write(f'  {"Created" if created else "Exists"}: {cat_name} > {subcat_name}')

    def _create_products(self):
        self.stdout.write('\nCreating products...')
        product_image_map = {
            '法式碎花连衣裙': 'product-11-tote.webp',
            '纯棉宽松T恤': 'product-03-mug.webp',
            '高腰直筒牛仔裤': 'product-05-sneakers.webp',
            '商务Polo衫': 'product-03-mug.webp',
            '休闲牛仔短裤': 'product-05-sneakers.webp',
            '玻尿酸保湿面膜': 'product-04-serum.webp',
            '氨基酸洁面乳': 'product-02-earbuds.webp',
            'iPhone保护壳': 'product-12-bottle.webp',
            '无线充电器': 'product-12-bottle.webp',
            '日式收纳盒': 'product-11-tote.webp',
            '骨瓷餐具套装': 'product-03-mug.webp',
            '跑步鞋': 'product-05-sneakers.webp',
            '瑜伽垫': 'product-04-serum.webp',
            '水果礼盒': 'product-12-bottle.webp',
            '每日坚果礼盒': 'product-12-bottle.webp',
            '简约真皮腕表': 'product-01-watch.webp',
            '复古飞行员太阳镜': 'product-07-sunglasses.webp',
            '无线蓝牙耳机': 'product-02-earbuds.webp',
            '极简陶瓷咖啡杯': 'product-03-mug.webp',
        }
        products_data = [
            ('法式碎花连衣裙', '优雅碎花图案，轻薄透气面料，适合夏季穿着', 189, 299, '女装:连衣裙', 4.6, 320, 8600, '热卖'),
            ('纯棉宽松T恤', '100%纯棉，宽松版型，百搭款式', 79, 129, '女装:T恤', 4.5, 580, 12000, '爆款'),
            ('高腰直筒牛仔裤', '高腰设计，显瘦直筒版型，经典靛蓝色', 159, 259, '女装:牛仔裤', 4.7, 890, 15000, '推荐'),
            ('商务Polo衫', '珠地棉面料，透气舒适，经典商务款式', 129, 199, '男装:POLO衫', 4.6, 520, 11000, '热卖'),
            ('休闲牛仔短裤', '柔软丹宁面料，直筒版型，夏季必备', 99, 169, '男装:裤装', 4.5, 680, 13500, '爆款'),
            ('玻尿酸保湿面膜', '深层补水，焕亮肌肤，医美级玻尿酸', 99, 169, '美妆护肤:面膜', 4.9, 1200, 28000, '热卖'),
            ('氨基酸洁面乳', '温和清洁，不刺激，适合敏感肌', 89, 139, '美妆护肤:洁面', 4.8, 890, 22000, '爆款'),
            ('iPhone保护壳', '液态硅胶材质，精准孔位，防摔保护', 59, 99, '数码电子:配件', 4.8, 1500, 35000, '热卖'),
            ('无线充电器', '快充技术，智能识别，多设备兼容', 79, 129, '数码电子:配件', 4.7, 980, 25000, '爆款'),
            ('日式收纳盒', '优质PP材质，分类收纳，美观实用', 69, 109, '家居生活:收纳', 4.7, 880, 22000, '热卖'),
            ('骨瓷餐具套装', '精美骨瓷，釉下彩工艺，环保健康', 199, 329, '家居生活:厨具', 4.8, 420, 9800, '爆款'),
            ('跑步鞋', '轻量透气，缓震科技，防滑耐磨', 299, 499, '运动户外:运动鞋', 4.8, 720, 18000, '热卖'),
            ('瑜伽垫', 'TPE材质，抗菌防滑，舒适当道', 89, 149, '运动户外:健身', 4.7, 980, 24000, '爆款'),
            ('水果礼盒', '当季精选，产地直发，新鲜配送', 99, 169, '食品生鲜:水果', 4.6, 850, 21000, '热卖'),
            ('每日坚果礼盒', '科学配比，独立包装，健康零食', 79, 129, '食品生鲜:零食', 4.8, 1300, 32000, '爆款'),
            ('简约真皮腕表', '头层牛皮表带，自动机芯，30米防水，百搭款式', 299, 899, '潮流配饰:腕表', 4.8, 1200, 23000, '热卖'),
            ('复古飞行员太阳镜', 'UV400防护，金属框，复古时尚', 159, 299, '潮流配饰:眼镜', 4.6, 980, 18000, '爆款'),
            ('无线蓝牙耳机', '主动降噪，单次续航8小时，轻盈舒适', 199, 499, '数码电子:耳机', 4.7, 890, 18000, '热卖'),
            ('极简陶瓷咖啡杯', '高温烧制，大理石纹理，容量350ml', 68, 128, '家居生活:厨具', 4.6, 560, 12000, '爆款'),
        ]
        self.products = {}
        for name, desc, price, original, subcat_key, rating, reviews, sales, tag in products_data:
            subcat = self.subcategories.get(subcat_key)
            prod, created = Product.objects.get_or_create(
                name=name,
                defaults={
                    'description': desc,
                    'price': Decimal(str(price)),
                    'original_price': Decimal(str(original)),
                    'tag': tag,
                    'sales_count': sales,
                    'rating': Decimal(str(rating)),
                    'review_count': reviews,
                    'is_in_stock': True,
                    'subcategory': subcat,
                }
            )
            if not created and prod.subcategory is None:
                prod.subcategory = subcat
                prod.save()

            img_name = product_image_map.get(name)
            if img_name:
                img_media = self._get_media(img_name)
                if img_media:
                    prod.image = img_media
                    prod.save()

            self.products[name] = prod
            self.stdout.write(f'  {"Created" if created else "Exists"}: {name}')

    def _create_product_details(self):
        self.stdout.write('\nCreating product details...')
        for prod in self.products.values():
            detail, created = ProductDetail.objects.get_or_create(product=prod)
            detail.shop_name = '潮流优品官方旗舰店'
            if prod.image:
                detail.shop_logo = prod.image
                detail.images.add(prod.image)
                detail.detail_images.add(prod.image)
            detail.save()
            self.stdout.write(f'  {"Created" if created else "Exists"}: {prod.name}')

    def _create_specs_and_skus(self):
        self.stdout.write('\nCreating specs and SKUs...')
        SKU.objects.all().delete()
        SpecValue.objects.all().delete()
        SpecGroup.objects.filter(product__isnull=False).delete()

        from itertools import product as iter_product
        spec_data = {
            '法式碎花连衣裙': [('尺码', ['S', 'M', 'L', 'XL']), ('颜色', ['碎花', '纯色'])],
            '纯棉宽松T恤': [('尺码', ['S', 'M', 'L', 'XL']), ('颜色', ['白色', '黑色', '灰色'])],
            '高腰直筒牛仔裤': [('尺码', ['26', '27', '28', '29', '30']), ('颜色', ['深蓝', '浅蓝', '黑色'])],
            '氨基酸洁面乳': [('规格', ['100ml', '150ml'])],
            '简约真皮腕表': [('颜色', ['黑色', '棕色', '银色']), ('表带', ['皮质', '钢带'])],
        }

        for prod_name, spec_groups in spec_data.items():
            prod = self.products.get(prod_name)
            if not prod:
                continue

            group_values = {}
            for group_name, values in spec_groups:
                sg, _ = SpecGroup.objects.get_or_create(product=prod, name=group_name)
                group_values[group_name] = []
                for val in values:
                    sv, _ = SpecValue.objects.get_or_create(group=sg, value=val)
                    group_values[group_name].append((sv, val))

            group_names = list(group_values.keys())
            for combo in iter_product(*[group_values[gn] for gn in group_names]):
                sku = SKU.objects.create(
                    product=prod,
                    price=prod.price,
                    original_price=prod.original_price,
                    stock=100,
                )
                for sv, _ in combo:
                    sku.spec_values.add(sv)

            self.stdout.write(f'  {prod_name}: {len(list(iter_product(*[group_values[gn] for gn in group_names])))} SKUs')

    def _create_reviews(self):
        self.stdout.write('\nCreating reviews...')
        from django.db.models import Count, Avg
        review_data = [
            ('简约真皮腕表', '张**', 5, '款式非常好看，佩戴舒适，很满意！'),
            ('无线蓝牙耳机', '王**', 5, '降噪效果超赞，音质清晰，续航给力！'),
            ('极简陶瓷咖啡杯', '孙**', 4, '做工精细，容量刚好，适合喝茶。'),
            ('跑步鞋', '郑**', 5, '穿起来很舒服，透气性好，样式好看。'),
            ('法式碎花连衣裙', '林**', 5, '碎花图案很漂亮，面料很舒服！'),
        ]
        user = User.objects.get(username='testuser')
        for prod_name, user_name, rating, content in review_data:
            prod = self.products.get(prod_name)
            if not prod:
                continue
            rev, created = Review.objects.get_or_create(
                product=prod,
                user_name=user_name,
                defaults={'rating': rating, 'content': content, 'user': user}
            )
            if created:
                self.stdout.write(f'  Created review: {prod_name} by {user_name}')

        for prod in Product.objects.all():
            stats = Review.objects.filter(product=prod).aggregate(
                count=Count('id'),
                avg_rating=Avg('rating')
            )
            prod.review_count = stats['count'] or 0
            if stats['avg_rating']:
                prod.rating = Decimal(str(round(stats['avg_rating'], 1)))
            prod.save()

    def _create_home_content(self):
        self.stdout.write('\nCreating home banners...')
        banners_data = [
            ('banner-1-summer-1710.webp', '夏装新品', '清凉一夏', '立即选购', 0),
            ('banner-new-1710.webp', '美妆节', '焕新美妆', '查看详情', 1),
            ('banner-flash-1710.webp', '限时特惠', '折扣专区', '马上抢', 2),
        ]
        for img, tag, title, action, gradient in banners_data:
            banner_media = self._get_media(img)
            ban, created = HomeBanner.objects.get_or_create(
                tag=tag,
                defaults={'title': title, 'action_title': action, 'gradient_type': gradient, 'sort_order': gradient, 'is_enabled': True}
            )
            if banner_media:
                ban.image = banner_media
                ban.save()
            self.stdout.write(f'  {"Created" if created else "Exists"}: {tag}')

        self.stdout.write('\nCreating home sections...')
        flashsale, _ = HomeFlashSale.objects.get_or_create(
            title='限时秒杀',
            defaults={'subtitle': '爆款限时抢', 'sort_order': 1, 'is_enabled': True}
        )
        hotrank, _ = HomeHotRank.objects.get_or_create(
            title='热销榜单',
            defaults={'sort_order': 2, 'is_enabled': True}
        )
        recommend, _ = HomeRecommend.objects.get_or_create(
            title='为你推荐',
            defaults={'sort_order': 3, 'is_enabled': True}
        )
        newarrival, _ = HomeNewArrival.objects.get_or_create(
            title='新品上市',
            defaults={'sort_order': 4, 'is_enabled': True}
        )
        promo, _ = HomePromotion.objects.get_or_create(
            title='优惠活动',
            defaults={'subtitle': '满减优惠', 'sort_order': 5, 'is_enabled': True}
        )

        for prod in Product.objects.all()[:6]:
            recommend.products.add(prod)
        for prod in Product.objects.order_by('-id')[:6]:
            newarrival.products.add(prod)
        for prod in Product.objects.filter(tag='热卖')[:6]:
            flashsale.products.add(prod)
        for prod in Product.objects.filter(tag='爆款')[:4]:
            hotrank.products.add(prod)

        self.stdout.write(f'  FlashSale: {flashsale.products.count()} products')
        self.stdout.write(f'  HotRank: {hotrank.products.count()} products')
        self.stdout.write(f'  Recommend: {recommend.products.count()} products')
        self.stdout.write(f'  NewArrival: {newarrival.products.count()} products')

    def _create_addresses(self):
        self.stdout.write('\nCreating addresses...')
        user = User.objects.get(username='testuser')
        addresses_data = [
            {'name': '张三', 'phone': '13800138000', 'province': '北京市', 'city': '北京市', 'district': '朝阳区', 'detail': '建国路88号SOHO现代城A座1201室', 'is_default': True},
            {'name': '李四', 'phone': '13900139000', 'province': '上海市', 'city': '上海市', 'district': '浦东新区', 'detail': '世纪大道100号环球金融中心18楼', 'is_default': False},
        ]
        self.addresses = []
        for addr_data in addresses_data:
            addr, created = Address.objects.get_or_create(
                user=user,
                name=addr_data['name'],
                defaults=addr_data
            )
            self.addresses.append(addr)
            self.stdout.write(f'  {"Created" if created else "Exists"}: {addr.name} - {addr.province}{addr.city}')

    def _create_cart_items(self):
        self.stdout.write('\nCreating cart items...')
        user = User.objects.get(username='testuser')
        CartItem.objects.filter(user=user).delete()
        for i, prod in enumerate(Product.objects.all()[:3]):
            cart_item = CartItem.objects.create(
                user=user,
                product=prod,
                quantity=(i % 3) + 1,
                is_selected=i < 2
            )
            self.stdout.write(f'  {prod.name} x{cart_item.quantity}')

    def _create_orders(self):
        self.stdout.write('\nCreating orders...')
        user = User.objects.get(username='testuser')
        OrderProduct.objects.filter(order__user=user).delete()
        Order.objects.filter(user=user).delete()

        addr1 = self.addresses[0]

        def make_order_num(seed):
            return f"ORH5{datetime.now().strftime('%Y%m%d%H%M%S')}{seed:03d}"

        order1_id = make_order_num(1)
        order1 = Order.objects.create(
            id=order1_id,
            user=user,
            store='潮流优品官方旗舰店',
            status='pending',
            total_amount=Decimal('268.00'),
            payment=Decimal('268.00'),
            freight=Decimal('0.00'),
            discount=Decimal('0.00'),
            address_name=addr1.name,
            address_phone=addr1.phone,
            address_province=addr1.province,
            address_city=addr1.city,
            address_district=addr1.district,
            address_detail=addr1.detail,
        )
        OrderProduct.objects.create(order=order1, name='法式碎花连衣裙', spec='白色, M', price=Decimal('189.00'), quantity=1, image=self.products['法式碎花连衣裙'].image)
        OrderProduct.objects.create(order=order1, name='纯棉宽松T恤', spec='黑色, L', price=Decimal('79.00'), quantity=1, image=self.products['纯棉宽松T恤'].image)

        order2_id = make_order_num(2)
        order2 = Order.objects.create(
            id=order2_id,
            user=user,
            store='潮流优品官方旗舰店',
            status='paid',
            total_amount=Decimal('159.00'),
            payment=Decimal('159.00'),
            freight=Decimal('0.00'),
            discount=Decimal('0.00'),
            address_name=addr1.name,
            address_phone=addr1.phone,
            address_province=addr1.province,
            address_city=addr1.city,
            address_district=addr1.district,
            address_detail=addr1.detail,
        )
        OrderProduct.objects.create(order=order2, name='高腰直筒牛仔裤', spec='浅蓝, 27', price=Decimal('159.00'), quantity=1, image=self.products['高腰直筒牛仔裤'].image)

        order3_id = make_order_num(3)
        order3 = Order.objects.create(
            id=order3_id,
            user=user,
            store='潮流优品官方旗舰店',
            status='shipped',
            total_amount=Decimal('298.00'),
            payment=Decimal('298.00'),
            freight=Decimal('10.00'),
            discount=Decimal('0.00'),
            address_name=self.addresses[1].name,
            address_phone=self.addresses[1].phone,
            address_province=self.addresses[1].province,
            address_city=self.addresses[1].city,
            address_district=self.addresses[1].district,
            address_detail=self.addresses[1].detail,
        )
        OrderProduct.objects.create(order=order3, name='简约真皮腕表', spec='', price=Decimal('299.00'), quantity=1, image=self.products['简约真皮腕表'].image)

        order4_id = make_order_num(4)
        order4 = Order.objects.create(
            id=order4_id,
            user=user,
            store='潮流优品官方旗舰店',
            status='completed',
            total_amount=Decimal('198.00'),
            payment=Decimal('198.00'),
            freight=Decimal('0.00'),
            discount=Decimal('0.00'),
            address_name=addr1.name,
            address_phone=addr1.phone,
            address_province=addr1.province,
            address_city=addr1.city,
            address_district=addr1.district,
            address_detail=addr1.detail,
            pay_time=datetime.now(),
        )
        OrderProduct.objects.create(order=order4, name='无线蓝牙耳机', spec='', price=Decimal('199.00'), quantity=1, image=self.products['无线蓝牙耳机'].image)
        OrderProduct.objects.create(order=order4, name='极简陶瓷咖啡杯', spec='', price=Decimal('68.00'), quantity=2, image=self.products['极简陶瓷咖啡杯'].image)

        self.stdout.write(f'  Created {Order.objects.filter(user=user).count()} orders')

    def _create_coupons(self):
        self.stdout.write('\nCreating coupons...')
        user = User.objects.get(username='testuser')
        coupons_data = [
            {'name': '新人专享券', 'value': 20, 'threshold': '满100元减20元', 'description': '满100元减20元'},
            {'name': '满50减10', 'value': 10, 'threshold': '满50元减10元', 'description': '满50元减10元'},
            {'name': '无门槛券', 'value': 5, 'threshold': '无门槛', 'description': '无门槛使用'},
        ]
        for cp_data in coupons_data:
            coupon, created = UserCoupon.objects.get_or_create(
                user=user,
                name=cp_data['name'],
                defaults={
                    'value': cp_data['value'],
                    'threshold': cp_data['threshold'],
                    'description': cp_data['description'],
                    'time': '2026-12-31'
                }
            )
            self.stdout.write(f'  {"Created" if created else "Exists"}: {cp_data["name"]}')