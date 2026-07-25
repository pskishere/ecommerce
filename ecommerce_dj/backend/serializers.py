import re
from rest_framework import serializers
from .models import (
    Category, Subcategory, Product, ProductDetail,
    HomeBanner, HomeFlashSale, HomeHotRank, HomeRecommend, HomeNewArrival, HomePromotion,
    CartItem, Order, OrderProduct, Address, Review, Favorite, BrowseHistory, UserCoupon, Notification,
    SpecGroup, SpecValue, SKU, ShopInfo, VIPMembership, VIP_LEVEL_NAMES, VIP_LEVEL_ORDER
)


def get_image_url(image_field, context=None):
    from django.conf import settings
    if image_field and image_field.file:
        if getattr(settings, 'GITHUB_RAW_URL', ''):
            return f"{settings.GITHUB_RAW_URL}/{image_field.file.name}"
        if context and 'request' in context:
            return context['request'].build_absolute_uri(image_field.file.url)
        if hasattr(settings, 'SITE_URL'):
            return settings.SITE_URL.rstrip('/') + image_field.file.url
        return image_field.file.url
    return None


def _subcategory_data(subcategory):
    if subcategory:
        return {
            'id': subcategory.id,
            'name': subcategory.name,
            'category_id': subcategory.category_id if subcategory.category else None,
        }
    return None


def sku_spec_text(sku):
    if not sku:
        return ''
    values = sku.spec_values.select_related('group').order_by('group__sort_order', 'sort_order', 'id')
    return ' / '.join(v.value for v in values)


# ============== 商品相关序列化器 ==============
class ProductListSerializer(serializers.ModelSerializer):
    subcategory = serializers.SerializerMethodField()
    image = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = ['id', 'name', 'description', 'price', 'original_price', 'image',
                  'subcategory', 'rating', 'review_count', 'sales_count', 'is_in_stock', 'tag']

    def get_image(self, obj):
        return get_image_url(obj.image, self.context)

    def get_subcategory(self, obj):
        return _subcategory_data(obj.subcategory)


class ProductDetailSerializer(serializers.ModelSerializer):
    subcategory = serializers.SerializerMethodField()
    image = serializers.SerializerMethodField()
    detail = serializers.SerializerMethodField()
    spec_groups = serializers.SerializerMethodField()
    skus = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = ['id', 'name', 'description', 'price', 'original_price', 'image',
                  'subcategory', 'rating', 'review_count', 'sales_count', 'is_in_stock', 'tag', 'detail',
                  'spec_groups', 'skus']

    def get_image(self, obj):
        return get_image_url(obj.image, self.context)

    def get_subcategory(self, obj):
        return _subcategory_data(obj.subcategory)

    def get_detail(self, obj):
        try:
            d = obj.detail
            if not d:
                return None
            return {
                'shop_name': d.shop_name,
                'shop_logo': get_image_url(d.shop_logo, self.context),
                'images': [get_image_url(img, self.context) for img in d.images.all()] if d.images else [],
                'detail_images': [get_image_url(img, self.context) for img in d.detail_images.all()] if d.detail_images else [],
            }
        except (ProductDetail.DoesNotExist, Product.DoesNotExist, AttributeError):
            return None

    def get_spec_groups(self, obj):
        try:
            groups = obj.spec_groups.all()
            return SpecGroupSerializer(groups, many=True, context=self.context).data
        except AttributeError:
            return []

    def get_skus(self, obj):
        try:
            skus = obj.skus.all()
            return SKUSerializer(skus, many=True, context=self.context).data
        except AttributeError:
            return []


# ============== 规格序列化器 ==============
class SpecValueSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = SpecValue
        fields = ['id', 'value', 'image', 'sort_order']

    def get_image(self, obj):
        return get_image_url(obj.image, self.context)


class SpecGroupSerializer(serializers.ModelSerializer):
    values = SpecValueSerializer(many=True, read_only=True)

    class Meta:
        model = SpecGroup
        fields = ['id', 'name', 'sort_order', 'values']


class SKUSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()
    spec_value_ids = serializers.SerializerMethodField()

    class Meta:
        model = SKU
        fields = ['id', 'price', 'original_price', 'stock', 'image', 'spec_value_ids']

    def get_image(self, obj):
        return get_image_url(obj.image, self.context)

    def get_spec_value_ids(self, obj):
        return list(obj.spec_values.values_list('id', flat=True))


# ============== 分类序列化器 ==============
class SubcategorySerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = Subcategory
        fields = ['id', 'name', 'image', 'category_id', 'sort_order', 'is_enabled']

    def get_image(self, obj):
        return get_image_url(obj.icon, self.context)


class SubcategoryWithProductsSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()
    products = serializers.SerializerMethodField()

    class Meta:
        model = Subcategory
        fields = ['id', 'name', 'image', 'sort_order', 'is_enabled', 'products']

    def get_image(self, obj):
        return get_image_url(obj.icon, self.context)

    def get_products(self, obj):
        products = obj.products.all()[:20]  # 限制返回产品数量
        return ProductListSerializer(products, many=True, context=self.context).data


