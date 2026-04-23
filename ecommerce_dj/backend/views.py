from rest_framework import viewsets, serializers
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from rest_framework.authtoken.models import Token
from rest_framework.exceptions import AuthenticationFailed
from django.contrib.auth.models import User
import json
from datetime import datetime

from .models import (
    Category, Subcategory, Product, ProductDetail,
    HomeBanner, HomeFlashSale, HomeHotRank, HomeRecommend, HomeNewArrival, HomePromotion,
    CartItem, Order, OrderProduct, Address, Review, Favorite, History, UserCoupon, Notification,
    SpecGroup, SpecValue, SKU, SKUSpec
)
from .serializers import (
    ProductListSerializer, ProductDetailSerializer, SpecValueSerializer, SpecGroupSerializer,
    CategorySerializer, CategoryWithSubcategoriesSerializer, SubcategorySerializer, SubcategoryWithProductsSerializer,
    HomeBannerSerializer, HomeFlashSaleSerializer, HomeHotRankSerializer,
    HomeRecommendSerializer, HomeNewArrivalSerializer, HomePromotionSerializer,
    CartItemSerializer, OrderSerializer, OrderProductSerializer, AddressSerializer,
    FavoriteSerializer, HistorySerializer, CouponSerializer, NotificationSerializer,
    ReviewSerializer
)


def get_image_url(image_field, context=None):
    if image_field and image_field.file:
        if context and 'request' in context:
            return context['request'].build_absolute_uri(image_field.file.url)
        return image_field.file.url
    return None


# ============ SKU Algorithm ============
class SKUService:
    def __init__(self, spec_groups, skus):
        self.spec_groups = spec_groups
        self.skus = skus
        self.code_to_index = {}
        self.adj_matrix = []
        self._build_graph()

    def _build_graph(self):
        idx = 0
        for group in self.spec_groups:
            for value in group.values.all():
                code = f"{group.id}:{value.id}"
                self.code_to_index[code] = idx
                idx += 1

        n = idx
        self.adj_matrix = [[False] * n for _ in range(n)]

        for sku in self.skus:
            spec_value_ids = list(sku.spec_values.values_list('id', flat=True))
            if len(spec_value_ids) < 1:
                continue
            for i in range(len(spec_value_ids)):
                for j in range(i + 1, len(spec_value_ids)):
                    code_i = f"*:{spec_value_ids[i]}"
                    code_j = f"*:{spec_value_ids[j]}"
                    for group in self.spec_groups:
                        for value in group.values.all():
                            if value.id == spec_value_ids[i]:
                                code_i = f"{group.id}:{value.id}"
                            if value.id == spec_value_ids[j]:
                                code_j = f"{group.id}:{spec_value_ids[j]}"
                    if code_i in self.code_to_index and code_j in self.code_to_index:
                        ii, jj = self.code_to_index[code_i], self.code_to_index[code_j]
                        self.adj_matrix[ii][jj] = True
                        self.adj_matrix[jj][ii] = True

    def get_available_spec_values(self, selected_ids):
        if not selected_ids:
            return self._all_available()

        matching_skus = []
        for sku in self.skus:
            sku_spec_ids = set(sku.spec_values.values_list('id', flat=True))
            if all(sid in sku_spec_ids for sid in selected_ids):
                matching_skus.append(sku)

        if not matching_skus:
            return [{'groupId': g.id, 'availableValues': []} for g in self.spec_groups]

        available_in_skus = set()
        for sku in matching_skus:
            for sv in sku.spec_values.all():
                available_in_skus.add(sv.id)

        results = []
        for group in self.spec_groups:
            avail_ids = []
            for value in group.values.all():
                if value.id in available_in_skus:
                    avail_ids.append(value.id)
            results.append({'groupId': group.id, 'availableValues': avail_ids})
        return results

    def _all_available(self):
        results = []
        for group in self.spec_groups:
            avail_ids = list(group.values.values_list('id', flat=True))
            results.append({'groupId': group.id, 'availableValues': avail_ids})
        return results


def get_user_id(request):
    auth = request.headers.get('Authorization', '')
    if auth.startswith('Token '):
        try:
            key = auth[6:]
            token = Token.objects.get(key=key)
            return token.user.username
        except Token.DoesNotExist:
            raise AuthenticationFailed('无效的Token')
    return ''


