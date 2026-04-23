from rest_framework import serializers
from .models import (
    Category, Subcategory, Product, ProductDetail,
    HomeBanner, HomeFlashSale, HomeHotRank, HomeRecommend, HomeNewArrival, HomePromotion,
    CartItem, Order, OrderProduct, Address, Review, Favorite, History, UserCoupon, Notification,
    SpecGroup, SpecValue, SKU
)


def get_image_url(image_field, context):
    if image_field and image_field.file:
        if context and 'request' in context:
            return context['request'].build_absolute_uri(image_field.file.url)
        return image_field.file.url
    return None


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
        if obj.subcategory:
            return {
                'id': obj.subcategory.id,
                'name': obj.subcategory.name,
                'category_id': obj.subcategory.category_id if obj.subcategory.category else None
            }
        return None


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
        if obj.subcategory:
            return {
                'id': obj.subcategory.id,
                'name': obj.subcategory.name,
                'category_id': obj.subcategory.category_id if obj.subcategory.category else None
            }
        return None

    def get_detail(self, obj):
        try:
            d = obj.detail
            return {
                'shop_name': d.shop_name,
                'shop_logo': get_image_url(d.shop_logo, self.context),
                'images': [get_image_url(img, self.context) for img in d.images.all()] if d.images else [],
                'detail_images': [get_image_url(img, self.context) for img in d.detail_images.all()] if d.detail_images else [],
            }
        except ProductDetail.DoesNotExist:
            return None

    def get_spec_groups(self, obj):
        groups = obj.spec_groups.all()
        return SpecGroupSerializer(groups, many=True, context=self.context).data

    def get_skus(self, obj):
        skus = obj.skus.all()
        return SKUSerializer(skus, many=True, context=self.context).data


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


# ============== 首页Banner序列化器 ==============
class HomeBannerSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = HomeBanner
        fields = ['id', 'image', 'tag', 'title', 'action_title', 'gradient_type', 'sort_order', 'is_enabled']

    def get_image(self, obj):
        return get_image_url(obj.image, self.context)


# ============== 首页限时秒杀序列化器 ==============
class HomeFlashSaleSerializer(serializers.ModelSerializer):
    products = serializers.SerializerMethodField()

    class Meta:
        model = HomeFlashSale
        fields = ['id', 'title', 'subtitle', 'start_time', 'end_time', 'sort_order', 'is_enabled', 'products']

    def get_products(self, obj):
        products = obj.products.all()
        return ProductListSerializer(products, many=True, context=self.context).data


# ============== 首页热销榜单序列化器 ==============
class HomeHotRankSerializer(serializers.ModelSerializer):
    products = serializers.SerializerMethodField()

    class Meta:
        model = HomeHotRank
        fields = ['id', 'title', 'sort_order', 'is_enabled', 'products']

    def get_products(self, obj):
        products = obj.products.all()
        return ProductListSerializer(products, many=True, context=self.context).data


# ============== 首页为你推荐序列化器 ==============
class HomeRecommendSerializer(serializers.ModelSerializer):
    products = serializers.SerializerMethodField()

    class Meta:
        model = HomeRecommend
        fields = ['id', 'title', 'sort_order', 'is_enabled', 'products']

    def get_products(self, obj):
        products = obj.products.all()
        return ProductListSerializer(products, many=True, context=self.context).data


# ============== 首页新品上市序列化器 ==============
class HomeNewArrivalSerializer(serializers.ModelSerializer):
    products = serializers.SerializerMethodField()

    class Meta:
        model = HomeNewArrival
        fields = ['id', 'title', 'sort_order', 'is_enabled', 'products']

    def get_products(self, obj):
        products = obj.products.all()
        return ProductListSerializer(products, many=True, context=self.context).data


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

    class Meta:
        model = CartItem
        fields = ['id', 'product', 'quantity', 'is_selected']


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
        fields = ['id', 'name', 'spec', 'price', 'quantity', 'image']

    def get_image(self, obj):
        return get_image_url(obj.image, self.context)


class OrderSerializer(serializers.ModelSerializer):
    id = serializers.CharField(source='order_number')
    products = OrderProductSerializer(many=True, read_only=True)
    address = AddressSerializer(read_only=True)
    statusText = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = ['id', 'order_number', 'store', 'status', 'statusText', 'total_amount', 'payment', 'freight', 'discount', 'address', 'pay_time', 'created_at', 'products']

    def get_statusText(self, obj):
        return dict(Order.STATUS_CHOICES).get(obj.status, obj.status)


# ============== 收藏序列化器 ==============
class FavoriteSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = Favorite
        fields = ['id', 'name', 'price', 'original_price', 'image', 'sales']

    def get_image(self, obj):
        return get_image_url(obj.image, self.context)


# ============== 历史记录序列化器 ==============
class HistorySerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = History
        fields = ['id', 'name', 'price', 'image', 'time']

    def get_image(self, obj):
        return get_image_url(obj.image, self.context)


# ============== 优惠券序列化器 ==============
class CouponSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserCoupon
        fields = ['id', 'name', 'value', 'threshold', 'description', 'time']


# ============== 通知序列化器 ==============
class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'type', 'name', 'time', 'content', 'action', 'is_read']


# ============== 登录序列化器 ==============
class LoginSerializer(serializers.Serializer):
    user_id = serializers.CharField()
