import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ecommerce_dj.settings')
django.setup()

from backend.models import (
    Category, Subcategory, Product,
    HomeBanner, HomeFlashSale, HomeHotRank, HomeRecommend, HomeNewArrival, HomePromotion,
    SpecGroup, SpecValue, SKU, Review, ProductDetail,
    Address, UserCoupon, CartItem
)
from mediafiles.models import MediaFile
from decimal import Decimal


# ============== 辅助函数 ==============
def get_media(original_name):
    return MediaFile.objects.filter(original_name=original_name).first()


# ============== 一级分类 ==============
categories_data = [
    ('女装', 'icon-fashion-01.webp', 'banner-1-summer-1710.webp'),
    ('男装', 'icon-mens-02.webp', 'banner-2-newarrival-1710.webp'),
    ('美妆护肤', 'icon-skincare-03.webp', 'banner-3-discount-1710.webp'),
    ('数码电子', 'icon-phone-04.webp', 'banner-1-summer-1710.webp'),
    ('家居生活', 'icon-home-05.webp', 'banner-2-newarrival-1710.webp'),
    ('运动户外', 'icon-sport-06.webp', 'banner-3-discount-1710.webp'),
    ('食品生鲜', 'icon-food-07.webp', 'banner-1-summer-1710.webp'),
    ('潮流配饰', 'icon-beauty-08.webp', 'banner-2-newarrival-1710.webp'),
]

print("Creating categories...")
categories = {}
for name, icon_file, banner_file in categories_data:
    icon_media = get_media(icon_file)
    banner_media = get_media(banner_file)
    cat, created = Category.objects.get_or_create(name=name)
    if icon_media:
        cat.icon = icon_media
    if banner_media:
        cat.banner = banner_media
    cat.save()
    categories[name] = cat
    print(f"  {'Created' if created else 'Updated'}: {name}")


# ============== 二级分类 ==============
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

print("\nCreating subcategories...")
subcategories = {}
for cat_name, subcat_list in subcategories_data.items():
    icon_file = [k for k, v in [
        ('女装', 'icon-fashion-01.webp'), ('男装', 'icon-mens-02.webp'),
        ('美妆护肤', 'icon-skincare-03.webp'), ('数码电子', 'icon-phone-04.webp'),
        ('家居生活', 'icon-home-05.webp'), ('运动户外', 'icon-sport-06.webp'),
        ('食品生鲜', 'icon-food-07.webp'), ('潮流配饰', 'icon-beauty-08.webp'),
    ] if v[0] == cat_name][0] if False else f"icon-{cat_name[:2]}-01.webp"

    for subcat_name in subcat_list:
        icon_media = get_media(f"icon-{cat_name[:2]}-01.webp")
        subcat, created = Subcategory.objects.get_or_create(
            name=subcat_name,
            category=categories[cat_name]
        )
        if icon_media:
            subcat.icon = icon_media
            subcat.save()
        key = f"{cat_name}:{subcat_name}"
        subcategories[key] = subcat
        print(f"  {'Created' if created else 'Exists'}: {cat_name} > {subcat_name}")


