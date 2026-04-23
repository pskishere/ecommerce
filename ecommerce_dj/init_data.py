import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ecommerce_dj.settings')
django.setup()

from backend.models import *

print("Creating categories...")
c1 = Category.objects.create(name='女装', icon_name='./static/images/icon-fashion-01.webp', banner_name='./static/images/banner-1-summer-1710.webp')
c2 = Category.objects.create(name='男装', icon_name='./static/images/icon-mens-02.webp', banner_name='./static/images/banner-1-summer-1710.webp')
c3 = Category.objects.create(name='美妆护肤', icon_name='./static/images/icon-skincare-03.webp', banner_name='./static/images/banner-2-newarrival-1710.webp')
c4 = Category.objects.create(name='数码电子', icon_name='./static/images/icon-phone-04.webp', banner_name='./static/images/banner-2-newarrival-1710.webp')
c5 = Category.objects.create(name='家居生活', icon_name='./static/images/icon-home-05.webp', banner_name='./static/images/banner-3-discount-1710.webp')
c6 = Category.objects.create(name='运动户外', icon_name='./static/images/icon-sport-06.webp', banner_name='./static/images/banner-3-discount-1710.webp')
c7 = Category.objects.create(name='食品生鲜', icon_name='./static/images/icon-food-07.webp', banner_name='./static/images/banner-1-summer-1710.webp')
c8 = Category.objects.create(name='潮流配饰', icon_name='./static/images/icon-beauty-08.webp', banner_name='./static/images/banner-2-newarrival-1710.webp')
print(f"  Created {Category.objects.count()} categories")

print("Creating products with details...")

def create_product(name, desc, price, original_price, image_name, category, rating, reviews, sales, tag, shop_name, images, detail_images, spec_groups_data):
    p = Product.objects.create(
        name=name, description=desc, price=price, original_price=original_price,
        image_name=image_name, category=category, rating=rating, review_count=reviews,
        sales_count=sales, is_in_stock=True, tag=tag
    )
    ProductDetail.objects.create(
        product=p, shop_name=shop_name, shop_logo='./static/images/product-01-watch.webp',
        images=images, detail_images=detail_images
    )
    for sg_data in spec_groups_data:
        sg = SpecGroup.objects.create(product=p, name=sg_data['name'], sort_order=sg_data.get('sort_order', 0))
        for sv in sg_data['values']:
            SpecValue.objects.create(group=sg, value=sv['value'], image_name=sv.get('image', ''), sort_order=sv.get('sort', 0))
    # Refresh to get spec_groups with values
    sg_list = list(SpecGroup.objects.filter(product=p).prefetch_related('values'))
    for sku_data in spec_groups_data[0]['values']:
        for sku_size in spec_groups_data[1]['values']:
            color_sv = SpecValue.objects.get(group=sg_list[0], value=sku_data['value'])
            size_sv = SpecValue.objects.get(group=sg_list[1], value=sku_size['value'])
            sku_price = price
            sku_stock = 50 if sku_size['value'] != 'M' else 0  # M out of stock for demo
            sku = SKU.objects.create(product=p, price=sku_price, original_price=original_price, stock=sku_stock)
            SKUSpec.objects.create(sku=sku, spec_value=color_sv)
            SKUSpec.objects.create(sku=sku, spec_value=size_sv)
    return p

# Product 1: Dress with color + size specs
p1 = create_product(
    name='法式碎花连衣裙',
    desc='优雅碎花图案，轻薄透气面料，适合夏季穿着',
    price=189.00, original_price=299.00,
    image_name='./static/images/product-10-candle.webp',
    category=c1, rating=4.6, reviews=320, sales=8600, tag='热卖',
    shop_name='潮流优品官方旗舰店',
    images=['./static/images/product-10-candle.webp', './static/images/product-11-tote.webp', './static/images/product-08-plantpot.webp'],
    detail_images=['./static/images/banner-1-summer-1710.webp', './static/images/banner-2-newarrival-1710.webp'],
    spec_groups_data=[
        {'name': '颜色', 'sort_order': 1, 'values': [
            {'value': '白色', 'sort': 1}, {'value': '黑色', 'sort': 2}, {'value': '红色', 'sort': 3}
        ]},
        {'name': '尺码', 'sort_order': 2, 'values': [
            {'value': 'S', 'sort': 1}, {'value': 'M', 'sort': 2}, {'value': 'L', 'sort': 3}, {'value': 'XL', 'sort': 4}
        ]}
    ]
)
print(f"  Created product: {p1.name} (ID: {p1.id})")

