from decimal import Decimal

from django.contrib.auth.models import User
from rest_framework.test import APITestCase

from .models import (
    Address,
    BrowseHistory,
    Category,
    HomeBanner,
    HomeFlashSale,
    HomeHotRank,
    HomeRecommend,
    Order,
    OrderProduct,
    PaymentTransaction,
    Product,
    Subcategory,
    UserCoupon,
    UserProfile,
    VIPMembership,
    ShopInfo,
)
from mediafiles.models import MediaFile


class H5APISmokeTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='buyer',
            email='buyer@example.com',
            password='iole',
        )
        UserProfile.objects.create(user=self.user, user_type='user')

        self.category = Category.objects.create(name='女装', is_enabled=True)
        self.subcategory = Subcategory.objects.create(
            name='连衣裙',
            category=self.category,
            is_enabled=True,
        )
        self.product = Product.objects.create(
            name='测试连衣裙',
            description='测试商品描述',
            price=Decimal('189.00'),
            original_price=Decimal('299.00'),
            subcategory=self.subcategory,
            rating=Decimal('5.0'),
            review_count=0,
            sales_count=1000,
            is_in_stock=True,
            tag='热卖',
        )
        self.banner = HomeBanner.objects.create(
            tag='新品',
            title='测试 Banner',
            action_title='立即选购',
            link='campaign.html?banner_id=test',
            landing_badge='TEST',
            landing_subtitle='测试专题',
            landing_description='测试专题描述',
            is_enabled=True,
        )
        self.banner.products.add(self.product)
        flash = HomeFlashSale.objects.create(title='限时秒杀', is_enabled=True)
        flash.products.add(self.product)
        hot = HomeHotRank.objects.create(title='热销榜单', is_enabled=True)
        hot.products.add(self.product)
        recommend = HomeRecommend.objects.create(title='为你推荐', is_enabled=True)
        recommend.products.add(self.product)
        UserCoupon.objects.create(
            user=self.user,
            name='满100减20',
            value=20,
            threshold='满100可用',
            description='测试优惠券',
            time='2026-12-31',
        )

    def login(self):
        response = self.client.post('/api/h5/login/', {'username': 'buyer', 'password': 'iole'}, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['code'], 0)
        token = response.data['data']['token']
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {token}')
        return token

    def assert_success(self, response):
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['code'], 0, response.data)
        return response.data.get('data')

    def test_public_catalog_and_home_endpoints(self):
        categories = self.assert_success(self.client.get('/api/h5/categories/'))
        products = self.assert_success(self.client.get('/api/h5/products/'))
        detail = self.assert_success(self.client.get(f'/api/h5/products/{self.product.id}/'))
        search = self.assert_success(self.client.get('/api/h5/products/search/?q=连衣裙'))
        banners = self.assert_success(self.client.get('/api/h5/home/banners/'))
        banner_landing = self.assert_success(self.client.get(f'/api/h5/home/banners/{self.banner.id}/landing/'))
        flash = self.assert_success(self.client.get('/api/h5/home/flash-sales/'))
        hot = self.assert_success(self.client.get('/api/h5/home/hot-ranks/'))
        recommends = self.assert_success(self.client.get('/api/h5/home/recommends/'))

        self.assertEqual(len(categories), 1)
        self.assertEqual(len(products), 1)
        self.assertEqual(detail['id'], self.product.id)
        self.assertEqual(len(search), 1)
        self.assertEqual(len(banners), 1)
        self.assertEqual(banners[0]['link'], 'campaign.html?banner_id=test')
        self.assertEqual(banner_landing['landing_badge'], 'TEST')
        self.assertEqual(len(banner_landing['products']), 1)
        self.assertEqual(len(flash[0]['products']), 1)
        self.assertEqual(len(hot[0]['products']), 1)
        self.assertEqual(len(recommends[0]['products']), 1)

    def test_profile_update_persists_extended_fields(self):
        self.login()

        profile = self.assert_success(self.client.patch('/api/h5/user/profile/', {
            'username': '潮流买手',
            'email': 'trend@example.com',
            'phone': '13900139000',
            'gender': 'female',
            'birthday': '1998-06-15',
            'avatar': 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==',
        }, format='json'))

        self.assertEqual(profile['username'], '潮流买手')
        self.assertEqual(profile['email'], 'trend@example.com')
        self.assertEqual(profile['phone'], '13900139000')
        self.assertEqual(profile['phone_masked'], '139****9000')
        self.assertEqual(profile['gender'], 'female')
        self.assertEqual(profile['gender_label'], '女')
        self.assertEqual(profile['birthday'], '1998-06-15')
        self.assertIn('/media/uploads/', profile['avatar_name'])
        self.assertTrue(profile['registered_at'])

        self.user.refresh_from_db()
        self.user.profile.refresh_from_db()
        self.assertEqual(self.user.username, '潮流买手')
        self.assertEqual(self.user.profile.phone, '13900139000')
        self.assertEqual(self.user.profile.gender, 'female')
        self.assertEqual(self.user.profile.birthday.isoformat(), '1998-06-15')
        self.assertIsNotNone(self.user.profile.avatar)
        self.assertEqual(MediaFile.objects.filter(id=self.user.profile.avatar_id).count(), 1)

    def test_cart_order_payment_notification_favorite_and_review_flow(self):
        self.login()

        address = self.assert_success(self.client.post('/api/h5/addresses/', {
            'name': '测试用户',
            'phone': '13800138000',
            'province': '广东省',
            'city': '深圳市',
            'district': '南山区',
            'detail': '科技园测试地址1号',
            'is_default': True,
        }, format='json'))
        cart_item = self.assert_success(self.client.post('/api/h5/cart/', {
            'productId': self.product.id,
            'quantity': 2,
        }, format='json'))
        cart = self.assert_success(self.client.get('/api/h5/cart/'))
        self.assertEqual(len(cart['items']), 1)
        self.assertEqual(cart['items'][0]['quantity'], 2)

        coupon = UserCoupon.objects.get(user=self.user)
        preview = self.assert_success(self.client.post('/api/h5/orders/preview/', {
            'cartItemIds': [cart_item['id']],
            'addressId': address['id'],
            'couponId': coupon.id,
        }, format='json'))
        self.assertEqual(len(preview['items']), 1)
        self.assertEqual(preview['discount'], 20.0)

        order = self.assert_success(self.client.post('/api/h5/orders/', {
            'cartItemIds': [cart_item['id']],
            'addressId': address['id'],
            'couponId': coupon.id,
        }, format='json'))
        self.assertEqual(order['status'], 'pending')
        self.assertEqual(Address.objects.filter(user=self.user).count(), 1)
        self.assertEqual(UserCoupon.objects.get(id=coupon.id).status, 'used')

        payment = self.assert_success(self.client.put(f"/api/h5/orders/{order['id']}/pay/", {
            'paymentMethod': 'wxpay',
        }, format='json'))
        self.assertEqual(payment['status'], 'requires_action')
        self.assertEqual(payment['order']['status'], 'pending')
        self.assertEqual(PaymentTransaction.objects.filter(order_id=order['id'], status='requires_action').count(), 1)

        paid_payment = self.assert_success(self.client.post(f"/api/h5/payments/{payment['id']}/confirm/", {}, format='json'))
        self.assertEqual(paid_payment['status'], 'succeeded')
        paid = paid_payment['order']
        self.assertEqual(paid['status'], 'paid')

        shipped = self.assert_success(self.client.put(f"/api/h5/orders/{order['id']}/ship/", {
            'carrier': '顺丰速运',
            'trackingNumber': 'SFTEST001',
        }, format='json'))
        self.assertEqual(shipped['status'], 'shipped')
        self.assertEqual(shipped['carrier'], '顺丰速运')
        self.assertEqual(shipped['tracking_number'], 'SFTEST001')
        self.assertGreaterEqual(len(shipped['logistics']), 2)

        logistics = self.assert_success(self.client.get(f"/api/h5/orders/{order['id']}/logistics/"))
        self.assertEqual(logistics['tracking_number'], 'SFTEST001')
        self.assertGreaterEqual(len(logistics['items']), 2)

        confirmed = self.assert_success(self.client.put(f"/api/h5/orders/{order['id']}/confirm/", {}, format='json'))
        self.assertEqual(confirmed['status'], 'completed')

        after_sale = self.assert_success(self.client.post(f"/api/h5/orders/{order['id']}/after-sale/", {
            'reason': '尺码不合适',
        }, format='json'))
        self.assertEqual(after_sale['after_sale_status'], 'requested')
        self.assertEqual(after_sale['after_sale_status_text'], '已申请')

        buy_again = self.assert_success(self.client.post(f"/api/h5/orders/{order['id']}/buy-again/", {}, format='json'))
        self.assertEqual(buy_again['added_count'], 2)

        favorite = self.assert_success(self.client.post('/api/h5/favorites/', {
            'productId': self.product.id,
        }, format='json'))
        favorite_check = self.assert_success(self.client.get(f'/api/h5/favorites/check/?product_id={self.product.id}'))
        self.assertTrue(favorite_check['is_favorited'])
        self.assertEqual(favorite_check['favorite_id'], favorite['id'])

        history = self.assert_success(self.client.post('/api/h5/browse-history/', {
            'productId': self.product.id,
        }, format='json'))
        self.assertEqual(history['product']['id'], self.product.id)
        self.assertEqual(BrowseHistory.objects.filter(user=self.user).count(), 1)
        self.assert_success(self.client.post('/api/h5/browse-history/', {
            'productId': self.product.id,
        }, format='json'))
        self.assertEqual(BrowseHistory.objects.filter(user=self.user).count(), 1)
        history_list = self.assert_success(self.client.get('/api/h5/browse-history/'))
        self.assertEqual(len(history_list), 1)

        review = self.assert_success(self.client.post(f'/api/h5/products/{self.product.id}/reviews/', {
            'rating': 5,
            'content': '很好用',
            'spec': '',
            'is_anonymous': True,
            'images': [
                'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw=='
            ],
        }, format='json'))
        self.assertEqual(review['content'], '很好用')
        self.assertEqual(len(review['images']), 1)

        unread = self.assert_success(self.client.get('/api/h5/notifications/count/'))
        self.assertGreaterEqual(unread['count'], 3)
        self.assert_success(self.client.put('/api/h5/notifications/read_all/', {}, format='json'))
        unread_after = self.assert_success(self.client.get('/api/h5/notifications/count/'))
        self.assertEqual(unread_after['count'], 0)
        self.assert_success(self.client.delete('/api/h5/browse-history/clear/'))
        self.assertEqual(BrowseHistory.objects.filter(user=self.user).count(), 0)