# ============== 产品图片映射 ==============
product_image_map = {
    # Original products
    '时尚简约腕表': 'product-01-watch.webp',
    '无线蓝牙耳机': 'product-02-earbuds.webp',
    '极简陶瓷咖啡杯': 'product-03-mug.webp',
    '有机护肤精华液': 'product-04-serum.webp',
    '经典帆布硫化鞋': 'product-05-sneakers.webp',
    '头层牛皮钱包': 'product-06-wallet.webp',
    '复古飞行员太阳镜': 'product-07-sunglasses.webp',
    '多肉植物盆栽': 'product-08-plantpot.webp',
    '手账笔记本 A5': 'product-09-notebook.webp',
    '天然香薰蜡烛 150g': 'product-10-candle.webp',
    '文艺帆布托特包': 'product-11-tote.webp',
    '不锈钢保温水瓶 750ml': 'product-12-bottle.webp',
    # New products - 女装
    '法式碎花连衣裙': 'product-11-tote.webp',
    '纯棉宽松T恤': 'product-03-mug.webp',
    '休闲长袖衬衫': 'product-05-sneakers.webp',
    '高腰直筒牛仔裤': 'product-05-sneakers.webp',
    '百褶半身长裙': 'product-01-watch.webp',
    # New products - 男装
    '经典纯白T恤': 'product-05-sneakers.webp',
    '休闲商务衬衫': 'product-03-mug.webp',
    '修身直筒裤': 'product-05-sneakers.webp',
    '飞行员夹克': 'product-11-tote.webp',
    '加绒连帽卫衣': 'product-11-tote.webp',
    # New products - 美妆护肤
    '玻尿酸保湿精华液': 'product-04-serum.webp',
    '氨基酸洁面乳': 'product-02-earbuds.webp',
    '经典女士香水': 'product-03-mug.webp',
    '控油粉底液': 'product-04-serum.webp',
    '便携旅行套装': 'product-04-serum.webp',
    # New products - 数码电子
    '无线蓝牙耳机Pro': 'product-02-earbuds.webp',
    '便携蓝牙音箱': 'product-03-mug.webp',
    '快充充电宝': 'product-12-bottle.webp',
    # New products - 家居生活
    '不锈钢保温水瓶': 'product-12-bottle.webp',
    '全棉四件套': 'product-11-tote.webp',
    '智能LED台灯': 'product-01-watch.webp',
    # New products - 运动户外
    '瑜伽垫加厚': 'product-04-serum.webp',
    '双肩背包旅行': 'product-11-tote.webp',
    # New products - 食品生鲜
    '进口混合坚果': 'product-12-bottle.webp',
    '云南古树普洱': 'product-03-mug.webp',
    # New products - 潮流配饰
    '简约真皮腕表': 'product-01-watch.webp',
    '复古墨镜': 'product-05-sneakers.webp',
    '轻奢手提包': 'product-11-tote.webp',
}