class CategorySerializer(serializers.ModelSerializer):
    icon = serializers.SerializerMethodField()
    banner = serializers.SerializerMethodField()

    class Meta:
        model = Category
        fields = ['id', 'name', 'icon', 'banner', 'sort_order', 'is_enabled']

    def get_icon(self, obj):
        return get_image_url(obj.icon, self.context)

    def get_banner(self, obj):
        return get_image_url(obj.banner, self.context)


class CategoryWithSubcategoriesSerializer(serializers.ModelSerializer):
    icon = serializers.SerializerMethodField()
    banner = serializers.SerializerMethodField()
    subcategories = serializers.SerializerMethodField()

    class Meta:
        model = Category
        fields = ['id', 'name', 'icon', 'banner', 'sort_order', 'is_enabled', 'subcategories']

    def get_icon(self, obj):
        return get_image_url(obj.icon, self.context)

    def get_banner(self, obj):
        return get_image_url(obj.banner, self.context)

    def get_subcategories(self, obj):
        subcategories = obj.subcategories.filter(is_enabled=True)
        return SubcategoryWithProductsSerializer(subcategories, many=True, context=self.context).data


# ============== 首页通用Mixin ==============
class HomeProductsMixin:
    def get_products(self, obj):
        return ProductListSerializer(obj.products.all(), many=True, context=self.context).data


# ============== 首页Banner序列化器 ==============
class HomeBannerSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = HomeBanner
        fields = ['id', 'image', 'tag', 'title', 'action_title', 'gradient_type', 'sort_order', 'is_enabled']

    def get_image(self, obj):
        return get_image_url(obj.image, self.context)


# ============== 首页限时秒杀序列化器 ==============
class HomeFlashSaleSerializer(HomeProductsMixin, serializers.ModelSerializer):
    products = serializers.SerializerMethodField()

    class Meta:
        model = HomeFlashSale
        fields = ['id', 'title', 'subtitle', 'start_time', 'end_time', 'sort_order', 'is_enabled', 'products']


# ============== 首页热销榜单序列化器 ==============
class HomeHotRankSerializer(HomeProductsMixin, serializers.ModelSerializer):
    products = serializers.SerializerMethodField()

    class Meta:
        model = HomeHotRank
        fields = ['id', 'title', 'sort_order', 'is_enabled', 'products']


# ============== 首页为你推荐序列化器 ==============
class HomeRecommendSerializer(HomeProductsMixin, serializers.ModelSerializer):
    products = serializers.SerializerMethodField()

    class Meta:
        model = HomeRecommend
        fields = ['id', 'title', 'sort_order', 'is_enabled', 'products']


# ============== 首页新品上市序列化器 ==============
class HomeNewArrivalSerializer(HomeProductsMixin, serializers.ModelSerializer):
    products = serializers.SerializerMethodField()

    class Meta:
        model = HomeNewArrival
        fields = ['id', 'title', 'sort_order', 'is_enabled', 'products']


# ============== 首页优惠活动序列化器 ==============
class HomePromotionSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = HomePromotion
        fields = ['id', 'title', 'subtitle', 'image', 'link', 'sort_order', 'is_enabled']

    def get_image(self, obj):
        return get_image_url(obj.image, self.context)


# ============== 评价序列化器 ==============
class ReviewSerializer(serializers.ModelSerializer):
    images = serializers.SerializerMethodField()

    class Meta:
        model = Review
        fields = ['id', 'product_id', 'user_id', 'user_name', 'user_avatar', 'rating', 'content', 'spec', 'images', 'created_at']
        read_only_fields = ['user_name', 'user_avatar']

    def get_images(self, obj):
        return [get_image_url(img, self.context) for img in obj.images.all()] if obj.images else []


# ============== 购物车序列化器 ==============
class CartItemSerializer(serializers.ModelSerializer):
    product = ProductListSerializer(read_only=True)
    sku_id = serializers.SerializerMethodField()
    spec = serializers.SerializerMethodField()
    unit_price = serializers.SerializerMethodField()
    original_price = serializers.SerializerMethodField()
    image = serializers.SerializerMethodField()

    class Meta:
        model = CartItem
        fields = ['id', 'product', 'sku_id', 'spec', 'unit_price', 'original_price', 'image', 'quantity', 'is_selected']

    def get_sku_id(self, obj):
        return obj.sku_id or ''

    def get_spec(self, obj):
        return sku_spec_text(obj.sku)

    def get_unit_price(self, obj):
        return obj.sku.price if obj.sku else obj.product.price

    def get_original_price(self, obj):
        if obj.sku and obj.sku.original_price:
            return obj.sku.original_price
        return obj.product.original_price or obj.product.price

    def get_image(self, obj):
        image = obj.sku.image if obj.sku and obj.sku.image else obj.product.image
        return get_image_url(image, self.context)


# ============== 地址序列化器 ==============
class AddressSerializer(serializers.ModelSerializer):
    class Meta:
        model = Address
        fields = ['id', 'name', 'phone', 'province', 'city', 'district', 'detail', 'is_default']


# ============== 订单序列化器 ==============
class OrderProductSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = OrderProduct
        fields = ['id', 'product_id', 'name', 'spec', 'price', 'quantity', 'image']

    def get_image(self, obj):
        return get_image_url(obj.image, self.context)