# ============ ViewSets ============
class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.filter(is_in_stock=True)
    serializer_class = ProductListSerializer
    permission_classes = [AllowAny]

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return ProductDetailSerializer
        return ProductListSerializer

    def retrieve(self, request, *args, **kwargs):
        try:
            instance = self.get_object()
            serializer = self.get_serializer(instance)
            return Response({'code': 0, 'msg': 'success', 'data': serializer.data})
        except:
            return Response({'code': 404, 'msg': 'product not found'})

    @action(detail=False, methods=['get'])
    def search(self, request):
        q = request.GET.get('q', '')
        products = self.queryset.filter(name__icontains=q)
        return Response({'code': 0, 'msg': 'success', 'data': ProductListSerializer(products, many=True, context={'request': request}).data})

    @action(detail=True, methods=['get', 'post'])
    def reviews(self, request, pk=None):
        if request.method == 'GET':
            reviews = Review.objects.filter(product_id=pk)
            return Response({'code': 0, 'msg': 'success', 'data': ReviewSerializer(reviews, many=True, context={'request': request}).data})
        else:
            user_id = get_user_id(request)
            serializer = ReviewSerializer(data=request.data)
            if serializer.is_valid():
                serializer.save(user_id=user_id, product_id=pk, user_name='用户', user_avatar=None)
                return Response({'code': 0, 'msg': 'created', 'data': serializer.data})
            return Response({'code': 400, 'msg': 'invalid request'})

    @action(detail=True, methods=['get'], url_path='spec-available')
    def spec_available(self, request, pk=None):
        selected_str = request.GET.get('selected', '')
        selected_ids = [s.strip() for s in selected_str.split(',') if s.strip()] if selected_str else []

        try:
            product = Product.objects.get(id=pk)
            groups = SpecGroup.objects.filter(product=product)
            skus = SKU.objects.filter(product=product)
            if not groups.exists():
                return Response({'code': 0, 'msg': 'success', 'data': []})

            sku_service = SKUService(groups, skus)
            result = sku_service.get_available_spec_values(selected_ids)
            return Response({'code': 0, 'msg': 'success', 'data': result})
        except Product.DoesNotExist:
            return Response({'code': 404, 'msg': 'product not found'})


class SubcategoryViewSet(viewsets.ModelViewSet):
    queryset = Subcategory.objects.filter(is_enabled=True)
    serializer_class = SubcategorySerializer
    permission_classes = [AllowAny]

    @action(detail=True, methods=['get'])
    def products(self, request, pk=None):
        subcategory = self.get_object()
        products = subcategory.products.filter(is_in_stock=True)
        return Response({'code': 0, 'msg': 'success', 'data': ProductListSerializer(products, many=True, context={'request': request}).data})


class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.filter(is_enabled=True)
    serializer_class = CategorySerializer
    permission_classes = [AllowAny]

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return CategoryWithSubcategoriesSerializer
        return CategorySerializer

    @action(detail=True, methods=['get'])
    def subcategories(self, request, pk=None):
        category = self.get_object()
        subcategories = category.subcategories.filter(is_enabled=True)
        return Response({'code': 0, 'msg': 'success', 'data': SubcategoryWithProductsSerializer(subcategories, many=True, context={'request': request}).data})

    @action(detail=True, methods=['get'])
    def all_products(self, request, pk=None):
        """获取一级分类下所有子分类的产品"""
        category = self.get_object()
        products = Product.objects.filter(subcategory__category=category, is_in_stock=True)
        return Response({'code': 0, 'msg': 'success', 'data': ProductListSerializer(products, many=True, context={'request': request}).data})


class HomeBannerViewSet(viewsets.ModelViewSet):
    queryset = HomeBanner.objects.filter(is_enabled=True)
    serializer_class = HomeBannerSerializer
    permission_classes = [AllowAny]


class HomeFlashSaleViewSet(viewsets.ModelViewSet):
    queryset = HomeFlashSale.objects.filter(is_enabled=True)
    serializer_class = HomeFlashSaleSerializer
    permission_classes = [AllowAny]


class HomeHotRankViewSet(viewsets.ModelViewSet):
    queryset = HomeHotRank.objects.filter(is_enabled=True)
    serializer_class = HomeHotRankSerializer
    permission_classes = [AllowAny]


class HomeRecommendViewSet(viewsets.ModelViewSet):
    queryset = HomeRecommend.objects.filter(is_enabled=True)
    serializer_class = HomeRecommendSerializer
    permission_classes = [AllowAny]


class HomeNewArrivalViewSet(viewsets.ModelViewSet):
    queryset = HomeNewArrival.objects.filter(is_enabled=True)
    serializer_class = HomeNewArrivalSerializer
    permission_classes = [AllowAny]


class HomePromotionViewSet(viewsets.ModelViewSet):
    queryset = HomePromotion.objects.filter(is_enabled=True)
    serializer_class = HomePromotionSerializer
    permission_classes = [AllowAny]


