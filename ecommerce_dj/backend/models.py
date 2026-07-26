from django.db import models
from django.contrib.auth.models import User
from mediafiles.models import MediaFile
import uuid
from datetime import datetime


def generate_uuid():
    return str(uuid.uuid4())[:20]


# ============== 分类表（一级分类）==============
class Category(models.Model):
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    name = models.CharField(max_length=100)
    icon = models.ForeignKey(MediaFile, on_delete=models.SET_NULL, null=True, blank=True, related_name='category_icons')
    banner = models.ForeignKey(MediaFile, on_delete=models.SET_NULL, null=True, blank=True, related_name='category_banners')
    sort_order = models.IntegerField(default=0)
    is_enabled = models.BooleanField(default=True)

    class Meta:
        db_table = 'categories'
        ordering = ['sort_order']

    def __str__(self):
        return self.name


# ============== 分类表（二级分类）==============
class Subcategory(models.Model):
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    name = models.CharField(max_length=100)
    icon = models.ForeignKey(MediaFile, on_delete=models.SET_NULL, null=True, blank=True, related_name='subcategory_icons')
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='subcategories')
    sort_order = models.IntegerField(default=0)
    is_enabled = models.BooleanField(default=True)

    class Meta:
        db_table = 'subcategories'
        ordering = ['sort_order']

    def __str__(self):
        return f"{self.category.name} - {self.name}"


# ============== 商品表（关联二级分类）==============
class Product(models.Model):
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    original_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    image = models.ForeignKey(MediaFile, on_delete=models.SET_NULL, null=True, blank=True, related_name='product_images')
    subcategory = models.ForeignKey(Subcategory, on_delete=models.SET_NULL, null=True, related_name='products')
    rating = models.DecimalField(max_digits=2, decimal_places=1, default=0)
    review_count = models.IntegerField(default=0)
    sales_count = models.IntegerField(default=0)
    is_in_stock = models.BooleanField(default=True)
    tag = models.CharField(max_length=50, blank=True)

    class Meta:
        db_table = 'products'

    def __str__(self):
        return self.name


# ============== 商品详情表（保留）==============
class ProductDetail(models.Model):
    product = models.OneToOneField(Product, on_delete=models.CASCADE, primary_key=True, related_name='detail')
    shop_name = models.CharField(max_length=255, blank=True)
    shop_logo = models.ForeignKey(MediaFile, on_delete=models.SET_NULL, null=True, blank=True, related_name='shop_logos')
    images = models.ManyToManyField(MediaFile, related_name='product_detail_images', blank=True)
    detail_images = models.ManyToManyField(MediaFile, related_name='product_detail_extras', blank=True)

    class Meta:
        db_table = 'product_details'


# ============== 规格表（保留）==============
class SpecGroup(models.Model):
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='spec_groups')
    name = models.CharField(max_length=100)
    sort_order = models.IntegerField(default=0)

    class Meta:
        db_table = 'spec_groups'


class SpecValue(models.Model):
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    group = models.ForeignKey(SpecGroup, on_delete=models.CASCADE, related_name='values')
    value = models.CharField(max_length=100)
    image = models.ForeignKey(MediaFile, on_delete=models.SET_NULL, null=True, blank=True)
    sort_order = models.IntegerField(default=0)

    class Meta:
        db_table = 'spec_values'


class SKU(models.Model):
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='skus')
    price = models.DecimalField(max_digits=10, decimal_places=2)
    original_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    stock = models.IntegerField(default=0)
    image = models.ForeignKey(MediaFile, on_delete=models.SET_NULL, null=True, blank=True)
    spec_values = models.ManyToManyField(SpecValue, through='SKUSpec', related_name='skus')

    class Meta:
        db_table = 'skus'


class SKUSpec(models.Model):
    sku = models.ForeignKey(SKU, on_delete=models.CASCADE)
    spec_value = models.ForeignKey(SpecValue, on_delete=models.CASCADE)

    class Meta:
        db_table = 'sku_specs'
        unique_together = ('sku', 'spec_value')


