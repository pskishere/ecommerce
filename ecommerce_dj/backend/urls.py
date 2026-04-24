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
router.register(r'addresses', views.AddressViewSet, basename='address')
router.register(r'favorites', views.FavoriteViewSet, basename='favorite')
router.register(r'coupons', views.CouponViewSet, basename='coupon')
router.register(r'notifications', views.NotificationViewSet, basename='notification')
router.register(r'user', views.UserViewSet, basename='user')

urlpatterns = [
    path('h5/', include(router.urls)),
    path('h5/login/', views.h5_login, name='h5_login'),
    path('h5/user/', views.user_profile, name='h5_user_profile'),
    path('ios/', include(router.urls)),
    path('ios/login/', views.ios_login, name='ios_login'),
    path('ios/user/', views.user_profile, name='ios_user_profile'),
    path('admin/login/', views.admin_login, name='admin_login'),
]