class CartViewSet(viewsets.ModelViewSet):
    serializer_class = CartItemSerializer
    permission_classes = [AllowAny]
    http_method_names = ['get', 'post', 'patch', 'delete']

    def get_queryset(self):
        return CartItem.objects.filter(user_id=get_user_id(self.request)).select_related('product')

    def create(self, request):
        user_id = get_user_id(request)
        product_id = request.data.get('productId')
        quantity = request.data.get('quantity', 1)
        item, _ = CartItem.objects.get_or_create(user_id=user_id, product_id=product_id, defaults={'quantity': quantity})
        if not _:
            item.quantity += quantity
            item.save()
        return Response({'code': 0, 'msg': 'added to cart', 'data': {'id': str(item.id)}})

    @action(detail=True, methods=['patch'])
    def toggle(self, request, pk=None):
        item = self.get_object()
        item.is_selected = not item.is_selected
        item.save()
        return Response({'code': 0, 'msg': 'toggled'})

    @action(detail=False, methods=['put'])
    def select_all(self, request):
        selected = request.GET.get('selected', 'true') == 'true'
        CartItem.objects.filter(user_id=get_user_id(request)).update(is_selected=selected)
        return Response({'code': 0, 'msg': 'success'})

    def destroy(self, request, pk=None):
        item = self.get_object()
        item.delete()
        return Response({'code': 0, 'msg': 'removed'})

    @action(detail=False, methods=['delete'])
    def clear(self, request):
        CartItem.objects.filter(user_id=get_user_id(request)).delete()
        return Response({'code': 0, 'msg': 'cleared'})


class OrderViewSet(viewsets.ModelViewSet):
    serializer_class = OrderSerializer
    permission_classes = [AllowAny]
    http_method_names = ['get', 'post', 'put', 'delete']

    def get_queryset(self):
        qs = Order.objects.filter(user_id=get_user_id(self.request))
        status = self.request.GET.get('status')
        if status:
            qs = qs.filter(status=status)
        return qs.order_by('-created_at')

    def create(self, request):
        user_id = get_user_id(request)
        cart_item_ids = request.data.get('cartItemIds', [])
        address_id = request.data.get('addressId')
        remark = request.data.get('remark', '')

        total = 0
        order_products = []
        for cid in cart_item_ids:
            try:
                item = CartItem.objects.get(id=cid, user_id=user_id)
                total += float(item.product.price) * item.quantity
                order_products.append({
                    'name': item.product.name,
                    'spec': '',
                    'price': float(item.product.price),
                    'quantity': item.quantity,
                    'image': item.product.image,
                })
                item.delete()
            except:
                pass

            order = Order.objects.create(
                user_id=user_id,
                order_number=f"ORH5{datetime.now().strftime('%Y%m%d%H%M%S')}",
                store='潮流优品官方旗舰店',
                status='pending',
                total_amount=total,
                payment=total,
                freight=0,
                discount=0,
            )
            for op in order_products:
                OrderProduct.objects.create(order=order, **op)
        return Response({'code': 0, 'msg': 'order created', 'data': OrderSerializer(order, context={'request': request}).data})

    @action(detail=False, methods=['post'])
    def preview(self, request):
        """预订单接口 - 不入库，只返回预览数据"""
        user_id = get_user_id(request)
        cart_item_ids = request.data.get('cartItemIds', [])
        address_id = request.data.get('addressId')

        items = []
        total = 0
        for cid in cart_item_ids:
            try:
                item = CartItem.objects.select_related('product').get(id=cid, user_id=user_id)
                item_total = float(item.product.price) * item.quantity
                total += item_total
                items.append({
                    'cartId': str(item.id),
                    'productId': str(item.product.id),
                    'name': item.product.name,
                    'spec': '',
                    'price': float(item.product.price),
                    'originalPrice': float(item.product.original_price),
                    'quantity': item.quantity,
                    'image': get_image_url(item.product.image, context={'request': request}),
                })
            except CartItem.DoesNotExist:
                pass

        # 计算运费
        freight = 0 if total >= 99 else 10

        return Response({
            'code': 0,
            'msg': 'success',
            'data': {
                'items': items,
                'subtotal': total,
                'freight': freight,
                'total': total + freight,
                'store': '官方旗舰店',
            }
        })

    @action(detail=True, methods=['put'])
    def cancel(self, request, pk=None):
        order = self.get_object()
        if order.status == 'pending':
            order.status = 'cancelled'
            order.save()
        return Response({'code': 0, 'msg': 'order cancelled'})

    @action(detail=True, methods=['put'])
    def pay(self, request, pk=None):
        order = self.get_object()
        order.status = 'paid'
        order.save()
        return Response({'code': 0, 'msg': 'payment successful'})

    @action(detail=True, methods=['put'])
    def confirm(self, request, pk=None):
        order = self.get_object()
        order.status = 'completed'
        order.save()
        return Response({'code': 0, 'msg': 'confirmed'})