# ============== 商品（关联二级分类） ==============
products_data = [
    # 女装
    ('法式碎花连衣裙', '优雅碎花设计，夏季必备', 189, 259, '女装', 8500, 4.8, 1200, '女装:连衣裙'),
    ('纯棉宽松T恤', '舒适纯棉面料，透气性好', 79, 99, '女装', 12000, 4.6, 800, '女装:T恤'),
    ('休闲长袖衬衫', '休闲百搭，职场必备', 129, 169, '女装', 6500, 4.7, 520, '女装:衬衫'),
    ('高腰直筒牛仔裤', '显瘦百搭款，修饰腿型', 159, 199, '女装', 5600, 4.7, 650, '女装:牛仔裤'),
    ('百褶半身长裙', '气质百褶设计，优雅大方', 139, 179, '女装', 3200, 4.5, 420, '女装:半身裙'),
    # 男装
    ('经典纯白T恤', '百搭基础款，简约时尚', 99, 129, '男装', 9800, 4.8, 1500, '男装:T恤'),
    ('休闲商务衬衫', '上班休闲两不误', 149, 199, '男装', 4500, 4.6, 780, '男装:衬衫'),
    ('修身直筒裤', '简约设计，舒适穿着', 179, 229, '男装', 3800, 4.7, 620, '男装:裤装'),
    ('飞行员夹克', '时尚帅气，秋季必备', 299, 399, '男装', 2800, 4.9, 520, '男装:外套'),
    ('加绒连帽卫衣', '保暖时尚，休闲百搭', 159, 219, '男装', 4200, 4.6, 890, '男装:卫衣'),
    # 美妆护肤
    ('玻尿酸保湿精华液', '深层补水保湿', 159, 219, '美妆', 15000, 4.7, 2300, '美妆护肤:护肤'),
    ('氨基酸洁面乳', '温和清洁不刺激', 89, 119, '美妆', 22000, 4.5, 1800, '美妆护肤:护肤'),
    ('经典女士香水', '优雅气质，持久留香', 259, 329, '美妆', 5100, 4.8, 920, '美妆护肤:香水'),
    ('控油粉底液', '轻薄遮瑕，持久控油', 149, 199, '美妆', 7800, 4.6, 1100, '美妆护肤:彩妆'),
    ('便携旅行套装', '出行方便，随时补水', 99, 139, '美妆', 5600, 4.5, 780, '美妆护肤:个护'),
    # 数码电子
    ('无线蓝牙耳机Pro', '主动降噪，高品质音效', 299, 399, '数码', 35000, 4.8, 4500, '数码电子:耳机'),
    ('便携蓝牙音箱', '小巧便携，音质出色', 199, 259, '数码', 18000, 4.6, 2100, '数码电子:音箱'),
    ('快充充电宝', '大容量快充，旅行必备', 129, 169, '数码', 25000, 4.7, 3200, '数码电子:配件'),
    # 家居生活
    ('不锈钢保温水瓶', '持久保温，保冷保热', 89, 129, '家居', 12000, 4.5, 1600, '家居生活:厨具'),
    ('全棉四件套', '柔软舒适，睡眠质量', 259, 359, '家居', 4200, 4.8, 890, '家居生活:家纺'),
    ('智能LED台灯', '护眼设计，多档调光', 99, 149, '家居', 15000, 4.6, 2100, '家居生活:家装'),
    ('手账笔记本 A5', '优质纸张，精致装订', 35, 69, '家居', 12000, 4.5, 890, '家居生活:收纳'),
    # 运动户外
    ('经典帆布硫化鞋', '时尚百搭，舒适透气', 159, 219, '运动', 20000, 4.7, 2800, '运动户外:运动鞋'),
    ('瑜伽垫加厚', '防滑耐用，健身必备', 89, 129, '运动', 16000, 4.5, 1900, '运动户外:健身'),
    ('双肩背包旅行', '大容量防水，适合户外', 199, 279, '运动', 7800, 4.8, 1100, '运动户外:户外'),
    # 食品生鲜
    ('进口混合坚果', '营养健康，每日必备', 89, 119, '食品', 18000, 4.6, 2200, '食品生鲜:零食'),
    ('云南古树普洱', '正宗云南产，醇香回甘', 159, 219, '食品', 4500, 4.9, 780, '食品生鲜:茶叶'),
    # 潮流配饰
    ('简约真皮腕表', '时尚简约，真皮表带', 299, 399, '配饰', 12000, 4.8, 1800, '潮流配饰:腕表'),
    ('复古墨镜', '遮阳防晒，时尚复古', 159, 219, '配饰', 6800, 4.5, 950, '潮流配饰:眼镜'),
    ('轻奢手提包', '品质皮料，大容量', 399, 559, '配饰', 3200, 4.9, 620, '潮流配饰:包包'),
]

print("\nCreating products...")
products = {}
for name, desc, price, original, tag, sales, rating, reviews, subcat_key in products_data:
    subcat = subcategories.get(subcat_key)
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
        img_media = get_media(img_name)
        if img_media:
            prod.image = img_media
            prod.save()

    products[name] = prod
    print(f"  {'Created' if created else 'Updated'}: {name} -> {subcat_key}")


# ============== 为产品添加详情 ==============
print("\nCreating product details...")
from backend.models import ProductDetail
for prod_name, img_name in product_image_map.items():
    prod = products.get(prod_name)
    if not prod:
        continue
    detail, created = ProductDetail.objects.get_or_create(product=prod)
    detail.shop_name = '优品生活馆'
    img_media = get_media(img_name)
    if img_media:
        detail.shop_logo = img_media
        detail.images.add(img_media)
        detail.detail_images.add(img_media)
    detail.save()
    print(f"  {'Created' if created else 'Updated'}: {prod_name}")