# Product 2: T-shirt
p2 = create_product(
    name='纯棉宽松T恤',
    desc='100%纯棉，宽松版型，百搭款式',
    price=79.00, original_price=129.00,
    image_name='./static/images/product-11-tote.webp',
    category=c1, rating=4.5, reviews=580, sales=12000, tag='爆款',
    shop_name='潮流优品官方旗舰店',
    images=['./static/images/product-11-tote.webp'],
    detail_images=['./static/images/banner-1-summer-1710.webp'],
    spec_groups_data=[
        {'name': '颜色', 'sort_order': 1, 'values': [
            {'value': '白色', 'sort': 1}, {'value': '黑色', 'sort': 2}, {'value': '灰色', 'sort': 3}
        ]},
        {'name': '尺码', 'sort_order': 2, 'values': [
            {'value': 'M', 'sort': 1}, {'value': 'L', 'sort': 2}, {'value': 'XL', 'sort': 3}
        ]}
    ]
)
print(f"  Created product: {p2.name} (ID: {p2.id})")

# Product 3: Jeans
p3 = create_product(
    name='高腰直筒牛仔裤',
    desc='高腰设计，显瘦直筒版型，经典靛蓝色',
    price=159.00, original_price=259.00,
    image_name='./static/images/product-01-watch.webp',
    category=c1, rating=4.7, reviews=890, sales=15000, tag='推荐',
    shop_name='潮流优品官方旗舰店',
    images=['./static/images/product-01-watch.webp'],
    detail_images=['./static/images/banner-1-summer-1710.webp'],
    spec_groups_data=[
        {'name': '颜色', 'sort_order': 1, 'values': [
            {'value': '浅蓝', 'sort': 1}, {'value': '深蓝', 'sort': 2}
        ]},
        {'name': '尺码', 'sort_order': 2, 'values': [
            {'value': '26', 'sort': 1}, {'value': '27', 'sort': 2}, {'value': '28', 'sort': 3}, {'value': '29', 'sort': 4}
        ]}
    ]
)
print(f"  Created product: {p3.name} (ID: {p3.id})")

# Product 4: Polo shirt
p4 = Product.objects.create(
    name='商务polo衫', description='珠地棉面料，透气舒适，经典商务款式',
    price=129.00, original_price=199.00, image_name='./static/images/product-05-sneakers.webp',
    category=c2, rating=4.6, review_count=520, sales_count=11000, is_in_stock=True, tag='热卖'
)
ProductDetail.objects.create(product=p4, shop_name='男装精选店', shop_logo='./static/images/icon-mens-02.webp',
    images=['./static/images/product-05-sneakers.webp'], detail_images=[])
print(f"  Created product: {p4.name} (ID: {p4.id})")

# Product 5: Shorts
p5 = Product.objects.create(
    name='休闲牛仔短裤', description='柔软丹宁面料，直筒版型，夏季必备',
    price=99.00, original_price=169.00, image_name='./static/images/product-06-wallet.webp',
    category=c2, rating=4.5, review_count=680, sales_count=13500, is_in_stock=True, tag='爆款'
)
ProductDetail.objects.create(product=p5, shop_name='男装精选店', shop_logo='./static/images/icon-mens-02.webp',
    images=['./static/images/product-06-wallet.webp'], detail_images=[])
print(f"  Created product: {p5.name} (ID: {p5.id})")

# Product 6: Face mask
p6 = Product.objects.create(
    name='玻尿酸保湿面膜10片装', description='深层补水，焕亮肌肤，医美级玻尿酸',
    price=99.00, original_price=169.00, image_name='./static/images/product-04-serum.webp',
    category=c3, rating=4.9, review_count=1200, sales_count=28000, is_in_stock=True, tag='热卖'
)
ProductDetail.objects.create(product=p6, shop_name='美妆护肤专营店', shop_logo='./static/images/icon-skincare-03.webp',
    images=['./static/images/product-04-serum.webp'], detail_images=[])
print(f"  Created product: {p6.name} (ID: {p6.id})")

# Product 7: Cleanser
p7 = Product.objects.create(
    name='氨基酸洁面乳', description='温和清洁，不刺激，适合敏感肌',
    price=89.00, original_price=139.00, image_name='./static/images/product-05-sneakers.webp',
    category=c3, rating=4.8, review_count=890, sales_count=22000, is_in_stock=True, tag='爆款'
)
ProductDetail.objects.create(product=p7, shop_name='美妆护肤专营店', shop_logo='./static/images/icon-skincare-03.webp',
    images=['./static/images/product-05-sneakers.webp'], detail_images=[])