class AddressViewSet(viewsets.ModelViewSet):
    serializer_class = AddressSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        return Address.objects.filter(user_id=get_user_id(self.request))

    def perform_create(self, serializer):
        serializer.save(user_id=get_user_id(self.request))

    @action(detail=True, methods=['put'])
    def set_default(self, request, pk=None):
        user_id = get_user_id(request)
        Address.objects.filter(user_id=user_id).update(is_default=False)
        Address.objects.filter(id=pk, user_id=user_id).update(is_default=True)
        return Response({'code': 0, 'msg': 'success'})


class FavoriteViewSet(viewsets.ModelViewSet):
    serializer_class = FavoriteSerializer
    permission_classes = [AllowAny]
    http_method_names = ['get', 'post', 'delete']

    def get_queryset(self):
        return Favorite.objects.filter(user_id=get_user_id(self.request))

    def perform_create(self, serializer):
        product_id = self.request.data.get('productId')
        product = Product.objects.get(id=product_id)
        serializer.save(
            user_id=get_user_id(self.request),
            name=product.name,
            price=product.price,
            original_price=product.original_price,
            image=get_image_url(product.image, context={'request': self.request}),
            sales=f"{product.sales_count}+"
        )


class HistoryViewSet(viewsets.ModelViewSet):
    serializer_class = HistorySerializer
    permission_classes = [AllowAny]
    http_method_names = ['get', 'post', 'delete']

    def get_queryset(self):
        return History.objects.filter(user_id=get_user_id(self.request)).order_by('-time')

    def perform_create(self, serializer):
        product_id = self.request.data.get('productId')
        product = Product.objects.get(id=product_id)
        serializer.save(
            user_id=get_user_id(self.request),
            name=product.name,
            price=product.price,
            image=get_image_url(product.image, context={'request': self.request}),
            time='刚刚'
        )

    @action(detail=False, methods=['delete'])
    def clear(self, request):
        History.objects.filter(user_id=get_user_id(request)).delete()
        return Response({'code': 0, 'msg': 'cleared'})


class CouponViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = CouponSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        return UserCoupon.objects.filter(user_id=get_user_id(self.request))


class NotificationViewSet(viewsets.ModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [AllowAny]
    http_method_names = ['get', 'put']

    def get_queryset(self):
        qs = Notification.objects.filter(user_id=get_user_id(self.request))
        notif_type = self.request.GET.get('type')
        if notif_type:
            qs = qs.filter(type=notif_type)
        return qs

    @action(detail=False, methods=['get'])
    def count(self, request):
        user_id = get_user_id(request)
        count = Notification.objects.filter(user_id=user_id, is_read=False).count()
        return Response({'code': 0, 'msg': 'success', 'data': {'count': count}})

    @action(detail=False, methods=['put'])
    def read_all(self, request):
        Notification.objects.filter(user_id=get_user_id(request)).update(is_read=True)
        return Response({'code': 0, 'msg': 'success'})

    @action(detail=True, methods=['put'])
    def read(self, request, pk=None):
        Notification.objects.filter(id=pk, user_id=get_user_id(request)).update(is_read=True)
        return Response({'code': 0, 'msg': 'success'})


class LoginViewSet(viewsets.ViewSet):
    permission_classes = [AllowAny]
    authentication_classes = []

    @action(detail=False, methods=['post'])
    def login(self, request):
        user_id = request.data.get('user_id', 'u1')
        user, created = User.objects.get_or_create(username=user_id)
        token, _ = Token.objects.get_or_create(user=user)
        return Response({'code': 0, 'msg': 'success', 'data': {'token': token.key}})


class UserViewSet(viewsets.ViewSet):
    permission_classes = [AllowAny]

    @action(detail=False, methods=['get'])
    def profile(self, request):
        user_id = get_user_id(request)
        return Response({'code': 0, 'msg': 'success', 'data': {
            'id': user_id, 'name': '林小琳', 'email': 'linxiaolin@example.com',
            'avatar_name': 'https://picsum.photos/200/200?random=100',
            'followCount': 128, 'fansCount': 356, 'points': 2860,
        }})


# Function-based views for direct URL mapping
@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    user_id = request.data.get('user_id', 'u1')
    user, created = User.objects.get_or_create(username=user_id)
    token, _ = Token.objects.get_or_create(user=user)
    return Response({'code': 0, 'msg': 'success', 'data': {'token': token.key}})


@api_view(['GET'])
@permission_classes([AllowAny])
def user_profile(request):
    user_id = get_user_id(request)
    return Response({'code': 0, 'msg': 'success', 'data': {
        'id': user_id, 'name': '林小琳', 'email': 'linxiaolin@example.com',
        'avatar_name': 'https://picsum.photos/200/200?random=100',
        'followCount': 128, 'fansCount': 356, 'points': 2860,
    }})