# ============== 为每个产品添加规格和SKU ==============
spec_data = {
    # 女装
    '法式碎花连衣裙': [('尺码', ['S', 'M', 'L', 'XL']), ('颜色', ['碎花', '纯色'])],
    '纯棉宽松T恤': [('尺码', ['S', 'M', 'L', 'XL']), ('颜色', ['白色', '黑色', '灰色'])],
    '休闲长袖衬衫': [('尺码', ['S', 'M', 'L', 'XL']), ('颜色', ['白色', '蓝色', '粉色'])],
    '高腰直筒牛仔裤': [('尺码', ['26', '27', '28', '29', '30', '31']), ('颜色', ['深蓝', '浅蓝', '黑色'])],
    '百褶半身长裙': [('尺码', ['S', 'M', 'L']), ('颜色', ['黑色', '米色', '灰色'])],
    # 男装
    '经典纯白T恤': [('尺码', ['S', 'M', 'L', 'XL', 'XXL']), ('颜色', ['白色', '黑色'])],
    '休闲商务衬衫': [('尺码', ['S', 'M', 'L', 'XL']), ('颜色', ['白色', '浅蓝', '粉色'])],
    '修身直筒裤': [('尺码', ['S', 'M', 'L', 'XL']), ('颜色', ['黑色', '深灰', '卡其'])],
    '飞行员夹克': [('尺码', ['S', 'M', 'L', 'XL']), ('颜色', ['黑色', '军绿', '棕色'])],
    '加绒连帽卫衣': [('尺码', ['S', 'M', 'L', 'XL']), ('颜色', ['黑色', '灰色', '藏青'])],
    # 美妆护肤
    '玻尿酸保湿精华液': [('容量', ['30ml', '50ml', '100ml'])],
    '氨基酸洁面乳': [('规格', ['100ml', '150ml'])],
    '经典女士香水': [('香型', ['花香', '果香', '木质香']), ('规格', ['30ml', '50ml', '100ml'])],
    '控油粉底液': [('色号', ['01亮肤色', '02自然色', '03小麦色']), ('规格', ['30ml', '50ml'])],
    '便携旅行套装': [('类型', ['护肤套装', '彩妆套装'])],
    # 数码电子
    '无线蓝牙耳机Pro': [('颜色', ['黑色', '白色', '蓝色']), ('版本', ['标配版', 'Pro版'])],
    '便携蓝牙音箱': [('颜色', ['黑色', '白色', '红色']), ('版本', ['标准版', '迷你版'])],
    '快充充电宝': [('容量', ['5000mAh', '10000mAh', '20000mAh']), ('颜色', ['黑色', '白色'])],
    # 家居生活
    '不锈钢保温水瓶': [('容量', ['500ml', '750ml', '1L']), ('颜色', ['银色', '黑色', '白色'])],
    '全棉四件套': [('规格', ['1.5米床', '1.8米床', '2.0米床']), ('颜色', ['纯白', '浅灰', '粉色'])],
    '智能LED台灯': [('功率', ['5W', '10W', '15W']), ('颜色', ['白色', '黑色'])],
    # 运动户外
    '瑜伽垫加厚': [('厚度', ['6mm', '8mm', '10mm']), ('颜色', ['粉色', '紫色', '绿色', '蓝色'])],
    '双肩背包旅行': [('容量', ['20L', '30L', '40L']), ('颜色', ['黑色', '灰色', '军绿'])],
    # 食品生鲜
    '进口混合坚果': [('规格', ['每日坚果30包', '礼盒装']), ('口味', ['原味', '盐焗', '蜂蜜'])],
    '云南古树普洱': [('规格', ['357g饼茶', '100g散茶']), ('年份', ['2019年', '2020年', '2021年'])],
    # 潮流配饰
    '简约真皮腕表': [('颜色', ['黑色', '棕色', '银色']), ('表带', ['皮质', '钢带'])],
    '复古墨镜': [('镜片', ['透明', '偏光', '变色']), ('框型', ['圆框', '方框', '椭圆'])],
    '轻奢手提包': [('颜色', ['黑色', '棕色', '米色']), ('尺寸', ['小号', '中号', '大号'])],
    # Original products
    '时尚简约腕表': [('颜色', ['黑色', '银色', '金色']), ('规格', ['标准版', '限量版'])],
    '无线蓝牙耳机': [('颜色', ['黑色', '白色', '蓝色']), ('套餐', ['标配', '升级版'])],
    '极简陶瓷咖啡杯': [('图案', ['大理石纹', '纯色', '渐变'])],
    '有机护肤精华液': [('容量', ['30ml', '50ml', '100ml'])],
    '经典帆布硫化鞋': [('颜色', ['白色', '黑色', '灰色']), ('尺码', ['39', '40', '41', '42', '43'])],
    '头层牛皮钱包': [('颜色', ['黑色', '棕色', '深蓝'])],
    '复古飞行员太阳镜': [('镜片', ['透明', '偏光', '变色'])],
    '多肉植物盆栽': [('品种', ['熊童子', '玉露', '桃蛋'])],
    '手账笔记本 A5': [('封面', ['牛皮纸', '布面', '皮面'])],
    '天然香薰蜡烛 150g': [('香型', ['薰衣草', '玫瑰', '柠檬'])],
    '文艺帆布托特包': [('图案', ['纯色', '印花', '扎染'])],
    '不锈钢保温水瓶 750ml': [('颜色', ['银色', '黑色', '白色'])],
}