class AdminAPITests(APITestCase):
    def setUp(self):
        self.admin = User.objects.create_user(
            username='admin',
            email='admin@example.com',
            password='iole',
        )
        UserProfile.objects.create(user=self.admin, user_type='admin')

        self.buyer = User.objects.create_user(
            username='buyer',
            email='buyer@example.com',
            password='iole',
        )
        UserProfile.objects.create(user=self.buyer, user_type='user')
        VIPMembership.objects.create(user=self.buyer, points=80)

        self.category = Category.objects.create(name='女装', is_enabled=True)
        self.subcategory = Subcategory.objects.create(
            name='连衣裙',
            category=self.category,
            is_enabled=True,
        )
        self.product = Product.objects.create(
            name='后台测试商品',
            description='后台测试商品描述',
            price=Decimal('88.00'),
            original_price=Decimal('128.00'),
            subcategory=self.subcategory,
            rating=Decimal('4.9'),
            review_count=3,
            sales_count=99,
            is_in_stock=True,
            tag='测试',
        )
        self.banner = HomeBanner.objects.create(
            tag='TEST',
            title='后台测试 Banner',
            action_title='查看',
            link='campaign.html?banner_id=test',
            is_enabled=True,
        )
        self.banner.products.add(self.product)
        self.order = Order.objects.create(
            user=self.buyer,
            id='ORADMIN001',
            store='潮流优品官方旗舰店',
            status='pending',
            total_amount=Decimal('88.00'),
            payment=Decimal('88.00'),
            address_name='测试买家',
            address_phone='13800138000',
            address_province='广东省',
            address_city='深圳市',
            address_district='南山区',
            address_detail='科技园',
        )
        OrderProduct.objects.create(
            order=self.order,
            product_id=self.product.id,
            name=self.product.name,
            price=self.product.price,
            quantity=1,
        )
        UserCoupon.objects.create(
            user=self.buyer,
            name='已有优惠券',
            value=10,
            threshold='满50可用',
            description='测试',
            time='2026-12-31',
        )

    def assert_success(self, response):
        self.assertEqual(response.status_code, 200, response.content)
        self.assertEqual(response.data['code'], 0, response.data)
        return response.data.get('data')

    def login_admin(self):
        response = self.client.post('/api/admin/login/', {'username': 'admin', 'password': 'iole'}, format='json')
        data = self.assert_success(response)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {data['token']}")

    def test_admin_permission_and_overview(self):
        self.assertEqual(self.client.get('/api/admin/overview/').status_code, 401)

        user_login = self.client.post('/api/h5/login/', {'username': 'buyer', 'password': 'iole'}, format='json')
        token = self.assert_success(user_login)['token']
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {token}')
        self.assertEqual(self.client.get('/api/admin/overview/').status_code, 403)

        self.login_admin()
        overview = self.assert_success(self.client.get('/api/admin/overview/'))
        self.assertEqual(overview['metrics']['orders'], 1)
        self.assertEqual(overview['metrics']['products'], 1)
        self.assertEqual(overview['recent_orders'][0]['id'], self.order.id)

    def test_admin_catalog_content_management(self):
        self.login_admin()
        product_list = self.assert_success(self.client.get('/api/admin/products/'))
        self.assertEqual(product_list['total'], 1)

        updated_product = self.assert_success(self.client.patch(f'/api/admin/products/{self.product.id}/', {
            'price': '99.00',
            'is_in_stock': False,
            'tag': '已调整',
        }, format='json'))
        self.assertEqual(updated_product['price'], '99.00')
        self.assertFalse(updated_product['is_in_stock'])
        h5_products = self.assert_success(self.client.get('/api/h5/products/'))
        self.assertEqual(h5_products, [])

        new_category = self.assert_success(self.client.post('/api/admin/categories/', {
            'name': '鞋包配饰',
            'sort_order': 9,
            'is_enabled': True,
        }, format='json'))
        new_subcategory = self.assert_success(self.client.post('/api/admin/subcategories/', {
            'name': '通勤包',
            'category_id': new_category['id'],
            'sort_order': 1,
            'is_enabled': True,
        }, format='json'))
        self.assertEqual(new_subcategory['category_name'], '鞋包配饰')

        banner = self.assert_success(self.client.patch(f'/api/admin/banners/{self.banner.id}/', {
            'title': '新版 Banner',
            'product_ids': [self.product.id],
            'is_enabled': True,
        }, format='json'))
        self.assertEqual(banner['title'], '新版 Banner')
        self.assertEqual(banner['product_count'], 1)

    def test_admin_order_user_coupon_and_shop_flow(self):
        self.login_admin()

        paid = self.assert_success(self.client.post(f'/api/admin/orders/{self.order.id}/mark-paid/', {}, format='json'))
        self.assertEqual(paid['status'], 'paid')

        shipped = self.assert_success(self.client.post(f'/api/admin/orders/{self.order.id}/ship/', {
            'carrier': '顺丰速运',
            'tracking_number': 'SFADMIN001',
        }, format='json'))
        self.assertEqual(shipped['status'], 'shipped')
        self.assertEqual(shipped['tracking_number'], 'SFADMIN001')

        after_sale = self.assert_success(self.client.post(f'/api/admin/orders/{self.order.id}/after-sale/', {
            'after_sale_status': 'processing',
            'after_sale_reason': '后台处理中',
        }, format='json'))
        self.assertEqual(after_sale['after_sale_status'], 'processing')

        user = self.assert_success(self.client.patch(f'/api/admin/users/{self.buyer.id}/', {
            'vip_level': 'gold',
            'points': 500,
            'is_active': True,
        }, format='json'))
        self.assertEqual(user['vip_level'], 'gold')
        self.assertEqual(user['points'], 500)

        coupon = self.assert_success(self.client.post('/api/admin/coupons/', {
            'username': 'buyer',
            'name': '后台发放券',
            'value': 30,
            'threshold': '满120可用',
            'time': '2026-12-31',
        }, format='json'))
        self.assertEqual(coupon['username'], 'buyer')
        self.assertEqual(UserCoupon.objects.filter(user=self.buyer).count(), 2)

        shop = self.assert_success(self.client.patch('/api/admin/shop/save/', {
            'name': '潮流好物测试店',
            'description': '后台保存',
            'score': '4.8',
            'product_count': 12,
            'sales': '99万',
            'fans_count': '88万',
        }, format='json'))
        self.assertEqual(shop['name'], '潮流好物测试店')
        self.assertEqual(ShopInfo.objects.get(pk=1).product_count, 12)