print(f"  Created product: {p7.name} (ID: {p7.id})")

# Product 8: Phone case
p8 = Product.objects.create(
    name='iPhone 15 Pro Max 保护壳', description='液态硅胶材质，精准孔位，防摔保护',
    price=59.00, original_price=99.00, image_name='./static/images/product-01-watch.webp',
    category=c4, rating=4.8, review_count=1500, sales_count=35000, is_in_stock=True, tag='热卖'
)
ProductDetail.objects.create(product=p8, shop_name='数码配件旗舰店', shop_logo='./static/images/icon-phone-04.webp',
    images=['./static/images/product-01-watch.webp'], detail_images=[])
print(f"  Created product: {p8.name} (ID: {p8.id})")

# Product 9: Wireless charger
p9 = Product.objects.create(
    name='无线充电器 15W', description='快充技术，智能识别，多设备兼容',
    price=79.00, original_price=129.00, image_name='./static/images/product-02-earbuds.webp',
    category=c4, rating=4.7, review_count=980, sales_count=25000, is_in_stock=True, tag='爆款'
)
ProductDetail.objects.create(product=p9, shop_name='数码配件旗舰店', shop_logo='./static/images/icon-phone-04.webp',
    images=['./static/images/product-02-earbuds.webp'], detail_images=[])
print(f"  Created product: {p9.name} (ID: {p9.id})")

# Product 10: Storage box
p10 = Product.objects.create(
    name='日式收纳盒三件套', description='优质PP材质，分类收纳，美观实用',
    price=69.00, original_price=109.00, image_name='./static/images/product-08-plantpot.webp',
    category=c5, rating=4.7, review_count=880, sales_count=22000, is_in_stock=True, tag='热卖'
)
ProductDetail.objects.create(product=p10, shop_name='家居生活馆', shop_logo='./static/images/icon-home-05.webp',
    images=['./static/images/product-08-plantpot.webp'], detail_images=[])
print(f"  Created product: {p10.name} (ID: {p10.id})")

# Product 11: Tableware
p11 = Product.objects.create(
    name='骨瓷餐具套装', description='精美骨瓷，釉下彩工艺，环保健康',
    price=199.00, original_price=329.00, image_name='./static/images/product-09-notebook.webp',
    category=c5, rating=4.8, review_count=420, sales_count=9800, is_in_stock=True, tag='爆款'
)
ProductDetail.objects.create(product=p11, shop_name='家居生活馆', shop_logo='./static/images/icon-home-05.webp',
    images=['./static/images/product-09-notebook.webp'], detail_images=[])
print(f"  Created product: {p11.name} (ID: {p11.id})")

# Product 12: Running shoes
p12 = Product.objects.create(
    name='跑步鞋 专业级', description='轻量透气，缓震科技，防滑耐磨',
    price=299.00, original_price=499.00, image_name='./static/images/product-05-sneakers.webp',
    category=c6, rating=4.8, review_count=720, sales_count=18000, is_in_stock=True, tag='热卖'
)
ProductDetail.objects.create(product=p12, shop_name='运动户外专营店', shop_logo='./static/images/icon-sport-06.webp',
    images=['./static/images/product-05-sneakers.webp'], detail_images=[])
print(f"  Created product: {p12.name} (ID: {p12.id})")

# Product 13: Yoga mat
p13 = Product.objects.create(
    name='瑜伽垫 加厚防滑', description='TPE材质，抗菌防滑，舒适当道',
    price=89.00, original_price=149.00, image_name='./static/images/product-02-earbuds.webp',
    category=c6, rating=4.7, review_count=980, sales_count=24000, is_in_stock=True, tag='爆款'
)
ProductDetail.objects.create(product=p13, shop_name='运动户外专营店', shop_logo='./static/images/icon-sport-06.webp',
    images=['./static/images/product-02-earbuds.webp'], detail_images=[])
print(f"  Created product: {p13.name} (ID: {p13.id})")

# Product 14: Fruit box
p14 = Product.objects.create(
    name='新鲜水果礼盒', description='当季精选，产地直发，新鲜配送',
    price=99.00, original_price=169.00, image_name='./static/images/product-08-plantpot.webp',
    category=c7, rating=4.6, review_count=850, sales_count=21000, is_in_stock=True, tag='热卖'
)
ProductDetail.objects.create(product=p14, shop_name='食品生鲜馆', shop_logo='./static/images/icon-food-07.webp',
    images=['./static/images/product-08-plantpot.webp'], detail_images=[])
print(f"  Created product: {p14.name} (ID: {p14.id})")

