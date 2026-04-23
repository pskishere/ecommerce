from django.contrib import admin
from .models import (
    Category, Subcategory, Product, ProductDetail,
    HomeBanner, HomeFlashSale, HomeHotRank, HomeRecommend, HomeNewArrival, HomePromotion,
    CartItem, Order, OrderProduct, Address, Review, Favorite, UserCoupon, Notification
)


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['id', 'name', 'sort_order', 'is_enabled']
    list_filter = ['is_enabled']
    search_fields = ['name']
    ordering = ['sort_order']


@admin.register(Subcategory)
class SubcategoryAdmin(admin.ModelAdmin):
    list_display = ['id', 'name', 'category', 'sort_order', 'is_enabled']
    list_filter = ['is_enabled', 'category']
    search_fields = ['name']
    ordering = ['sort_order']


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ['id', 'name', 'subcategory', 'price', 'is_in_stock', 'sales_count']
    list_filter = ['is_in_stock', 'subcategory__category']
    search_fields = ['name']
    ordering = ['-sales_count']


@admin.register(ProductDetail)
class ProductDetailAdmin(admin.ModelAdmin):
    list_display = ['product', 'shop_name']


@admin.register(HomeBanner)
class HomeBannerAdmin(admin.ModelAdmin):
    list_display = ['id', 'tag', 'title', 'sort_order', 'is_enabled']
    list_filter = ['is_enabled']
    ordering = ['sort_order']


@admin.register(HomeFlashSale)
class HomeFlashSaleAdmin(admin.ModelAdmin):
    list_display = ['id', 'title', 'start_time', 'end_time', 'sort_order', 'is_enabled']
    list_filter = ['is_enabled']
    ordering = ['sort_order']
    filter_horizontal = ['products']


@admin.register(HomeHotRank)
class HomeHotRankAdmin(admin.ModelAdmin):
    list_display = ['id', 'title', 'sort_order', 'is_enabled']
    list_filter = ['is_enabled']
    ordering = ['sort_order']
    filter_horizontal = ['products']


@admin.register(HomeRecommend)
class HomeRecommendAdmin(admin.ModelAdmin):
    list_display = ['id', 'title', 'sort_order', 'is_enabled']
    list_filter = ['is_enabled']
    ordering = ['sort_order']
    filter_horizontal = ['products']


@admin.register(HomeNewArrival)
class HomeNewArrivalAdmin(admin.ModelAdmin):
    list_display = ['id', 'title', 'sort_order', 'is_enabled']
    list_filter = ['is_enabled']
    ordering = ['sort_order']
    filter_horizontal = ['products']


@admin.register(HomePromotion)
class HomePromotionAdmin(admin.ModelAdmin):
    list_display = ['id', 'title', 'subtitle', 'sort_order', 'is_enabled']
    list_filter = ['is_enabled']
    ordering = ['sort_order']


@admin.register(CartItem)
class CartItemAdmin(admin.ModelAdmin):
    list_display = ['id', 'user_id', 'product', 'quantity', 'is_selected']
    list_filter = ['is_selected']


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ['id', 'user_id', 'store', 'status', 'total_amount', 'created_at']
    list_filter = ['status']
    search_fields = ['id']


@admin.register(OrderProduct)
class OrderProductAdmin(admin.ModelAdmin):
    list_display = ['id', 'order', 'name', 'price', 'quantity']


@admin.register(Address)
class AddressAdmin(admin.ModelAdmin):
    list_display = ['id', 'user_id', 'name', 'phone', 'province', 'city', 'district', 'is_default']
    list_filter = ['is_default', 'province', 'city']


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ['id', 'user_id', 'product', 'rating', 'created_at']
    list_filter = ['rating']


@admin.register(Favorite)
class FavoriteAdmin(admin.ModelAdmin):
    list_display = ['id', 'user_id', 'name', 'price']




@admin.register(UserCoupon)
class UserCouponAdmin(admin.ModelAdmin):
    list_display = ['id', 'user_id', 'name', 'value', 'threshold']


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['id', 'user_id', 'type', 'name', 'is_read']
    list_filter = ['type', 'is_read']