# ============== 首页Banner表==============
class HomeBanner(models.Model):
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    image = models.ForeignKey(MediaFile, on_delete=models.SET_NULL, null=True, blank=True, related_name='home_banners')
    tag = models.CharField(max_length=100, blank=True)
    title = models.TextField(blank=True)
    action_title = models.CharField(max_length=100, blank=True)
    link = models.CharField(max_length=255, blank=True)
    landing_badge = models.CharField(max_length=100, blank=True)
    landing_subtitle = models.CharField(max_length=150, blank=True)
    landing_description = models.TextField(blank=True)
    gradient_type = models.IntegerField(default=0)
    sort_order = models.IntegerField(default=0)
    is_enabled = models.BooleanField(default=True)
    products = models.ManyToManyField(Product, related_name='banner_landings', blank=True)

    class Meta:
        db_table = 'home_banners'
        ordering = ['sort_order']

    def __str__(self):
        return self.tag or f"Banner {self.id}"


# ============== 首页限时秒杀表==============
class HomeFlashSale(models.Model):
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    title = models.CharField(max_length=100)
    subtitle = models.CharField(max_length=100, blank=True)
    start_time = models.DateTimeField(null=True, blank=True)
    end_time = models.DateTimeField(null=True, blank=True)
    sort_order = models.IntegerField(default=0)
    is_enabled = models.BooleanField(default=True)
    products = models.ManyToManyField(Product, related_name='flash_sale_sections', blank=True)

    class Meta:
        db_table = 'home_flash_sales'
        ordering = ['sort_order']

    def __str__(self):
        return self.title


# ============== 首页热销榜单表==============
class HomeHotRank(models.Model):
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    title = models.CharField(max_length=100)
    sort_order = models.IntegerField(default=0)
    is_enabled = models.BooleanField(default=True)
    products = models.ManyToManyField(Product, related_name='hot_rank_sections', blank=True)

    class Meta:
        db_table = 'home_hot_ranks'
        ordering = ['sort_order']

    def __str__(self):
        return self.title


# ============== 首页为你推荐表==============
class HomeRecommend(models.Model):
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    title = models.CharField(max_length=100)
    sort_order = models.IntegerField(default=0)
    is_enabled = models.BooleanField(default=True)
    products = models.ManyToManyField(Product, related_name='recommend_sections', blank=True)

    class Meta:
        db_table = 'home_recommends'
        ordering = ['sort_order']

    def __str__(self):
        return self.title


# ============== 首页新品上市表==============
class HomeNewArrival(models.Model):
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    title = models.CharField(max_length=100)
    sort_order = models.IntegerField(default=0)
    is_enabled = models.BooleanField(default=True)
    products = models.ManyToManyField(Product, related_name='new_arrival_sections', blank=True)

    class Meta:
        db_table = 'home_new_arrivals'
        ordering = ['sort_order']

    def __str__(self):
        return self.title


# ============== 首页优惠活动表==============
class HomePromotion(models.Model):
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    title = models.CharField(max_length=100)
    subtitle = models.CharField(max_length=100, blank=True)
    image = models.ForeignKey(MediaFile, on_delete=models.SET_NULL, null=True, blank=True, related_name='home_promotions')
    link = models.CharField(max_length=255, blank=True)
    sort_order = models.IntegerField(default=0)
    is_enabled = models.BooleanField(default=True)

    class Meta:
        db_table = 'home_promotions'
        ordering = ['sort_order']

    def __str__(self):
        return self.title


# ============== 购物车表（保留）==============
class CartItem(models.Model):
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='cart_items')
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    sku = models.ForeignKey('SKU', on_delete=models.SET_NULL, null=True, blank=True, related_name='cart_items')
    quantity = models.IntegerField(default=1)
    is_selected = models.BooleanField(default=True)

    class Meta:
        db_table = 'cart_items'