# Clear existing SKUs and SpecValues to regenerate
print("\nClearing existing SKUs and SpecValues...")
SKU.objects.all().delete()
SpecValue.objects.all().delete()
SpecGroup.objects.filter(product__isnull=False).delete()

print("\nCreating specs and SKUs...")
from itertools import product as iter_product
for prod_name, spec_groups in spec_data.items():
    prod = products.get(prod_name)
    if not prod:
        continue

    # Create spec groups and values
    group_values = {}  # group_name -> [(spec_value_obj, value_name), ...]
    for group_name, values in spec_groups:
        sg, _ = SpecGroup.objects.get_or_create(product=prod, name=group_name)
        group_values[group_name] = []
        for val in values:
            sv, sv_created = SpecValue.objects.get_or_create(group=sg, value=val)
            group_values[group_name].append((sv, val))
            if sv_created:
                print(f"    Created spec value: {prod_name} > {group_name} > {val}")

    # Generate all combinations of spec values across groups
    group_names = list(group_values.keys())
    all_combinations = []
    for combo in iter_product(*[group_values[gn] for gn in group_names]):
        all_combinations.append(combo)  # combo is a tuple of (spec_value_obj, value_name) per group

    # Create one SKU per combination
    for combo in all_combinations:
        sku = SKU.objects.create(
            product=prod,
            price=prod.price,
            original_price=prod.original_price,
            stock=100,
        )
        for sv, val_name in combo:
            sku.spec_values.add(sv)
        print(f"    Created SKU: {prod_name} - {' / '.join([v for _, v in combo])}")


# ============== 为产品添加评论 ==============
review_data = [
    ('时尚简约腕表', '张**', 5, '款式非常好看，佩戴舒适，很满意！'),
    ('时尚简约腕表', '李**', 4, '质量不错，走时准确，就是表带有点硬。'),
    ('无线蓝牙耳机', '王**', 5, '降噪效果超赞，音质清晰，续航给力！'),
    ('无线蓝牙耳机', '赵**', 5, '佩戴舒适，连接稳定，强烈推荐！'),
    ('极简陶瓷咖啡杯', '孙**', 4, '做工精细，容量刚好，适合喝茶。'),
    ('有机护肤精华液', '周**', 5, '补水效果明显，肌肤明显变好了！'),
    ('有机护肤精华液', '吴**', 4, '稍微有点黏腻，但吸收很快。'),
    ('经典帆布硫化鞋', '郑**', 5, '穿起来很舒服，透气性好，样式好看。'),
    ('头层牛皮钱包', '陈**', 5, '皮质很好，手感细腻，很高档。'),
    ('复古飞行员太阳镜', '林**', 4, '款式经典，镜片清晰，遮阳效果好。'),
    ('多肉植物盆栽', '黄**', 5, '植物很健康，盆栽设计漂亮。'),
    ('手账笔记本 A5', '刘**', 4, '纸张质量好，写起来很顺滑。'),
    ('天然香薰蜡烛 150g', '许**', 5, '香味持久怡人，点燃后氛围很好。'),
    ('文艺帆布托特包', '何**', 4, '容量大，质量不错，适合日常使用。'),
    ('不锈钢保温水瓶 750ml', '罗**', 5, '保温效果好，早上装热水晚上还是热的。'),
]

