from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from django.utils import timezone
from backend.models import (
    Category, Subcategory, Product,
    HomeBanner, HomeFlashSale, HomeHotRank, HomeRecommend, HomeNewArrival, HomePromotion,
    SpecGroup, SpecValue, SKU,
    Address, CartItem, Order, OrderProduct, UserCoupon,
    UserProfile, AdminProfile, Review, ProductDetail,
    Favorite, Notification, ShopInfo, VIPMembership,
)
from decimal import Decimal
from datetime import datetime, timedelta


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
        self._create_favorites()
        self._create_notifications()
        self._create_shop_and_vip()

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
        self.stdout.write(f'Favorites: {Favorite.objects.count()}')
        self.stdout.write(f'Coupons: {UserCoupon.objects.count()}')
        self.stdout.write(f'Notifications: {Notification.objects.count()}')

    def _reset_data(self):
        OrderProduct.objects.all().delete()
        Order.objects.all().delete()
        CartItem.objects.all().delete()
        Address.objects.all().delete()
        Favorite.objects.all().delete()
        Notification.objects.all().delete()
        UserCoupon.objects.all().delete()
        VIPMembership.objects.all().delete()
        ShopInfo.objects.all().delete()
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
        testuser, created = User.objects.get_or_create(username='testuser')
        testuser.set_password('iole')
        testuser.email = 'test@example.com'
        testuser.save()
        profile, _ = UserProfile.objects.get_or_create(user=testuser, defaults={'user_type': 'user', 'phone': '13800138000'})
        profile.points = max(profile.points, 1280)
        profile.follow_count = max(profile.follow_count, 12)
        profile.fans_count = max(profile.fans_count, 86)
        profile.save()
        self.stdout.write(f'  testuser: {testuser.username} (password: iole)')

        admin, admin_created = User.objects.get_or_create(username='admin')
        if admin_created:
            admin.set_password('admin123')
            admin.email = 'admin@example.com'
            admin.save()
        else:
            # 确保已有 admin 用户的密码正确
            admin.set_password('admin123')
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
            '男装': ['T恤', '衬衫', '裤装', '外套', '卫衣', 'Polo衫'],
            '美妆护肤': ['护肤', '彩妆', '香水', '个护', '面膜', '洁面'],
            '数码电子': ['手机', '耳机', '音箱', '配件', '智能穿戴'],
            '家居生活': ['家纺', '收纳', '厨具', '家装', '清洁'],
            '运动户外': ['运动鞋', '健身', '户外', '箱包', '运动服饰'],
            '食品生鲜': ['零食', '茶叶', '水果', '粮油', '生鲜'],
            '潮流配饰': ['腕表', '眼镜', '包包', '首饰', '帽子'],
        }
        # Map category to subcategory icon filename
        category_subcat_icon_map = {
            '女装': 'icon-fashion-01.webp',
            '男装': 'icon-mens-02.webp',
            '美妆护肤': 'icon-skincare-03.webp',
            '数码电子': 'icon-phone-04.webp',
            '家居生活': 'icon-home-05.webp',
            '运动户外': 'icon-sport-06.webp',
            '食品生鲜': 'icon-food-07.webp',
            '潮流配饰': 'icon-beauty-08.webp',
        }
        self.subcategories = {}
        for cat_name, subcat_list in subcategories_data.items():
            for subcat_name in subcat_list:
                subcat, created = Subcategory.objects.get_or_create(
                    name=subcat_name,
                    category=self.categories[cat_name]
                )
                # Assign icon based on parent category
                icon_filename = category_subcat_icon_map.get(cat_name)
                if icon_filename:
                    icon_media = self._get_media(icon_filename)
                    if icon_media:
                        subcat.icon = icon_media
                        subcat.save()
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
            ('商务Polo衫', '珠地棉面料，透气舒适，经典商务款式', 129, 199, '男装:Polo衫', 4.6, 520, 11000, '热卖'),
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
            prod.description = desc
            prod.price = Decimal(str(price))
            prod.original_price = Decimal(str(original))
            prod.tag = tag
            prod.sales_count = sales
            prod.rating = Decimal(str(rating))
            prod.review_count = reviews
            prod.is_in_stock = True
            prod.subcategory = subcat

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
            '商务Polo衫': [('尺码', ['M', 'L', 'XL', 'XXL']), ('颜色', ['藏青', '白色', '灰色'])],
            '休闲牛仔短裤': [('尺码', ['M', 'L', 'XL']), ('颜色', ['浅蓝', '深蓝'])],
            '玻尿酸保湿面膜': [('组合', ['5片装', '10片装', '20片装'])],
            '氨基酸洁面乳': [('规格', ['100ml', '150ml'])],
            'iPhone保护壳': [('机型', ['iPhone 15', 'iPhone 16', 'iPhone 17']), ('颜色', ['雾黑', '奶白', '松石绿'])],
            '无线充电器': [('功率', ['15W', '30W']), ('颜色', ['白色', '黑色'])],
            '日式收纳盒': [('容量', ['小号', '中号', '大号']), ('颜色', ['透明', '米白'])],
            '骨瓷餐具套装': [('件数', ['4件套', '8件套', '12件套'])],
            '跑步鞋': [('尺码', ['39', '40', '41', '42', '43']), ('颜色', ['黑白', '云灰', '荧光绿'])],
            '瑜伽垫': [('厚度', ['6mm', '8mm']), ('颜色', ['莫兰迪粉', '湖蓝', '石墨灰'])],
            '水果礼盒': [('规格', ['6斤装', '10斤装'])],
            '每日坚果礼盒': [('规格', ['15袋', '30袋'])],
            '简约真皮腕表': [('颜色', ['黑色', '棕色', '银色']), ('表带', ['皮质', '钢带'])],
            '复古飞行员太阳镜': [('颜色', ['金框茶片', '银框灰片'])],
            '无线蓝牙耳机': [('颜色', ['云白', '曜黑']), ('版本', ['标准版', '降噪版'])],
            '极简陶瓷咖啡杯': [('容量', ['350ml', '500ml']), ('颜色', ['白色', '墨绿'])],
        }

        for prod_name, spec_groups in spec_data.items():
            prod = self.products.get(prod_name)
            if not prod:
                continue

            group_values = {}
            for group_index, (group_name, values) in enumerate(spec_groups):
                sg, _ = SpecGroup.objects.get_or_create(product=prod, name=group_name)
                sg.sort_order = group_index
                sg.save()
                group_values[group_name] = []
                for value_index, val in enumerate(values):
                    sv, _ = SpecValue.objects.get_or_create(group=sg, value=val)
                    sv.sort_order = value_index
                    sv.save()
                    group_values[group_name].append((sv, val))

            group_names = list(group_values.keys())
            for combo_index, combo in enumerate(iter_product(*[group_values[gn] for gn in group_names])):
                sku = SKU.objects.create(
                    product=prod,
                    price=prod.price,
                    original_price=prod.original_price,
                    stock=80 + combo_index * 7,
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
            ('纯棉宽松T恤', '周**', 5, '面料柔软，洗后不变形，日常很好搭。'),
            ('高腰直筒牛仔裤', '陈**', 4, '版型挺括，显腿直，尺码按推荐买正好。'),
            ('商务Polo衫', '赵**', 5, '通勤穿很合适，领口不塌。'),
            ('休闲牛仔短裤', '许**', 4, '夏天穿很清爽，颜色也耐看。'),
            ('玻尿酸保湿面膜', '刘**', 5, '补水效果明显，敷完不黏腻。'),
            ('氨基酸洁面乳', '何**', 5, '敏感肌用着也温和，泡沫细腻。'),
            ('iPhone保护壳', '吴**', 5, '手感细腻，孔位准确。'),
            ('无线充电器', '马**', 4, '充电稳定，放桌面也简洁。'),
            ('日式收纳盒', '郭**', 5, '厨房和衣柜都能用，叠放很稳。'),
            ('骨瓷餐具套装', '黄**', 5, '釉面很亮，包装也结实。'),
            ('瑜伽垫', '梁**', 4, '防滑不错，厚度适合居家训练。'),
            ('水果礼盒', '蒋**', 5, '果子新鲜，送人很体面。'),
            ('每日坚果礼盒', '冯**', 5, '独立包装方便，日期也新。'),
            ('复古飞行员太阳镜', '唐**', 4, '镜片清晰，脸型适配度高。'),
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
            if not created:
                rev.rating = rating
                rev.content = content
                rev.user = user
                rev.save()
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
            {
                'image': 'banner-1-summer-1710.webp',
                'tag': '夏装新品',
                'title': '清凉一夏',
                'action': '立即选购',
                'gradient': 0,
                'badge': 'SUMMER DROP',
                'subtitle': '轻薄、透气、明亮色系',
                'description': '精选适合夏季通勤、周末出游和户外运动的轻量单品，覆盖穿搭、防晒、运动与随身配饰。',
            },
            {
                'image': 'banner-2-newarrival-1710.webp',
                'tag': '美妆节',
                'title': '焕新美妆',
                'action': '查看详情',
                'gradient': 1,
                'badge': 'BEAUTY EDIT',
                'subtitle': '补水修护与日常洁面精选',
                'description': '围绕换季护肤和日常个护场景，组合高复购面膜、洁面与便携护理商品，适合直接加入购物车。',
            },
            {
                'image': 'banner-3-discount-1710.webp',
                'tag': '限时特惠',
                'title': '折扣专区',
                'action': '马上抢',
                'gradient': 2,
                'badge': 'LIMITED DEALS',
                'subtitle': '热卖款集中放价',
                'description': '按销量和优惠力度筛选出的折扣商品会场，覆盖服饰、数码、家居和食品，适合快速凑单。',
            },
        ]
        for data in banners_data:
            banner_media = self._get_media(data['image'])
            ban, created = HomeBanner.objects.get_or_create(
                tag=data['tag'],
                defaults={
                    'title': data['title'],
                    'action_title': data['action'],
                    'gradient_type': data['gradient'],
                    'sort_order': data['gradient'],
                    'is_enabled': True,
                }
            )
            ban.title = data['title']
            ban.action_title = data['action']
            ban.gradient_type = data['gradient']
            ban.sort_order = data['gradient']
            ban.landing_badge = data['badge']
            ban.landing_subtitle = data['subtitle']
            ban.landing_description = data['description']
            ban.link = f'campaign.html?banner_id={ban.id}'
            ban.is_enabled = True
            if banner_media:
                ban.image = banner_media
            ban.save()

            if data['tag'] == '夏装新品':
                products = list(Product.objects.filter(
                    subcategory__category__name__in=['女装', '男装', '运动户外', '潮流配饰']
                ).order_by('-sales_count')[:8])
            elif data['tag'] == '美妆节':
                products = list(Product.objects.filter(
                    subcategory__category__name='美妆护肤'
                ).order_by('-rating', '-sales_count')[:8])
            else:
                products = list(Product.objects.order_by('-sales_count')[:8])
            ban.products.set(products)
            self.stdout.write(f'  {"Created" if created else "Exists"}: {data["tag"]} ({len(products)} products)')

        self.stdout.write('\nCreating home sections...')
        flashsale, _ = HomeFlashSale.objects.get_or_create(
            title='限时秒杀',
            defaults={'subtitle': '爆款限时抢', 'sort_order': 1, 'is_enabled': True}
        )
        flashsale.subtitle = '爆款限时抢'
        flashsale.start_time = timezone.now() - timedelta(hours=2)
        flashsale.end_time = timezone.now() + timedelta(hours=8)
        flashsale.sort_order = 1
        flashsale.is_enabled = True
        flashsale.save()
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
        promo.subtitle = '满99减10，满199减30'
        promo.link = 'coupon.html'
        promo.image = self._get_media('banner-3-discount-1710.webp') or promo.image
        promo.sort_order = 5
        promo.is_enabled = True
        promo.save()

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
        for i, prod in enumerate(Product.objects.all()[:4]):
            sku = prod.skus.order_by('id').first()
            cart_item = CartItem.objects.create(
                user=user,
                product=prod,
                sku=sku,
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
        addr2 = self.addresses[1] if len(self.addresses) > 1 else addr1

        def make_order_num(seed):
            return f"ORH5{datetime.now().strftime('%Y%m%d%H%M%S')}{seed:03d}"

        def pick_sku(product_name, index=0):
            product = self.products[product_name]
            return product.skus.order_by('id')[index] if product.skus.exists() else None

        def spec_text(sku):
            if not sku:
                return ''
            values = sku.spec_values.select_related('group').order_by('group__sort_order', 'sort_order', 'id')
            return ' / '.join(v.value for v in values)

        def make_line(product_name, quantity=1, sku_index=0):
            product = self.products[product_name]
            sku = pick_sku(product_name, sku_index)
            return {
                'product': product,
                'sku': sku,
                'name': product.name,
                'spec': spec_text(sku),
                'price': sku.price if sku else product.price,
                'quantity': quantity,
                'image': sku.image if sku and sku.image else product.image,
            }

        def create_order(seed, status, lines, address, discount=Decimal('0.00')):
            total = sum(line['price'] * line['quantity'] for line in lines)
            freight = Decimal('0.00') if total >= Decimal('99.00') else Decimal('10.00')
            payment = max(Decimal('0.00'), total + freight - discount)
            order = Order.objects.create(
                id=make_order_num(seed),
                user=user,
                store='潮流优品官方旗舰店',
                status=status,
                total_amount=total,
                payment=payment,
                freight=freight,
                discount=discount,
                address_name=address.name,
                address_phone=address.phone,
                address_province=address.province,
                address_city=address.city,
                address_district=address.district,
                address_detail=address.detail,
                pay_time=timezone.now() if status in ('paid', 'shipped', 'completed') else None,
            )
            for line in lines:
                OrderProduct.objects.create(
                    order=order,
                    product_id=line['product'].id,
                    name=line['name'],
                    spec=line['spec'],
                    price=line['price'],
                    quantity=line['quantity'],
                    image=line['image'],
                )
            return order

        create_order(1, 'pending', [
            make_line('法式碎花连衣裙', 1, 0),
            make_line('纯棉宽松T恤', 1, 2),
        ], addr1)

        create_order(2, 'paid', [
            make_line('高腰直筒牛仔裤', 1, 4),
            make_line('无线充电器', 1, 1),
        ], addr1, discount=Decimal('10.00'))

        create_order(3, 'shipped', [
            make_line('简约真皮腕表', 1, 1),
        ], addr2)

        create_order(4, 'completed', [
            make_line('无线蓝牙耳机', 1, 1),
            make_line('极简陶瓷咖啡杯', 2, 0),
        ], addr1, discount=Decimal('20.00'))

        create_order(5, 'cancelled', [
            make_line('玻尿酸保湿面膜', 1, 0),
        ], addr2)

        self.stdout.write(f'  Created {Order.objects.filter(user=user).count()} orders')

    def _create_coupons(self):
        self.stdout.write('\nCreating coupons...')
        user = User.objects.get(username='testuser')
        coupons_data = [
            {'name': '新人专享券', 'value': 20, 'threshold': '满100元减20元', 'description': '全场通用，新用户首单可用', 'status': 'available', 'time': '2026-12-31'},
            {'name': '满50减10', 'value': 10, 'threshold': '满50元减10元', 'description': '服饰、美妆、家居均可用', 'status': 'available', 'time': '2026-11-30'},
            {'name': '无门槛券', 'value': 5, 'threshold': '无门槛', 'description': '任意商品可直接抵扣', 'status': 'available', 'time': '2026-10-31'},
            {'name': '会员专享券', 'value': 30, 'threshold': '满199元减30元', 'description': '会员日专属福利', 'status': 'used', 'time': '2026-09-30'},
            {'name': '夏日清仓券', 'value': 50, 'threshold': '满299元减50元', 'description': '活动已结束', 'status': 'expired', 'time': '2026-06-30'},
        ]
        for cp_data in coupons_data:
            coupon, created = UserCoupon.objects.get_or_create(
                user=user,
                name=cp_data['name'],
                defaults={
                    'value': cp_data['value'],
                    'threshold': cp_data['threshold'],
                    'description': cp_data['description'],
                    'time': cp_data['time'],
                    'status': cp_data['status'],
                }
            )
            if not created:
                coupon.value = cp_data['value']
                coupon.threshold = cp_data['threshold']
                coupon.description = cp_data['description']
                coupon.time = cp_data['time']
                coupon.status = cp_data['status']
                coupon.save()
            self.stdout.write(f'  {"Created" if created else "Exists"}: {cp_data["name"]}')

    def _create_favorites(self):
        self.stdout.write('\nCreating favorites...')
        user = User.objects.get(username='testuser')
        Favorite.objects.filter(user=user).delete()
        for product_name in ['简约真皮腕表', '无线蓝牙耳机', '法式碎花连衣裙', '跑步鞋']:
            product = self.products.get(product_name)
            if not product:
                continue
            Favorite.objects.create(
                user=user,
                product_id=product.id,
                name=product.name,
                price=product.price,
                original_price=product.original_price,
                image=product.image,
                sales=f'{product.sales_count}+'
            )
            self.stdout.write(f'  Favorite: {product.name}')

    def _create_notifications(self):
        self.stdout.write('\nCreating notifications...')
        user = User.objects.get(username='testuser')
        Notification.objects.filter(user=user).delete()
        notifications_data = [
            ('logistics', '包裹运输中', '2分钟前', '你的简约真皮腕表已到达上海浦东分拨中心，预计明天送达。', '查看物流', False),
            ('order', '订单待支付', '15分钟前', '你有一笔订单尚未支付，30分钟后将自动关闭。', '去支付', False),
            ('promo', '会员日优惠', '今天 10:00', '会员专享满199减30券已发放，可在结算页直接使用。', '去使用', False),
            ('sys', '账号安全提醒', '昨天 20:30', '检测到你在新设备登录，如非本人操作请及时修改密码。', '查看详情', True),
            ('order', '退款进度更新', '昨天 12:20', '你的退款申请已通过，款项将在1-3个工作日原路退回。', '查看订单', True),
        ]
        for notif_type, name, time, content, action, is_read in notifications_data:
            Notification.objects.create(
                user=user,
                type=notif_type,
                name=name,
                time=time,
                content=content,
                action=action,
                is_read=is_read,
            )
            self.stdout.write(f'  Notification: {name}')

    def _create_shop_and_vip(self):
        self.stdout.write('\nCreating shop and VIP info...')
        user = User.objects.get(username='testuser')
        shop, _ = ShopInfo.objects.get_or_create(pk=1)
        shop.name = '潮流优品官方旗舰店'
        shop.description = '专注年轻人日常穿搭、数码配件与品质生活好物'
        shop.score = Decimal('4.9')
        shop.product_count = Product.objects.count()
        shop.sales = '12.8万'
        shop.fans_count = '56.2万'
        shop.save()

        vip, _ = VIPMembership.objects.get_or_create(user=user)
        vip.level = 'silver'
        vip.points = max(vip.points, 1280)
        vip.growth_value = max(vip.growth_value, 2680)
        vip.expire_date = (timezone.now() + timedelta(days=365)).date()
        vip.save()
        self.stdout.write('  ShopInfo and VIP ready')
