from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'products', views.ProductViewSet, basename='product')
router.register(r'categories', views.CategoryViewSet, basename='category')
router.register(r'subcategories', views.SubcategoryViewSet, basename='subcategory')
router.register(r'home/banners', views.HomeBannerViewSet, basename='home-banner')
router.register(r'home/flash-sales', views.HomeFlashSaleViewSet, basename='home-flash-sale')
router.register(r'home/hot-ranks', views.HomeHotRankViewSet, basename='home-hot-rank')
router.register(r'home/recommends', views.HomeRecommendViewSet, basename='home-recommend')
router.register(r'home/new-arrivals', views.HomeNewArrivalViewSet, basename='home-new-arrival')
router.register(r'home/promotions', views.HomePromotionViewSet, basename='home-promotion')
router.register(r'cart', views.CartViewSet, basename='cart')
router.register(r'orders', views.OrderViewSet, basename='order')
router.register(r'payments', views.PaymentViewSet, basename='payment')
router.register(r'addresses', views.AddressViewSet, basename='address')
router.register(r'favorites', views.FavoriteViewSet, basename='favorite')
router.register(r'browse-history', views.BrowseHistoryViewSet, basename='browse-history')
router.register(r'coupons', views.CouponViewSet, basename='coupon')
router.register(r'notifications', views.NotificationViewSet, basename='notification')
router.register(r'user', views.UserViewSet, basename='user')
router.register(r'shop', views.ShopInfoViewSet, basename='shop')
router.register(r'vip', views.VIPViewSet, basename='vip')

admin_router = DefaultRouter()
admin_router.register(r'media', views.AdminMediaViewSet, basename='admin-media')
admin_router.register(r'products', views.AdminProductViewSet, basename='admin-product')
admin_router.register(r'categories', views.AdminCategoryViewSet, basename='admin-category')
admin_router.register(r'subcategories', views.AdminSubcategoryViewSet, basename='admin-subcategory')
admin_router.register(r'banners', views.AdminBannerViewSet, basename='admin-banner')
admin_router.register(r'home/flash-sales', views.AdminHomeFlashSaleViewSet, basename='admin-home-flash-sale')
admin_router.register(r'home/hot-ranks', views.AdminHomeHotRankViewSet, basename='admin-home-hot-rank')
admin_router.register(r'home/recommends', views.AdminHomeRecommendViewSet, basename='admin-home-recommend')
admin_router.register(r'home/new-arrivals', views.AdminHomeNewArrivalViewSet, basename='admin-home-new-arrival')
admin_router.register(r'home/promotions', views.AdminHomePromotionViewSet, basename='admin-home-promotion')
admin_router.register(r'orders', views.AdminOrderViewSet, basename='admin-order')
admin_router.register(r'users', views.AdminUserViewSet, basename='admin-user')
admin_router.register(r'coupons', views.AdminCouponViewSet, basename='admin-coupon')
admin_router.register(r'shop', views.AdminShopViewSet, basename='admin-shop')

urlpatterns = [
    path('h5/', include(router.urls)),
    path('h5/login/', views.h5_login, name='h5_login'),
    path('h5/user/', views.user_profile, name='h5_user_profile'),
    path('ios/', include(router.urls)),
    path('ios/login/', views.ios_login, name='ios_login'),
    path('ios/user/', views.user_profile, name='ios_user_profile'),
    path('admin/login/', views.admin_login, name='admin_login'),
    path('admin/overview/', views.admin_overview, name='admin_overview'),
    path('admin/', include(admin_router.urls)),
]