print("\nCreating reviews...")
for prod_name, user_name, rating, content in review_data:
    prod = products.get(prod_name)
    if not prod:
        continue
    rev, created = Review.objects.get_or_create(
        product=prod,
        user_name=user_name,
        defaults={
            'rating': rating,
            'content': content,
        }
    )
    if created:
        print(f"    Created review: {prod_name} by {user_name}")

# Update product review counts
print("\nUpdating product review counts...")
from django.db.models import Count, Avg
for prod in Product.objects.all():
    stats = Review.objects.filter(product=prod).aggregate(
        count=Count('id'),
        avg_rating=Avg('rating')
    )
    prod.review_count = stats['count'] or 0
    if stats['avg_rating']:
        prod.rating = Decimal(str(round(stats['avg_rating'], 1)))
    prod.save()
    print(f"  {prod.name}: {prod.review_count} reviews, avg rating: {prod.rating}")


# ============== 首页轮播图 ==============
banners_data = [
    ('banner-1-summer-1710.webp', 'summer', '夏季焕新\n全场低至5折', '立即选购', 0),
    ('banner-new-1710.webp', 'new', '当季新款\n潮流抢先穿', '查看全部', 1),
    ('banner-flash-1710.webp', 'flash', '爆款直降\n再享折上折', '马上抢', 2),
]

print("\nCreating home banners...")
for img, tag, title, action, gradient in banners_data:
    banner_media = get_media(img)
    ban, created = HomeBanner.objects.get_or_create(
        tag=tag,
        defaults={
            'title': title,
            'action_title': action,
            'gradient_type': gradient,
            'sort_order': gradient,
            'is_enabled': True,
        }
    )
    if banner_media:
        ban.image = banner_media
        ban.save()
    print(f"  {'Created' if created else 'Updated'}: {tag}")


# ============== 限时秒杀 ==============
print("\nCreating flash sale section...")
flashsale, created = HomeFlashSale.objects.get_or_create(
    title='限时秒杀',
    defaults={
        'subtitle': '爆款直降，限时抢购',
        'start_time': None,
        'end_time': None,
        'sort_order': 0,
        'is_enabled': True,
    }
)
flashsale_products = Product.objects.filter(name__in=[
    '时尚简约腕表', '无线蓝牙耳机', '极简陶瓷咖啡杯', '有机护肤精华液', '经典帆布硫化鞋'
])
for prod in flashsale_products:
    flashsale.products.add(prod)
print(f"  Done: {flashsale.title} ({flashsale.products.count()} products)")


# ============== 热销榜单 ==============
print("\nCreating hot rank section...")
hotrank, created = HomeHotRank.objects.get_or_create(
    title='热销榜单',
    defaults={
        'sort_order': 0,
        'is_enabled': True,
    }
)
hotrank_products = Product.objects.filter(name__in=[
    '头层牛皮钱包', '复古飞行员太阳镜', '多肉植物盆栽', '手账笔记本 A5'
])
for prod in hotrank_products:
    hotrank.products.add(prod)
print(f"  Done: {hotrank.title} ({hotrank.products.count()} products)")


# ============== 为你推荐 ==============
print("\nCreating recommend section...")
recommend, created = HomeRecommend.objects.get_or_create(
    title='为你推荐',
    defaults={
        'sort_order': 0,
        'is_enabled': True,
    }
)
recommend_products = Product.objects.all()[:8]
for prod in recommend_products:
    recommend.products.add(prod)