# Product 15: Nuts
p15 = Product.objects.create(
    name='每日坚果礼盒', description='科学配比，独立包装，健康零食',
    price=79.00, original_price=129.00, image_name='./static/images/product-09-notebook.webp',
    category=c7, rating=4.8, review_count=1300, sales_count=32000, is_in_stock=True, tag='爆款'
)
ProductDetail.objects.create(product=p15, shop_name='食品生鲜馆', shop_logo='./static/images/icon-food-07.webp',
    images=['./static/images/product-09-notebook.webp'], detail_images=[])
print(f"  Created product: {p15.name} (ID: {p15.id})")

# Product 16: Watch
p16 = Product.objects.create(
    name='简约真皮腕表', description='头层牛皮表带，自动机芯，30米防水，百搭款式',
    price=299.00, original_price=899.00, image_name='./static/images/product-01-watch.webp',
    category=c8, rating=4.8, review_count=1200, sales_count=23000, is_in_stock=True, tag='热卖'
)
ProductDetail.objects.create(product=p16, shop_name='潮流配饰专营店', shop_logo='./static/images/icon-beauty-08.webp',
    images=['./static/images/product-01-watch.webp'], detail_images=[])
print(f"  Created product: {p16.name} (ID: {p16.id})")

# Product 17: Sunglasses
p17 = Product.objects.create(
    name='复古飞行员太阳镜', description='UV400防护，金属框，复古时尚',
    price=159.00, original_price=299.00, image_name='./static/images/product-07-sunglasses.webp',
    category=c8, rating=4.6, review_count=980, sales_count=18000, is_in_stock=True, tag='爆款'
)
ProductDetail.objects.create(product=p17, shop_name='潮流配饰专营店', shop_logo='./static/images/icon-beauty-08.webp',
    images=['./static/images/product-07-sunglasses.webp'], detail_images=[])
print(f"  Created product: {p17.name} (ID: {p17.id})")

# Product 18: Earbuds
p18 = Product.objects.create(
    name='无线蓝牙耳机', description='主动降噪，单次续航8小时，轻盈舒适',
    price=199.00, original_price=499.00, image_name='./static/images/product-02-earbuds.webp',
    category=c4, rating=4.7, review_count=890, sales_count=18000, is_in_stock=True, tag='热卖'
)
ProductDetail.objects.create(product=p18, shop_name='数码配件旗舰店', shop_logo='./static/images/icon-phone-04.webp',
    images=['./static/images/product-02-earbuds.webp'], detail_images=[])
print(f"  Created product: {p18.name} (ID: {p18.id})")

# Product 19: Mug
p19 = Product.objects.create(
    name='极简陶瓷咖啡杯', description='高温烧制，大理石纹理，容量350ml',
    price=68.00, original_price=128.00, image_name='./static/images/product-03-mug.webp',
    category=c5, rating=4.6, review_count=560, sales_count=12000, is_in_stock=True, tag='爆款'
)
ProductDetail.objects.create(product=p19, shop_name='家居生活馆', shop_logo='./static/images/icon-home-05.webp',
    images=['./static/images/product-03-mug.webp'], detail_images=[])
print(f"  Created product: {p19.name} (ID: {p19.id})")

print(f"\nTotal products: {Product.objects.count()}")
print(f"Total SKUs: {SKU.objects.count()}")
print(f"Total SpecGroups: {SpecGroup.objects.count()}")
print(f"Total SpecValues: {SpecValue.objects.count()}")

print("\nCreating banners...")
b1 = Banner.objects.create(image_name='./static/images/banner-1-summer-1710.webp', tag='夏装新品', title='清凉一夏', action_title='立即选购')
b2 = Banner.objects.create(image_name='./static/images/banner-2-newarrival-1710.webp', tag='美妆节', title='焕新美妆', action_title='查看详情')
b3 = Banner.objects.create(image_name='./static/images/banner-3-discount-1710.webp', tag='限时特惠', title='折扣专区', action_title='抢购')
print(f"  Created {Banner.objects.count()} banners")

print("\nCreating home sections...")
HomeSection.objects.create(type='banner', name='首页轮播', sort_order=1)
HomeSection.objects.create(type='categories', name='分类导航', sort_order=2)
HomeSection.objects.create(type='flashSale', name='限时秒杀', sort_order=3)
HomeSection.objects.create(type='hotRank', name='热销榜单', sort_order=4)
HomeSection.objects.create(type='recommend', name='为你推荐', sort_order=5)
print(f"  Created {HomeSection.objects.count()} home sections")

print("\nData creation complete!")