# ============== 订单表（保留）==============
class Order(models.Model):
    STATUS_CHOICES = [
        ('pending', '待支付'),
        ('paid', '待发货'),
        ('shipped', '待收货'),
        ('completed', '已完成'),
        ('cancelled', '已取消'),
    ]
    id = models.CharField(max_length=50, primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='orders')
    store = models.CharField(max_length=255, blank=True)
    status = models.CharField(max_length=50, choices=STATUS_CHOICES, default='pending')
    total_amount = models.DecimalField(max_digits=10, decimal_places=2)
    payment = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True, help_text='实付金额')
    freight = models.DecimalField(max_digits=10, decimal_places=2, default=0, help_text='运费')
    discount = models.DecimalField(max_digits=10, decimal_places=2, default=0, help_text='优惠金额')
    # 地址文本副本
    address_name = models.CharField(max_length=100, blank=True)
    address_phone = models.CharField(max_length=50, blank=True)
    address_province = models.CharField(max_length=100, blank=True)
    address_city = models.CharField(max_length=100, blank=True)
    address_district = models.CharField(max_length=100, blank=True)
    address_detail = models.TextField(blank=True)
    pay_time = models.DateTimeField(null=True, blank=True, help_text='支付时间')
    created_at = models.DateTimeField(auto_now_add=True)
    shipped_at = models.DateTimeField(null=True, blank=True, help_text='发货时间')
    carrier = models.CharField(max_length=100, blank=True, help_text='物流承运商')
    tracking_number = models.CharField(max_length=100, blank=True, help_text='物流单号')
    after_sale_status = models.CharField(
        max_length=20,
        choices=[
            ('none', '未申请'),
            ('requested', '已申请'),
            ('processing', '处理中'),
            ('refunded', '已退款'),
            ('rejected', '已拒绝'),
        ],
        default='none',
    )
    after_sale_reason = models.TextField(blank=True)
    after_sale_applied_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'orders'

    def __str__(self):
        return self.id


class PaymentTransaction(models.Model):
    STATUS_CHOICES = [
        ('created', '已创建'),
        ('requires_action', '待用户操作'),
        ('processing', '处理中'),
        ('succeeded', '支付成功'),
        ('failed', '支付失败'),
        ('cancelled', '已取消'),
        ('expired', '已过期'),
    ]

    PROVIDER_CHOICES = [
        ('wxpay', '微信支付'),
        ('alipay', '支付宝'),
        ('balance', '余额支付'),
        ('sandbox', '沙箱支付'),
    ]

    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='payment_transactions')
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='payment_transactions')
    provider = models.CharField(max_length=30, choices=PROVIDER_CHOICES)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=10, default='CNY')
    status = models.CharField(max_length=30, choices=STATUS_CHOICES, default='created')
    payment_url = models.URLField(blank=True)
    client_secret = models.CharField(max_length=255, blank=True)
    provider_transaction_id = models.CharField(max_length=255, blank=True)
    provider_payload = models.JSONField(default=dict, blank=True)
    failure_reason = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    confirmed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'payment_transactions'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['order', 'status']),
            models.Index(fields=['provider_transaction_id']),
        ]

    def __str__(self):
        return f'{self.provider}:{self.id}'


class OrderProduct(models.Model):
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='products')
    product_id = models.CharField(max_length=50, blank=True, default='')
    name = models.CharField(max_length=255)
    spec = models.CharField(max_length=255, blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    quantity = models.IntegerField(default=1)
    image = models.ForeignKey(MediaFile, on_delete=models.SET_NULL, null=True, blank=True)

    class Meta:
        db_table = 'order_products'


# ============== 地址表（保留）==============
class Address(models.Model):
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='addresses')
    name = models.CharField(max_length=100)
    phone = models.CharField(max_length=50)
    province = models.CharField(max_length=100)
    city = models.CharField(max_length=100)
    district = models.CharField(max_length=100)
    detail = models.TextField()
    is_default = models.BooleanField(default=False)

    class Meta:
        db_table = 'addresses'

    def __str__(self):
        return f"{self.name} - {self.province}{self.city}{self.district}"


# ============== 评价表（保留）==============
class Review(models.Model):
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reviews')
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='reviews')
    user_name = models.CharField(max_length=100)
    user_avatar = models.ForeignKey(MediaFile, on_delete=models.SET_NULL, null=True, blank=True, related_name='review_avatars')
    rating = models.IntegerField()
    content = models.TextField()
    spec = models.CharField(max_length=255, blank=True)
    images = models.ManyToManyField(MediaFile, related_name='review_images', blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'reviews'


# ============== 收藏表（保留）==============
class Favorite(models.Model):
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='favorites')
    product_id = models.CharField(max_length=50, blank=True, default='')
    name = models.CharField(max_length=255)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    original_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    image = models.ForeignKey(MediaFile, on_delete=models.SET_NULL, null=True, blank=True, related_name='favorite_images')
    sales = models.CharField(max_length=50, blank=True)

    class Meta:
        db_table = 'favorites'