print(f"  Done: {recommend.title} ({recommend.products.count()} products)")


# ============== 新品上市 ==============
print("\nCreating new arrival section...")
newarrival, created = HomeNewArrival.objects.get_or_create(
    title='新品上市',
    defaults={
        'sort_order': 0,
        'is_enabled': True,
    }
)
new_products = Product.objects.order_by('-id')[:6]
for prod in new_products:
    newarrival.products.add(prod)
print(f"  Done: {newarrival.title} ({newarrival.products.count()} products)")


# ============== 优惠活动 ==============
promotions_data = [
    ('promo-summer.webp', '夏季焕新', '全场低至5折起', 0),
    ('promo-vip.webp', '会员专享', '新人立减50元', 1),
]

print("\nCreating promotions...")
for img, title, subtitle, sort in promotions_data:
    promo, created = HomePromotion.objects.get_or_create(
        title=title,
        defaults={
            'subtitle': subtitle,
            'sort_order': sort,
            'is_enabled': True,
        }
    )
    print(f"  {'Created' if created else 'Exists'}: {title}")


print("\n=== Done! ===")
print(f"Categories: {Category.objects.count()}")
print(f"Subcategories: {Subcategory.objects.count()}")
print(f"Products: {Product.objects.count()}")
print(f"SpecGroups: {SpecGroup.objects.count()}")
print(f"SpecValues: {SpecValue.objects.count()}")
print(f"SKUs: {SKU.objects.count()}")
print(f"Reviews: {Review.objects.count()}")
print(f"HomeBanners: {HomeBanner.objects.count()}")

# ============== 收货地址 ==============
addresses_data = [
    {'name': '林小琳', 'phone': '138****1234', 'province': '广东省', 'city': '深圳市', 'district': '南山区', 'detail': '科技园路100号A栋1201', 'is_default': True},
    {'name': '林小琳', 'phone': '138****1234', 'province': '广东省', 'city': '广州市', 'district': '天河区', 'detail': '体育西路123号', 'is_default': False},
]

print("\nCreating addresses...")
for addr_data in addresses_data:
    addr, created = Address.objects.get_or_create(
        user_id='u1',
        name=addr_data['name'],
        defaults=addr_data
    )
    print(f"  {'Created' if created else 'Exists'}: {addr_data['name']} - {addr_data['province']}{addr_data['city']}")

# ============== 用户优惠券 ==============
coupons_data = [
    {'name': '新人专享券', 'value': '20', 'threshold': '100', 'description': '满100元减20元'},
    {'name': '满50减10', 'value': '10', 'threshold': '50', 'description': '满50元减10元'},
    {'name': '无门槛券', 'value': '5', 'threshold': '0', 'description': '无门槛使用'},
]

print("\nCreating coupons...")
for cp_data in coupons_data:
    coupon, created = UserCoupon.objects.get_or_create(
        user_id='u1',
        name=cp_data['name'],
        defaults={
            'value': Decimal(cp_data['value']),
            'threshold': Decimal(cp_data['threshold']),
            'description': cp_data['description'],
            'time': '2026-12-31'
        }
    )
    print(f"  {'Created' if created else 'Exists'}: {cp_data['name']}")

# ============== 购物车商品（关联真实商品）==============
print("\nCreating cart items...")
# 获取一些真实商品
sample_products = list(Product.objects.all()[:5])
for i, prod in enumerate(sample_products):
    cart_item, created = CartItem.objects.get_or_create(
        user_id='u1',
        product=prod,
        defaults={'quantity': (i % 3) + 1, 'is_selected': i < 3}  # 前3个选中
    )
    if created:
        print(f"  Created cart item: {prod.name} x{cart_item.quantity}")

print(f"\nFinal CartItems: {CartItem.objects.count()}")
print(f"Final Addresses: {Address.objects.count()}")
print(f"Final Coupons: {UserCoupon.objects.count()}")