class OrderSerializer(serializers.ModelSerializer):
    products = OrderProductSerializer(many=True, read_only=True)
    address = serializers.SerializerMethodField()
    statusText = serializers.SerializerMethodField()
    logistics = serializers.SerializerMethodField()
    after_sale_status_text = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = [
            'id', 'store', 'status', 'statusText', 'total_amount', 'payment', 'freight', 'discount',
            'address', 'pay_time', 'created_at', 'shipped_at', 'carrier', 'tracking_number',
            'logistics', 'after_sale_status', 'after_sale_status_text', 'after_sale_reason',
            'after_sale_applied_at', 'products',
        ]

    def get_address(self, obj):
        return {
            'name': obj.address_name,
            'phone': obj.address_phone,
            'province': obj.address_province,
            'city': obj.address_city,
            'district': obj.address_district,
            'detail': obj.address_detail,
        }

    def get_statusText(self, obj):
        return dict(Order.STATUS_CHOICES).get(obj.status, obj.status)

    def get_after_sale_status_text(self, obj):
        return obj.get_after_sale_status_display()

    def get_logistics(self, obj):
        def fmt(value):
            return value.strftime('%Y-%m-%d %H:%M') if value else ''

        items = []
        if obj.status == 'completed':
            items.append({
                'text': '订单已签收，交易完成',
                'time': fmt(obj.shipped_at or obj.pay_time or obj.created_at),
                'active': True,
            })
        if obj.status in ('shipped', 'completed'):
            carrier = obj.carrier or '官方配送'
            tracking = f'，运单号 {obj.tracking_number}' if obj.tracking_number else ''
            items.append({
                'text': f'{carrier} 已揽收包裹{tracking}',
                'time': fmt(obj.shipped_at or obj.pay_time),
                'active': obj.status == 'shipped',
            })
        if obj.status in ('paid', 'shipped', 'completed'):
            items.append({
                'text': '订单已支付，商家正在准备商品',
                'time': fmt(obj.pay_time),
                'active': obj.status == 'paid',
            })
        items.append({
            'text': '订单已提交',
            'time': fmt(obj.created_at),
            'active': obj.status == 'pending',
        })
        return [item for item in items if item['time']]


# ============== 收藏序列化器 ==============
class FavoriteSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = Favorite
        fields = ['id', 'product_id', 'name', 'price', 'original_price', 'image', 'sales']
        read_only_fields = ['id', 'product_id', 'name', 'price', 'original_price', 'image', 'sales']

    def get_image(self, obj):
        return get_image_url(obj.image, self.context)


class BrowseHistorySerializer(serializers.ModelSerializer):
    product = ProductListSerializer(read_only=True)
    time = serializers.SerializerMethodField()

    class Meta:
        model = BrowseHistory
        fields = ['id', 'product', 'viewed_at', 'time']

    def get_time(self, obj):
        return obj.viewed_at.strftime('%Y-%m-%d %H:%M') if obj.viewed_at else ''


# ============== 优惠券序列化器 ==============
class CouponSerializer(serializers.ModelSerializer):
    threshold_amount = serializers.SerializerMethodField()

    class Meta:
        model = UserCoupon
        fields = ['id', 'name', 'value', 'threshold', 'threshold_amount', 'description', 'time', 'status']

    def get_threshold_amount(self, obj):
        match = re.search(r'(\d+)', obj.threshold)
        return int(match.group(1)) if match else 0


# ============== 通知序列化器 ==============
class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'type', 'name', 'time', 'content', 'action', 'is_read']


# ============== 店铺信息序列化器 ==============
class ShopInfoSerializer(serializers.ModelSerializer):
    class Meta:
        model = ShopInfo
        fields = ['name', 'description', 'score', 'product_count', 'sales', 'fans_count']


# ============== VIP序列化器 ==============
class VIPSerializer(serializers.ModelSerializer):
    level_name = serializers.SerializerMethodField()
    next_level = serializers.SerializerMethodField()
    next_level_name = serializers.SerializerMethodField()

    class Meta:
        model = VIPMembership
        fields = ['level', 'level_name', 'expire_date', 'points', 'growth_value', 'next_level', 'next_level_name']

    def get_level_name(self, obj):
        return VIP_LEVEL_NAMES.get(obj.level, '普通会员')

    def get_next_level(self, obj):
        idx = VIP_LEVEL_ORDER.index(obj.level) if obj.level in VIP_LEVEL_ORDER else 0
        if idx < len(VIP_LEVEL_ORDER) - 1:
            return VIP_LEVEL_ORDER[idx + 1]
        return None

    def get_next_level_name(self, obj):
        idx = VIP_LEVEL_ORDER.index(obj.level) if obj.level in VIP_LEVEL_ORDER else 0
        if idx < len(VIP_LEVEL_ORDER) - 1:
            return VIP_LEVEL_NAMES.get(VIP_LEVEL_ORDER[idx + 1])
        return None


# ============== 登录序列化器 ==============
class LoginSerializer(serializers.Serializer):
    user_id = serializers.CharField()