class BrowseHistory(models.Model):
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='browse_histories')
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='browse_histories')
    viewed_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'browse_histories'
        unique_together = ('user', 'product')
        ordering = ['-viewed_at']


# ============== 用户资料表 ==============
class UserProfile(models.Model):
    USER_TYPE_CHOICES = [
        ('admin', '管理员'),
        ('user', '普通用户'),
    ]
    GENDER_CHOICES = [
        ('male', '男'),
        ('female', '女'),
        ('secret', '保密'),
    ]
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    user_type = models.CharField(max_length=20, choices=USER_TYPE_CHOICES, default='user')
    phone = models.CharField(max_length=50, blank=True)
    gender = models.CharField(max_length=20, choices=GENDER_CHOICES, default='secret')
    birthday = models.DateField(null=True, blank=True)
    avatar = models.ForeignKey(MediaFile, on_delete=models.SET_NULL, null=True, blank=True, related_name='user_avatars')
    points = models.IntegerField(default=0)
    follow_count = models.IntegerField(default=0)
    fans_count = models.IntegerField(default=0)

    class Meta:
        db_table = 'user_profiles'


# ============== 管理员资料表 ==============
class AdminProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='admin_profile')
    permissions = models.JSONField(default=dict)  # 存储权限配置

    class Meta:
        db_table = 'admin_profiles'


# ============== 优惠券表（保留）==============
class UserCoupon(models.Model):
    STATUS_CHOICES = [
        ('available', '可用'),
        ('used', '已使用'),
        ('expired', '已过期'),
    ]
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='coupons')
    name = models.CharField(max_length=100)
    value = models.IntegerField()
    threshold = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    time = models.CharField(max_length=100)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='available')

    class Meta:
        db_table = 'user_coupons'


# ============== 通知表（保留）==============
class Notification(models.Model):
    TYPE_CHOICES = [
        ('logistics', '物流通知'),
        ('order', '订单提醒'),
        ('promo', '优惠活动'),
        ('sys', '系统通知'),
    ]
    id = models.CharField(max_length=50, primary_key=True, default=generate_uuid)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='notifications')
    type = models.CharField(max_length=50, choices=TYPE_CHOICES)
    name = models.CharField(max_length=100)
    time = models.CharField(max_length=100)
    content = models.TextField()
    action = models.CharField(max_length=100, blank=True)
    is_read = models.BooleanField(default=False)

    class Meta:
        db_table = 'notifications'


# ============== 店铺信息（单例）==============
class ShopInfo(models.Model):
    name = models.CharField(max_length=100, default='潮流优品官方旗舰店')
    description = models.TextField(blank=True, default='专注时尚潮流，只卖好货')
    score = models.DecimalField(max_digits=3, decimal_places=1, default=4.9)
    product_count = models.IntegerField(default=0)
    sales = models.CharField(max_length=20, blank=True, default='12.8万')
    fans_count = models.CharField(max_length=20, blank=True, default='56.2万')

    class Meta:
        db_table = 'shop_info'

    def __str__(self):
        return self.name


# ============== VIP会员 ==============
VIP_LEVELS = [
    ('none',    '普通会员'),
    ('bronze',  '铜牌会员'),
    ('silver',  '银牌会员'),
    ('gold',    '黄金会员'),
    ('diamond', '钻石会员'),
]

VIP_LEVEL_ORDER = ['none', 'bronze', 'silver', 'gold', 'diamond']

VIP_LEVEL_NAMES = {
    'none':    '普通会员',
    'bronze':  '铜牌会员',
    'silver':  '银牌会员',
    'gold':    '黄金会员',
    'diamond': '钻石会员',
}


class VIPMembership(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='vip')
    level = models.CharField(max_length=20, choices=VIP_LEVELS, default='none')
    expire_date = models.DateField(null=True, blank=True)
    points = models.IntegerField(default=0)
    growth_value = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'vip_memberships'
