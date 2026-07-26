from rest_framework import viewsets, serializers, mixins
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, BasePermission, IsAuthenticated
from rest_framework.authtoken.models import Token
from rest_framework.exceptions import AuthenticationFailed
from django.contrib.auth.models import User
from django.core.files.base import ContentFile
from django.conf import settings
from django.db import transaction
from django.db.models import Avg, Count, Prefetch, Q, Sum
from django.utils import timezone
from mediafiles.models import MediaFile
import base64
import binascii
import uuid
import json
import re
from datetime import datetime
from decimal import Decimal
from .serializers import get_image_url, sku_spec_text


def api_response(data=None, msg='success', code=0):
    """统一API响应格式"""
    return Response({'code': code, 'msg': msg, 'data': data})


def coupon_threshold_amount(coupon):
    match = re.search(r'\d+(?:\.\d+)?', coupon.threshold or '')
    return Decimal(match.group(0)) if match else Decimal('0')


GENDER_INPUT_MAP = {
    'male': 'male',
    '男': 'male',
    'female': 'female',
    '女': 'female',
    'secret': 'secret',
    '保密': 'secret',
    '': 'secret',
    None: 'secret',
}


def mask_phone(phone):
    phone = (phone or '').strip()
    if len(phone) >= 7:
        return f'{phone[:3]}****{phone[-4:]}'
    return phone


def parse_birthday(value):
    if value in (None, ''):
        return None, None
    try:
        return datetime.strptime(str(value), '%Y-%m-%d').date(), None
    except (TypeError, ValueError):
        return None, '生日格式应为 YYYY-MM-DD'


def profile_payload(user, request):
    profile, _ = UserProfile.objects.get_or_create(user=user)
    vip, _ = VIPMembership.objects.get_or_create(user=user)
    gender_label = dict(UserProfile.GENDER_CHOICES).get(profile.gender, '保密')
    return {
        'id': user.id,
        'username': user.username,
        'email': user.email or '',
        'avatar_name': get_image_url(profile.avatar, context={'request': request}) or 'https://picsum.photos/200/200?random=100',
        'phone': profile.phone or '',
        'phone_masked': mask_phone(profile.phone),
        'gender': profile.gender,
        'gender_label': gender_label,
        'birthday': profile.birthday.isoformat() if profile.birthday else '',
        'registered_at': user.date_joined.date().isoformat() if user.date_joined else '',
        'followCount': profile.follow_count,
        'fansCount': profile.fans_count,
        'points': vip.points or profile.points,
        'vip_level': vip.level,
        'vip_level_name': vip.get_level_display(),
        'vip_expire_date': str(vip.expire_date) if vip.expire_date else None,
    }


def update_profile(user, data):
    profile, _ = UserProfile.objects.get_or_create(user=user)

    if 'username' in data:
        username = str(data.get('username') or '').strip()
        if not username:
            return '昵称不能为空'
        user.username = username
    if 'email' in data:
        user.email = str(data.get('email') or '').strip()

    if 'phone' in data:
        profile.phone = str(data.get('phone') or '').strip()
    if 'gender' in data:
        gender = GENDER_INPUT_MAP.get(data.get('gender'))
        if gender is None:
            return '性别参数无效'
        profile.gender = gender
    if 'birthday' in data:
        birthday, error = parse_birthday(data.get('birthday'))
        if error:
            return error
        profile.birthday = birthday
    if 'avatar' in data:
        avatar_data = data.get('avatar')
        if avatar_data:
            avatar = media_from_data_url(avatar_data, original_prefix='avatar')
            if not avatar:
                return '头像图片格式无效'
            profile.avatar = avatar

    user.save()
    profile.save()
    return None


def media_from_data_url(data_url, original_prefix='review-image'):
    if not isinstance(data_url, str) or not data_url.startswith('data:image/'):
        return None
    try:
        header, encoded = data_url.split(',', 1)
        match = re.match(r'data:(image/[a-zA-Z0-9+.-]+);base64', header)
        if not match:
            return None
        mime_type = match.group(1)
        ext = mime_type.split('/')[-1].split('+')[0]
        raw = base64.b64decode(encoded)
        if len(raw) > 5 * 1024 * 1024:
            return None
        media = MediaFile(
            original_name=f'{original_prefix}.{ext}',
            size=len(raw),
            mime_type=mime_type,
        )
        media.file.save(f'{original_prefix}-{uuid.uuid4().hex}.{ext}', ContentFile(raw), save=True)
        return media
    except (ValueError, TypeError, binascii.Error):
        return None


class ResponseMixin:
    """Mixin to wrap all responses in unified format"""

    def list(self, request, *args, **kwargs):
        queryset = self.filter_queryset(self.get_queryset())
        serializer = self.get_serializer(queryset, many=True)
        return api_response(serializer.data)

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return api_response(serializer.data)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        return api_response(serializer.data)

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        return api_response(serializer.data)

    def partial_update(self, request, *args, **kwargs):
        kwargs['partial'] = True
        return self.update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        self.perform_destroy(instance)
        return api_response()


from .models import (
    Category, Subcategory, Product, ProductDetail,
    HomeBanner, HomeFlashSale, HomeHotRank, HomeRecommend, HomeNewArrival, HomePromotion,
    CartItem, Order, OrderProduct, Address, Review, Favorite, BrowseHistory, UserCoupon, Notification, UserProfile,
    PaymentTransaction, SpecGroup, SpecValue, SKU, SKUSpec,
    ShopInfo, VIPMembership, VIP_LEVEL_NAMES, VIP_LEVEL_ORDER
)

from .serializers import (
    ProductListSerializer, ProductDetailSerializer, SpecValueSerializer, SpecGroupSerializer,
    CategorySerializer, CategoryWithSubcategoriesSerializer, SubcategorySerializer, SubcategoryWithProductsSerializer,
    HomeBannerSerializer, HomeBannerLandingSerializer, HomeFlashSaleSerializer, HomeHotRankSerializer,
    HomeRecommendSerializer, HomeNewArrivalSerializer, HomePromotionSerializer,
    CartItemSerializer, OrderSerializer, OrderProductSerializer, AddressSerializer,
    FavoriteSerializer, BrowseHistorySerializer, CouponSerializer, NotificationSerializer,
    ReviewSerializer, PaymentTransactionSerializer, ShopInfoSerializer, VIPSerializer
)


REGION_DATA = {
  '北京市': {'北京市': ['东城区', '西城区', '朝阳区', '丰台区', '石景山区', '海淀区', '顺义区', '通州区', '大兴区', '房山区', '门头沟区', '昌平区', '平谷区', '密云区', '怀柔区', '延庆区']},
  '上海市': {'上海市': ['黄浦区', '徐汇区', '长宁区', '静安区', '普陀区', '虹口区', '杨浦区', '闵行区', '宝山区', '嘉定区', '浦东新区', '金山区', '松江区', '青浦区', '奉贤区', '崇明区']},
  '广东省': {
    '广州市': ['越秀区', '海珠区', '荔湾区', '天河区', '白云区', '黄埔区', '番禺区', '花都区', '南沙区', '从化区', '增城区'],
    '深圳市': ['罗湖区', '福田区', '南山区', '宝安区', '龙岗区', '盐田区', '龙华区', '坪山区', '光明区'],
    '东莞市': ['莞城区', '南城区', '东城区', '万江区', '石碣镇', '石龙镇', '茶山镇', '石排镇', '企石镇', '横沥镇', '桥头镇', '谢岗镇', '东坑镇', '常平镇', '寮步镇', '大朗镇', '黄江镇', '清溪镇', '塘厦镇', '凤岗镇', '长安镇', '虎门镇', '厚街镇', '沙田镇', '道滘镇', '洪梅镇', '麻涌镇', '望牛墩镇', '中堂镇', '高埗镇'],
    '佛山市': ['禅城区', '南海区', '顺德区', '三水区', '高明区'],
    '珠海市': ['香洲区', '斗门区', '金湾区'],
    '中山市': ['石岐区', '东区', '西区', '南区', '中山港街道', '五桂山街道'],
    '惠州市': ['惠城区', '惠阳区', '博罗县', '惠东县', '龙门县'],
    '汕头市': ['龙湖区', '金平区', '濠江区', '潮阳区', '潮南区', '澄海区', '南澳县'],
    '江门市': ['蓬江区', '江海区', '新会区', '台山市', '开平市', '鹤山市', '恩平市'],
  },
  '浙江省': {
    '杭州市': ['上城区', '下城区', '西湖区', '拱墅区', '江干区', '滨江区', '萧山区', '余杭区', '临平区', '钱塘区', '富阳区', '临安区', '桐庐县', '淳安县'],
    '宁波市': ['海曙区', '江北区', '北仑区', '镇海区', '鄞州区', '奉化区', '象山县', '宁海县', '余姚市', '慈溪市'],
    '温州市': ['鹿城区', '龙湾区', '瓯海区', '洞头区', '永嘉县', '平阳县', '苍南县', '文成县', '泰顺县', '瑞安市', '乐清市', '龙港市'],
    '嘉兴市': ['南湖区', '秀洲区', '嘉善县', '海盐县', '海宁市', '平湖市', '桐乡市'],
    '湖州市': ['吴兴区', '南浔区', '德清县', '长兴县', '安吉县'],
    '绍兴市': ['越城区', '柯桥区', '上虞区', '新昌县', '诸暨市', '嵊州市'],
    '金华市': ['婺城区', '金东区', '武义县', '浦江县', '磐安县', '兰溪市', '义乌市', '东阳市', '永康市'],
    '台州市': ['椒江区', '黄岩区', '路桥区', '三门县', '天台县', '仙居县', '温岭市', '临海市', '玉环市'],
    '苏州市': ['姑苏区', '虎丘区', '吴中区', '相城区', '吴江区', '工业园区', '高新区', '昆山市', '常熟市', '张家港市', '太仓市'],
  },
  '江苏省': {
    '南京市': ['玄武区', '秦淮区', '建邺区', '鼓楼区', '栖霞区', '雨花台区', '江宁区', '浦口区', '六合区', '溧水区', '高淳区'],
    '苏州市': ['姑苏区', '虎丘区', '吴中区', '相城区', '吴江区', '工业园区', '高新区', '昆山市', '常熟市', '张家港市', '太仓市'],
    '无锡市': ['锡山区', '惠山区', '滨湖区', '梁溪区', '新吴区', '江阴市', '宜兴市'],
    '常州市': ['天宁区', '钟楼区', '新北区', '武进区', '金坛区', '溧阳市'],
    '南通市': ['崇川区', '港闸区', '通州区', '如东县', '启东市', '如皋市', '海门市', '海安市'],
    '徐州市': ['云龙区', '鼓楼区', '贾汪区', '泉山区', '铜山区', '丰县', '沛县', '睢宁县', '新沂市', '邳州市'],
    '扬州市': ['广陵区', '邗江区', '江都区', '宝应县', '仪征市', '高邮市'],
    '盐城市': ['亭湖区', '盐都区', '大丰区', '响水县', '滨海县', '阜宁县', '射阳县', '建湖县', '东台市'],
    '连云港市': ['连云区', '海州区', '赣榆区', '东海县', '灌云县', '灌南县'],
    '泰州市': ['海陵区', '高港区', '姜堰区', '兴化市', '靖江市', '泰兴市'],
    '镇江市': ['京口区', '润州区', '丹徒区', '丹阳市', '扬中市', '句容市'],
    '淮安市': ['清江浦区', '淮安区', '淮阴区', '洪泽区', '涟水县', '盱眙县', '金湖县'],
    '宿迁市': ['宿城区', '宿豫区', '沭阳县', '泗阳县', '泗洪县'],
  },
  '四川省': {
    '成都市': ['锦江区', '青羊区', '金牛区', '武侯区', '成华区', '龙泉驿区', '青白江区', '新都区', '温江区', '双流区', '郫都区', '金堂县', '大邑县', '蒲江县', '新津区', '都江堰市', '彭州市', '邛崃市', '崇州市', '简阳市'],
    '绵阳市': ['涪城区', '游仙区', '安州区', '三台县', '盐亭县', '梓潼县', '北川县', '平武县', '江油市'],
    '德阳市': ['旌阳区', '罗江区', '中江县', '广汉市', '什邡市', '绵竹市'],
    '南充市': ['顺庆区', '高坪区', '嘉陵区', '南部县', '营山县', '蓬安县', '仪陇县', '西充县', '阆中市'],
    '宜宾市': ['翠屏区', '南溪区', '叙州区', '江安县', '长宁县', '高县', '珙县', '筠连县', '兴文县', '屏山县'],
    '自贡市': ['自流井区', '贡井区', '大安区', '沿滩区', '荣县', '富顺县'],
    '泸州市': ['江阳区', '纳溪区', '龙马潭区', '泸县', '合江县', '叙永县', '古蔺县'],
    '内江市': ['市中区', '东兴区', '威远县', '资中县', '隆昌市'],
    '乐山市': ['市中区', '沙湾区', '五通桥区', '金口河区', '犍为县', '井研县', '夹江县', '沐川县', '峨边县', '马边县', '峨眉山市'],
  },
  '湖北省': {
    '武汉市': ['江岸区', '江汉区', '硚口区', '汉阳区', '武昌区', '青山区', '洪山区', '东西湖区', '汉南区', '蔡甸区', '江夏区', '黄陂区', '新洲区'],
    '宜昌市': ['西陵区', '伍家岗区', '点军区', '猇亭区', '夷陵区', '远安县', '兴山县', '秭归县', '长阳县', '五峰县', '宜都市', '当阳市', '枝江市'],
    '襄阳市': ['襄城区', '樊城区', '襄州区', '襄阳县', '宜城县', '老河口市', '枣阳市', '宜城市', '南漳县', '谷城县', '保康县'],
    '荆州市': ['沙市区', '荆州区', '公安县', '监利县', '江陵县', '石首市', '洪湖市', '松滋市'],
    '黄石市': ['黄港区', '西塞山区', '下陆区', '铁山区', '阳新县', '大冶市'],
    '十堰市': ['茅箭区', '张湾区', '郧阳区', '郧西县', '竹山县', '竹溪县', '房县', '丹江口市'],
  },
  '湖南省': {
    '长沙市': ['芙蓉区', '天心区', '岳麓区', '开福区', '雨花区', '望城区', '长沙县', '浏阳市', '宁乡市'],
    '株洲市': ['荷塘区', '芦淞区', '石峰区', '天元区', '渌口区', '攸县', '茶陵县', '炎陵县', '醴陵市'],
    '湘潭市': ['雨湖区', '岳塘区', '湘潭县', '湘乡市', '韶山市'],
    '衡阳市': ['珠晖区', '雁峰区', '石鼓区', '蒸湘区', '南岳区', '衡阳县', '衡南县', '衡山县', '衡东县', '祁东县', '耒阳市', '常宁市'],
    '岳阳市': ['岳阳楼区', '云溪区', '君山区', '岳阳县', '华容县', '湘阴县', '平江县', '汨罗市', '临湘市'],
    '常德市': ['武陵区', '鼎城区', '安乡县', '汉寿县', '澧县', '临澧县', '桃源县', '石门县', '津市市'],
  },
  '山东省': {
    '济南市': ['历下区', '市中区', '槐荫区', '天桥区', '历城区', '长清区', '章丘区', '济阳区', '莱芜区', '钢城区', '平阴县', '商河县'],
    '青岛市': ['市南区', '市北区', '黄岛区', '崂山区', '李沧区', '城阳区', '胶州市', '即墨区', '平度市', '莱西市'],
    '烟台市': ['芝罘区', '福山区', '牟平区', '莱山区', '蓬莱区', '龙口市', '莱阳市', '莱州市', '招远市', '栖霞市', '海阳市'],
    '威海市': ['环翠区', '文登区', '荣成市', '乳山市'],
    '潍坊市': ['潍城区', '寒亭区', '坊子区', '奎文区', '临朐县', '昌乐县', '青州市', '诸城市', '寿光市', '安丘市', '高密市', '昌邑市'],
    '临沂市': ['兰山区', '罗庄区', '河东区', '沂南县', '郯城县', '沂水县', '兰陵县', '费县', '平邑县', '莒南县', '蒙阴县', '临沭县'],
    '淄博市': ['淄川区', '张店区', '博山区', '临淄区', '周村区', '桓台县', '高青县', '沂源县'],
  },
  '河南省': {
    '郑州市': ['中原区', '二七区', '管城区', '金水区', '惠济区', '上街区', '巩义市', '荥阳市', '新密市', '新郑市', '登封市', '中牟县'],
    '洛阳市': ['老城区', '西工区', '瀍河区', '涧西区', '吉利区', '洛龙区', '偃师区', '孟津县', '新安县', '栾川县', '嵩县', '汝阳县', '宜阳县', '洛宁县', '伊川县'],
    '开封市': ['龙亭区', '顺河区', '鼓楼区', '禹王台区', '祥符区', '杞县', '通许县', '尉氏县', '兰考县'],
    '南阳市': ['宛城区', '卧龙区', '南召县', '方城县', '西峡县', '镇平县', '内乡县', '淅川县', '社旗县', '唐河县', '新野县', '桐柏县', '邓州市'],
    '新乡市': ['红旗区', '卫滨区', '牧野区', '凤泉区', '卫辉市', '辉县市', '新乡县', '获嘉县', '原阳县', '延津县', '封丘县'],
    '安阳市': ['文峰区', '北关区', '殷都区', '龙安区', '安阳县', '汤阴县', '滑县', '内黄县', '林州市'],
  },
  '河北省': {
    '石家庄市': ['长安区', '桥西区', '新华区', '井陉矿区', '裕华区', '藁城区', '鹿泉区', '栾城区', '井陉县', '正定县', '行唐县', '灵寿县', '高邑县', '深泽县', '赞皇县', '无极县', '平山县', '元氏县', '赵县', '晋州市', '新乐市'],
    '保定市': ['竞秀区', '莲池区', '满城区', '清苑区', '徐水区', '涞水县', '阜平县', '定兴县', '唐县', '高阳县', '容城县', '涞源县', '望都县', '安新县', '易县', '曲阳县', '蠡县', '顺平县', '博野县', '雄县', '涿州市', '定州市', '安国市', '高碑店市'],
    '唐山市': ['路南区', '路北区', '古冶区', '开平区', '丰南区', '丰润区', '曹妃甸区', '滦南县', '乐亭县', '迁西县', '玉田县', '遵化市', '迁安市'],
    '廊坊市': ['安次区', '广阳区', '固安县', '永清县', '香河县', '大城县', '文安县', '大厂县', '霸州市', '三河市'],
    '沧州市': ['新华区', '运河区', '沧县', '青县', '东光县', '海兴县', '盐山县', '肃宁县', '南皮县', '吴桥县', '献县', '孟村县', '泊头市', '任丘市', '黄骅市', '河间市'],
  },
  '福建省': {
    '福州市': ['鼓楼区', '台江区', '仓山区', '马尾区', '晋安区', '长乐区', '闽侯县', '连江县', '罗源县', '闽清县', '永泰县', '平潭县', '福清市'],
    '厦门市': ['思明区', '海沧区', '湖里区', '集美区', '同安区', '翔安区'],
    '泉州市': ['鲤城区', '丰泽区', '洛江区', '泉港区', '惠安县', '安溪县', '永春县', '德化县', '金门县', '石狮市', '晋江市', '南安市'],
    '漳州市': ['芗城区', '龙文区', '龙海区', '云霄县', '漳浦县', '诏安县', '长泰县', '东山县', '南靖县', '平和县', '华安县'],
    '莆田市': ['城厢区', '涵江区', '荔城区', '秀屿区', '仙游县'],
    '宁德市': ['蕉城区', '霞浦县', '古田县', '屏南县', '寿宁县', '周宁县', '柘荣县', '福安市', '福鼎市'],
  },
  '辽宁省': {
    '沈阳市': ['和平区', '沈河区', '大东区', '皇姑区', '铁西区', '苏家屯区', '浑南区', '沈北新区', '于洪区', '辽中区', '康平县', '法库县', '新民市'],
    '大连市': ['中山区', '西岗区', '沙河口区', '甘井子区', '旅顺口区', '金州区', '普兰店区', '瓦房店市', '庄河市'],
    '鞍山市': ['铁东区', '铁西区', '立山区', '千山区', '台安县', '岫岩县', '海城市'],
    '锦州市': ['古塔区', '凌河区', '太和区', '黑山县', '义县', '凌海市', '北镇市'],
  },
  '黑龙江省': {
    '哈尔滨市': ['道里区', '南岗区', '道外区', '平房区', '松北区', '香坊区', '呼兰区', '阿城区', '双城区', '依兰县', '方正县', '宾县', '巴彦县', '木兰县', '通河县', '延寿县', '尚志市', '五常市'],
    '大庆市': ['萨尔图区', '龙凤区', '让胡路区', '红岗区', '大同区', '肇州县', '肇源县', '林甸县', '杜尔伯特县'],
    '齐齐哈尔市': ['龙沙区', '建华区', '铁锋区', '昂昂溪区', '富拉尔基区', '碾子山区', '梅里斯区', '龙江县', '依安县', '泰来县', '甘南县', '富裕县', '克山县', '克东县', '拜泉县', '讷河市'],
  },
  '吉林省': {
    '长春市': ['南关区', '宽城区', '朝阳区', '二道区', '绿园区', '双阳区', '九台区', '农安县', '榆树市', '德惠市'],
    '吉林市': ['昌邑区', '龙潭区', '船营区', '丰满区', '永吉县', '蛟河市', '桦甸市', '舒兰市', '磐石市'],
  },
  '陕西省': {
    '西安市': ['新城区', '碑林区', '莲湖区', '灞桥区', '未央区', '雁塔区', '阎良区', '临潼区', '长安区', '高陵区', '鄠邑区', '蓝田县', '周至县'],
    '宝鸡市': ['渭滨区', '金台区', '陈仓区', '凤翔县', '岐山县', '扶风县', '眉县', '陇县', '千阳县', '麟游县', '凤县', '太白县'],
    '咸阳市': ['秦都区', '渭城区', '杨陵区', '三原县', '泾阳县', '乾县', '礼泉县', '永寿县', '长武县', '旬邑县', '淳化县', '武功县', '兴平市', '彬州市'],
  },
  '重庆': {'重庆市': ['万州区', '涪陵区', '渝中区', '大渡口区', '江北区', '沙坪坝区', '九龙坡区', '南岸区', '北碚区', '渝北区', '巴南区', '黔江区', '长寿区', '合川区', '永川区', '南川区', '璧山区', '铜梁区', '潼南区', '荣昌区', '开州区', '梁平区', '武隆区', '城口县', '丰都县', '垫江县', '忠县', '云阳县', '奉节县', '巫山县', '巫溪县', '石柱县', '秀山县', '酉阳县', '彭水县']},
  '天津': {'天津市': ['和平区', '河东区', '河西区', '南开区', '河北区', '红桥区', '东丽区', '西青区', '津南区', '北辰区', '武清区', '宝坻区', '滨海新区', '宁河区', '静海区', '蓟州区']},
  '香港': {'香港': ['中西区', '东区', '南区', '湾仔区', '东区', '九龙城区', '观塘区', '深水埗区', '黄大仙区', '油尖旺区', '北区', '大埔区', '沙田区', '西贡区', '荃湾区', '屯门区', '元朗区', '葵青区', '离岛区']},
  '澳门': {'澳门': ['花地玛堂区', '圣安多尼堂区', '大堂区', '望德堂区', '风顺堂区', '嘉模堂区', '圣方济各堂区']},
  '台湾': {
    '台北市': ['松山區', '信義區', '大安區', '中山區', '中正區', '大同區', '萬華區', '文山區', '南港區', '內湖區', '士林區', '北投區'],
    '新北市': ['板橋區', '三重區', '中和區', '永和區', '新莊區', '新店區', '土城區', '蘆洲區', '樹林區', '鶯歌區', '三峽區', '淡水區', '汐止區', '瑞芳區'],
    '高雄市': ['鹽埕區', '鼓山區', '左營區', '楠梓區', '三民區', '新興區', '前金區', '苓雅區', '前鎮區', '旗津區', '小港區', '鳳山區'],
  },
}


SUPPORTED_PAYMENT_METHODS = {'wxpay', 'alipay', 'balance', 'sandbox'}


def normalize_payment_method(value):
    method = str(value or 'wxpay').strip().lower()
    return method if method in SUPPORTED_PAYMENT_METHODS else 'wxpay'


def payment_mode():
    return getattr(settings, 'PAYMENT_PROVIDER_MODE', 'sandbox')


def complete_payment_transaction(payment, request):
    if payment.status == 'succeeded':
        return payment

    order = payment.order
    if order.status != 'pending':
        payment.status = 'failed'
        payment.failure_reason = '订单状态不可支付'
        payment.save(update_fields=['status', 'failure_reason', 'updated_at'])
        return payment

    order.status = 'paid'
    order.pay_time = timezone.now()
    order.save(update_fields=['status', 'pay_time'])

    payment.status = 'succeeded'
    payment.confirmed_at = order.pay_time
    payment.provider_transaction_id = payment.provider_transaction_id or f"LOCAL-{payment.id}"
    payment.save(update_fields=['status', 'confirmed_at', 'provider_transaction_id', 'updated_at'])

    vip, _ = VIPMembership.objects.get_or_create(user=payment.user)
    points = int(order.payment or 0)
    vip.points += points
    vip.growth_value += points
    vip.save()

    Notification.objects.create(
        user=payment.user,
        type='order',
        name='支付成功',
        time='刚刚',
        content=f'订单 {order.id} 已支付成功，商家将尽快发货。',
        action='查看订单'
    )
    return payment


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


def get_user(request):
    """获取当前登录用户，未登录抛出异常"""
    auth = request.headers.get('Authorization', '')
    if not auth.startswith('Token '):
        raise AuthenticationFailed('请先登录')
    try:
        key = auth[6:]
        token = Token.objects.get(key=key)
        return token.user
    except Token.DoesNotExist:
        raise AuthenticationFailed('无效的Token')


def cart_item_price(item):
    return item.sku.price if item.sku else item.product.price


def cart_item_original_price(item):
    if item.sku and item.sku.original_price:
        return item.sku.original_price
    return item.product.original_price or item.product.price


def cart_item_image(item):
    return item.sku.image if item.sku and item.sku.image else item.product.image


# ============ ViewSets ============
class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.filter(is_in_stock=True).select_related('image', 'subcategory__category')
    serializer_class = ProductListSerializer
    permission_classes = [AllowAny]

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return ProductDetailSerializer
        return ProductListSerializer

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True, context={'request': request})
        return Response({'code': 0, 'msg': 'success', 'data': serializer.data})

    def retrieve(self, request, *args, **kwargs):
        try:
            instance = self.get_object()
            serializer = self.get_serializer(instance)
            return Response({'code': 0, 'msg': 'success', 'data': serializer.data})
        except Product.DoesNotExist:
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
            user = request.user if request.user.is_authenticated else get_user(request)
            data = request.data.copy()
            is_anonymous = str(data.pop('is_anonymous', data.pop('isAnonymous', False))).lower() in ('1', 'true', 'yes')
            image_payloads = data.pop('images', data.pop('imageUrls', []))
            if not image_payloads:
                image_payloads = []
            if isinstance(image_payloads, str):
                image_payloads = [image_payloads]
            serializer = ReviewSerializer(data=data)
            if serializer.is_valid():
                review = serializer.save(
                    user=user,
                    product_id=pk,
                    user_name='匿名用户' if is_anonymous else user.username,
                    user_avatar=None
                )
                media_files = [
                    media
                    for media in (media_from_data_url(payload) for payload in image_payloads[:6])
                    if media is not None
                ]
                if media_files:
                    review.images.add(*media_files)
                stats = Review.objects.filter(product_id=pk).aggregate(avg=Avg('rating'))
                Product.objects.filter(id=pk).update(
                    review_count=Review.objects.filter(product_id=pk).count(),
                    rating=stats['avg'] or 0
                )
                return Response({'code': 0, 'msg': 'created', 'data': ReviewSerializer(review, context={'request': request}).data})
            return Response({'code': 400, 'msg': 'invalid request', 'data': serializer.errors})

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

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True, context={'request': request})
        return Response({'code': 0, 'msg': 'success', 'data': serializer.data})

    @action(detail=True, methods=['get'])
    def products(self, request, pk=None):
        subcategory = self.get_object()
        products = subcategory.products.filter(is_in_stock=True)
        return Response({'code': 0, 'msg': 'success', 'data': ProductListSerializer(products, many=True, context={'request': request}).data})


class CategoryViewSet(ResponseMixin, viewsets.ModelViewSet):
    queryset = Category.objects.filter(is_enabled=True)
    serializer_class = CategorySerializer
    permission_classes = [AllowAny]

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return CategoryWithSubcategoriesSerializer
        return CategorySerializer

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance, context={'request': request})
        return api_response(serializer.data)

    @action(detail=True, methods=['get'])
    def subcategories(self, request, pk=None):
        category = self.get_object()
        subcategories = category.subcategories.filter(is_enabled=True)
        return api_response(SubcategoryWithProductsSerializer(subcategories, many=True, context={'request': request}).data)

    @action(detail=True, methods=['get'])
    def products(self, request, pk=None):
        """获取一级分类下所有子分类的产品"""
        category = self.get_object()
        products = Product.objects.filter(subcategory__category=category, is_in_stock=True)
        return api_response(ProductListSerializer(products, many=True, context={'request': request}).data)

    @action(detail=True, methods=['get'])
    def all_products(self, request, pk=None):
        """获取一级分类下所有子分类的产品（兼容旧端点）"""
        category = self.get_object()
        products = Product.objects.filter(subcategory__category=category, is_in_stock=True)
        return api_response(ProductListSerializer(products, many=True, context={'request': request}).data)


_product_qs = Product.objects.select_related('image', 'subcategory__category')


class HomeBannerViewSet(viewsets.ModelViewSet):
    queryset = HomeBanner.objects.filter(is_enabled=True).select_related('image').prefetch_related(
        Prefetch('products', queryset=_product_qs)
    )
    serializer_class = HomeBannerSerializer
    permission_classes = [AllowAny]

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True, context={'request': request})
        return Response({'code': 0, 'msg': 'success', 'data': serializer.data})

    @action(detail=True, methods=['get'])
    def landing(self, request, pk=None):
        banner = self.get_object()
        serializer = HomeBannerLandingSerializer(banner, context={'request': request})
        return Response({'code': 0, 'msg': 'success', 'data': serializer.data})


class HomeFlashSaleViewSet(viewsets.ModelViewSet):
    queryset = HomeFlashSale.objects.filter(is_enabled=True).prefetch_related(
        Prefetch('products', queryset=_product_qs)
    )
    serializer_class = HomeFlashSaleSerializer
    permission_classes = [AllowAny]

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True, context={'request': request})
        return Response({'code': 0, 'msg': 'success', 'data': serializer.data})


class HomeHotRankViewSet(viewsets.ModelViewSet):
    queryset = HomeHotRank.objects.filter(is_enabled=True).prefetch_related(
        Prefetch('products', queryset=_product_qs)
    )
    serializer_class = HomeHotRankSerializer
    permission_classes = [AllowAny]

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True, context={'request': request})
        return Response({'code': 0, 'msg': 'success', 'data': serializer.data})


class HomeRecommendViewSet(viewsets.ModelViewSet):
    queryset = HomeRecommend.objects.filter(is_enabled=True).prefetch_related(
        Prefetch('products', queryset=_product_qs)
    )
    serializer_class = HomeRecommendSerializer
    permission_classes = [AllowAny]

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True, context={'request': request})
        return Response({'code': 0, 'msg': 'success', 'data': serializer.data})


class HomeNewArrivalViewSet(viewsets.ModelViewSet):
    queryset = HomeNewArrival.objects.filter(is_enabled=True).prefetch_related(
        Prefetch('products', queryset=_product_qs)
    )
    serializer_class = HomeNewArrivalSerializer
    permission_classes = [AllowAny]

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True, context={'request': request})
        return Response({'code': 0, 'msg': 'success', 'data': serializer.data})


class HomePromotionViewSet(viewsets.ModelViewSet):
    queryset = HomePromotion.objects.filter(is_enabled=True).select_related('image')
    serializer_class = HomePromotionSerializer
    permission_classes = [AllowAny]

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True, context={'request': request})
        return Response({'code': 0, 'msg': 'success', 'data': serializer.data})


class IsAdminProfile(BasePermission):
    def has_permission(self, request, view):
        user = request.user
        if not user or not user.is_authenticated:
            return False
        profile = getattr(user, 'profile', None)
        return user.is_staff or user.is_superuser or (profile and profile.user_type == 'admin')


def _money(value):
    if value in (None, ''):
        return Decimal('0')
    return Decimal(str(value))


def _bool_value(value, default=False):
    if value is None:
        return default
    if isinstance(value, bool):
        return value
    return str(value).strip().lower() in ('1', 'true', 'yes', 'on', 'enabled')


def _date_time(value):
    return value.strftime('%Y-%m-%d %H:%M') if value else ''


def _media_payload(media, request):
    return {
        'id': media.id,
        'url': get_image_url(media, context={'request': request}),
        'name': media.original_name or media.file.name,
        'mime_type': media.mime_type,
        'size': media.size,
        'uploaded_at': _date_time(media.uploaded_at),
    }


def _admin_product_payload(product, request):
    sku_stock = product.skus.aggregate(total=Sum('stock')).get('total')
    skus = product.skus.select_related('image').prefetch_related('spec_values__group').order_by('id')
    spec_groups = product.spec_groups.prefetch_related('values__image').order_by('sort_order', 'id')
    subcategory = product.subcategory
    category = subcategory.category if subcategory and subcategory.category else None
    return {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'price': str(product.price),
        'original_price': str(product.original_price or ''),
        'image': get_image_url(product.image, context={'request': request}),
        'image_id': product.image_id or '',
        'subcategory_id': product.subcategory_id or '',
        'subcategory_name': subcategory.name if subcategory else '',
        'category_id': category.id if category else '',
        'category_name': category.name if category else '',
        'rating': str(product.rating),
        'review_count': product.review_count,
        'sales_count': product.sales_count,
        'is_in_stock': product.is_in_stock,
        'tag': product.tag,
        'sku_count': product.skus.count(),
        'low_stock_count': product.skus.filter(stock__lte=5).count(),
        'stock_total': sku_stock if sku_stock is not None else (999 if product.is_in_stock else 0),
        'spec_groups': [_admin_spec_group_payload(group, request) for group in spec_groups],
        'skus': [_admin_sku_payload(sku, request) for sku in skus],
    }


def _admin_spec_group_payload(group, request):
    return {
        'id': group.id,
        'name': group.name,
        'sort_order': group.sort_order,
        'values': [_admin_spec_value_payload(value, request) for value in group.values.all().order_by('sort_order', 'id')],
    }


def _admin_spec_value_payload(value, request):
    return {
        'id': value.id,
        'value': value.value,
        'image': get_image_url(value.image, context={'request': request}),
        'image_id': value.image_id or '',
        'sort_order': value.sort_order,
    }


def _admin_sku_payload(sku, request):
    return {
        'id': sku.id,
        'price': str(sku.price),
        'original_price': str(sku.original_price or ''),
        'stock': sku.stock,
        'image': get_image_url(sku.image, context={'request': request}),
        'image_id': sku.image_id or '',
        'spec_text': sku_spec_text(sku),
        'spec_value_ids': list(sku.spec_values.values_list('id', flat=True)),
    }


def _admin_category_payload(category, request):
    return {
        'id': category.id,
        'name': category.name,
        'icon': get_image_url(category.icon, context={'request': request}),
        'icon_id': category.icon_id or '',
        'banner': get_image_url(category.banner, context={'request': request}),
        'banner_id': category.banner_id or '',
        'sort_order': category.sort_order,
        'is_enabled': category.is_enabled,
        'subcategory_count': category.subcategories.count(),
        'product_count': Product.objects.filter(subcategory__category=category).count(),
    }


def _admin_subcategory_payload(subcategory, request):
    return {
        'id': subcategory.id,
        'name': subcategory.name,
        'image': get_image_url(subcategory.icon, context={'request': request}),
        'icon_id': subcategory.icon_id or '',
        'category_id': subcategory.category_id,
        'category_name': subcategory.category.name if subcategory.category else '',
        'sort_order': subcategory.sort_order,
        'is_enabled': subcategory.is_enabled,
        'product_count': subcategory.products.count(),
    }


def _admin_banner_payload(banner, request):
    return {
        'id': banner.id,
        'tag': banner.tag,
        'title': banner.title,
        'action_title': banner.action_title,
        'link': banner.link,
        'landing_badge': banner.landing_badge,
        'landing_subtitle': banner.landing_subtitle,
        'landing_description': banner.landing_description,
        'gradient_type': banner.gradient_type,
        'sort_order': banner.sort_order,
        'is_enabled': banner.is_enabled,
        'image': get_image_url(banner.image, context={'request': request}),
        'image_id': banner.image_id or '',
        'product_ids': list(banner.products.values_list('id', flat=True)),
        'product_count': banner.products.count(),
    }


def _admin_order_payload(order, request):
    data = OrderSerializer(order, context={'request': request}).data
    data['user'] = {
        'id': order.user_id,
        'username': order.user.username,
        'email': order.user.email or '',
    }
    data['item_count'] = sum(item.quantity for item in order.products.all())
    data['created_display'] = _date_time(order.created_at)
    data['pay_display'] = _date_time(order.pay_time)
    data['shipped_display'] = _date_time(order.shipped_at)
    return data


def _admin_user_payload(user):
    profile = getattr(user, 'profile', None)
    vip = getattr(user, 'vip', None)
    return {
        'id': user.id,
        'username': user.username,
        'email': user.email or '',
        'is_active': user.is_active,
        'is_staff': user.is_staff,
        'user_type': profile.user_type if profile else 'user',
        'phone': profile.phone if profile else '',
        'gender': profile.gender if profile else 'secret',
        'points': (vip.points if vip else (profile.points if profile else 0)),
        'vip_level': vip.level if vip else 'none',
        'vip_level_name': VIP_LEVEL_NAMES.get(vip.level, '普通会员') if vip else '普通会员',
        'order_count': getattr(user, 'order_count', user.orders.count()),
        'total_spent': str(getattr(user, 'total_spent', None) or 0),
        'coupon_count': getattr(user, 'coupon_count', user.coupons.count()),
        'date_joined': _date_time(user.date_joined),
    }


def _admin_coupon_payload(coupon):
    return {
        'id': coupon.id,
        'user_id': coupon.user_id,
        'username': coupon.user.username,
        'name': coupon.name,
        'value': coupon.value,
        'threshold': coupon.threshold,
        'threshold_amount': str(coupon_threshold_amount(coupon)),
        'description': coupon.description,
        'time': coupon.time,
        'status': coupon.status,
    }


def _set_media(instance, field, value):
    if value is None:
        return
    media = MediaFile.objects.filter(id=value).first() if value else None
    setattr(instance, field, media)


@api_view(['GET'])
@permission_classes([IsAdminProfile])
def admin_overview(request):
    orders = Order.objects.all()
    paid_orders = orders.exclude(status='cancelled')
    revenue = paid_orders.aggregate(total=Sum('payment')).get('total') or Decimal('0')
    status_counts = {row['status']: row['count'] for row in orders.values('status').annotate(count=Count('id'))}
    recent_orders = orders.select_related('user').prefetch_related('products__image').order_by('-created_at')[:6]
    top_products = Product.objects.select_related('image', 'subcategory__category').order_by('-sales_count')[:6]
    return api_response({
        'metrics': {
            'revenue': str(revenue),
            'orders': orders.count(),
            'pending_orders': status_counts.get('pending', 0),
            'paid_orders': status_counts.get('paid', 0),
            'after_sale_orders': orders.exclude(after_sale_status='none').count(),
            'products': Product.objects.count(),
            'active_products': Product.objects.filter(is_in_stock=True).count(),
            'users': User.objects.count(),
            'coupons': UserCoupon.objects.count(),
        },
        'order_status': status_counts,
        'recent_orders': [_admin_order_payload(order, request) for order in recent_orders],
        'top_products': [_admin_product_payload(product, request) for product in top_products],
    })


class AdminMediaViewSet(viewsets.ViewSet):
    permission_classes = [IsAdminProfile]

    def list(self, request):
        items = MediaFile.objects.all()[:80]
        return api_response([_media_payload(item, request) for item in items])

    def create(self, request):
        data_url = request.data.get('file')
        media = media_from_data_url(data_url, original_prefix=request.data.get('name') or 'admin-upload')
        if not media:
            return api_response(msg='图片格式无效', code=400)
        return api_response(_media_payload(media, request), msg='uploaded')


class AdminProductViewSet(viewsets.ViewSet):
    permission_classes = [IsAdminProfile]

    def get_queryset(self):
        qs = Product.objects.select_related('image', 'subcategory__category').prefetch_related(
            'skus__spec_values__group',
            'skus__image',
            'spec_groups__values__image',
        )
        q = (self.request.GET.get('q') or '').strip()
        status = self.request.GET.get('status')
        category_id = self.request.GET.get('category')
        if q:
            qs = qs.filter(Q(name__icontains=q) | Q(description__icontains=q) | Q(tag__icontains=q))
        if status == 'active':
            qs = qs.filter(is_in_stock=True)
        elif status == 'inactive':
            qs = qs.filter(is_in_stock=False)
        if category_id:
            qs = qs.filter(subcategory__category_id=category_id)
        return qs.order_by('-sales_count', 'name')

    def list(self, request):
        products = self.get_queryset()
        return api_response({
            'items': [_admin_product_payload(product, request) for product in products],
            'total': products.count(),
        })

    def retrieve(self, request, pk=None):
        product = Product.objects.select_related('image', 'subcategory__category').prefetch_related('skus').get(pk=pk)
        return api_response(_admin_product_payload(product, request))

    def create(self, request):
        name = str(request.data.get('name') or '').strip()
        if not name:
            return api_response(msg='商品名称不能为空', code=400)
        with transaction.atomic():
            product = Product(name=name, price=_money(request.data.get('price') or '0'))
            self._apply_product_data(product, request.data)
            product.save()
            self._sync_product_specs_and_skus(product, request.data)
        return api_response(_admin_product_payload(product, request), msg='created')

    def partial_update(self, request, pk=None):
        with transaction.atomic():
            product = Product.objects.get(pk=pk)
            self._apply_product_data(product, request.data)
            product.save()
            self._sync_product_specs_and_skus(product, request.data)
        return api_response(_admin_product_payload(product, request), msg='updated')

    def destroy(self, request, pk=None):
        product = Product.objects.get(pk=pk)
        product.is_in_stock = False
        product.save(update_fields=['is_in_stock'])
        return api_response(_admin_product_payload(product, request), msg='off shelf')

    @action(detail=True, methods=['post'])
    def toggle(self, request, pk=None):
        product = Product.objects.get(pk=pk)
        product.is_in_stock = not product.is_in_stock
        product.save(update_fields=['is_in_stock'])
        return api_response(_admin_product_payload(product, request), msg='updated')

    @action(detail=False, methods=['post'], url_path='bulk-status')
    def bulk_status(self, request):
        ids = request.data.get('ids') or []
        if isinstance(ids, str):
            ids = [item.strip() for item in ids.split(',') if item.strip()]
        if not ids:
            return api_response(msg='请选择商品', code=400)
        is_in_stock = _bool_value(request.data.get('is_in_stock'), True)
        updated = Product.objects.filter(id__in=ids).update(is_in_stock=is_in_stock)
        return api_response({'updated': updated}, msg='updated')

    def _apply_product_data(self, product, data):
        for field in ['name', 'description', 'tag']:
            if field in data:
                setattr(product, field, str(data.get(field) or '').strip())
        for field in ['price', 'original_price', 'rating']:
            if field in data:
                value = data.get(field)
                setattr(product, field, None if value == '' and field == 'original_price' else _money(value))
        for field in ['review_count', 'sales_count']:
            if field in data:
                setattr(product, field, int(data.get(field) or 0))
        if 'is_in_stock' in data:
            product.is_in_stock = _bool_value(data.get('is_in_stock'), product.is_in_stock)
        if 'subcategory_id' in data:
            product.subcategory = Subcategory.objects.filter(id=data.get('subcategory_id')).first() if data.get('subcategory_id') else None
        if 'image_id' in data:
            _set_media(product, 'image', data.get('image_id'))

    def _sync_product_specs_and_skus(self, product, data):
        value_id_map = {}
        if 'spec_groups' in data:
            value_id_map = self._sync_product_specs(product, data.get('spec_groups') or [])
        if 'skus' in data:
            self._sync_product_skus(product, data.get('skus') or [], value_id_map)

    def _sync_product_specs(self, product, groups_payload):
        kept_group_ids = []
        value_id_map = {}

        for group_index, group_payload in enumerate(groups_payload):
            name = str(group_payload.get('name') or '').strip()
            if not name:
                continue

            group_id = group_payload.get('id')
            group = SpecGroup.objects.filter(id=group_id, product=product).first() if group_id else None
            if not group:
                group = SpecGroup(product=product)
            group.name = name
            group.sort_order = int(group_payload.get('sort_order') if group_payload.get('sort_order') not in (None, '') else group_index)
            group.save()
            kept_group_ids.append(group.id)

            kept_value_ids = []
            for value_index, value_payload in enumerate(group_payload.get('values') or []):
                text = str(value_payload.get('value') or '').strip()
                if not text:
                    continue

                incoming_id = str(value_payload.get('id') or value_payload.get('client_id') or '').strip()
                value = SpecValue.objects.filter(id=incoming_id, group=group).first() if incoming_id else None
                if not value:
                    value = SpecValue(group=group)
                value.value = text
                value.sort_order = int(value_payload.get('sort_order') if value_payload.get('sort_order') not in (None, '') else value_index)
                if 'image_id' in value_payload:
                    _set_media(value, 'image', value_payload.get('image_id'))
                value.save()
                kept_value_ids.append(value.id)

                if incoming_id:
                    value_id_map[incoming_id] = value.id
                client_id = str(value_payload.get('client_id') or '').strip()
                if client_id:
                    value_id_map[client_id] = value.id

            group.values.exclude(id__in=kept_value_ids).delete()

        product.spec_groups.exclude(id__in=kept_group_ids).delete()
        return value_id_map

    def _sync_product_skus(self, product, skus_payload, value_id_map):
        valid_value_ids = set(product.spec_groups.values_list('values__id', flat=True))
        kept_sku_ids = []

        for sku_payload in skus_payload:
            raw_ids = sku_payload.get('spec_value_ids') or []
            if isinstance(raw_ids, str):
                raw_ids = [item.strip() for item in raw_ids.split(',') if item.strip()]
            spec_value_ids = [
                value_id_map.get(str(value_id), str(value_id))
                for value_id in raw_ids
            ]
            spec_value_ids = [value_id for value_id in spec_value_ids if value_id in valid_value_ids]

            sku_id = sku_payload.get('id')
            sku = SKU.objects.filter(id=sku_id, product=product).first() if sku_id else None
            if not sku:
                sku = SKU(product=product)
            sku.price = _money(sku_payload.get('price') or product.price)
            original_price = sku_payload.get('original_price')
            sku.original_price = None if original_price in (None, '') else _money(original_price)
            sku.stock = max(0, int(sku_payload.get('stock') or 0))
            if 'image_id' in sku_payload:
                _set_media(sku, 'image', sku_payload.get('image_id'))
            sku.save()
            sku.spec_values.set(SpecValue.objects.filter(id__in=spec_value_ids, group__product=product))
            kept_sku_ids.append(sku.id)

        product.skus.exclude(id__in=kept_sku_ids).delete()


class AdminCategoryViewSet(viewsets.ViewSet):
    permission_classes = [IsAdminProfile]

    def list(self, request):
        categories = Category.objects.select_related('icon', 'banner').prefetch_related('subcategories').order_by('sort_order', 'name')
        return api_response([_admin_category_payload(category, request) for category in categories])

    def create(self, request):
        name = str(request.data.get('name') or '').strip()
        if not name:
            return api_response(msg='分类名称不能为空', code=400)
        category = Category.objects.create(
            name=name,
            sort_order=int(request.data.get('sort_order') or 0),
            is_enabled=_bool_value(request.data.get('is_enabled'), True),
        )
        _set_media(category, 'icon', request.data.get('icon_id'))
        _set_media(category, 'banner', request.data.get('banner_id'))
        category.save()
        return api_response(_admin_category_payload(category, request), msg='created')

    def partial_update(self, request, pk=None):
        category = Category.objects.get(pk=pk)
        if 'name' in request.data:
            category.name = str(request.data.get('name') or '').strip()
        if 'sort_order' in request.data:
            category.sort_order = int(request.data.get('sort_order') or 0)
        if 'is_enabled' in request.data:
            category.is_enabled = _bool_value(request.data.get('is_enabled'), category.is_enabled)
        if 'icon_id' in request.data:
            _set_media(category, 'icon', request.data.get('icon_id'))
        if 'banner_id' in request.data:
            _set_media(category, 'banner', request.data.get('banner_id'))
        category.save()
        return api_response(_admin_category_payload(category, request), msg='updated')

    def destroy(self, request, pk=None):
        category = Category.objects.get(pk=pk)
        category.is_enabled = False
        category.save(update_fields=['is_enabled'])
        return api_response(_admin_category_payload(category, request), msg='disabled')


class AdminSubcategoryViewSet(viewsets.ViewSet):
    permission_classes = [IsAdminProfile]

    def list(self, request):
        qs = Subcategory.objects.select_related('category', 'icon').order_by('category__sort_order', 'sort_order', 'name')
        category_id = request.GET.get('category')
        if category_id:
            qs = qs.filter(category_id=category_id)
        return api_response([_admin_subcategory_payload(item, request) for item in qs])

    def create(self, request):
        name = str(request.data.get('name') or '').strip()
        category_id = request.data.get('category_id')
        category = Category.objects.filter(id=category_id).first()
        if not name or not category:
            return api_response(msg='子分类名称和所属分类不能为空', code=400)
        subcategory = Subcategory.objects.create(
            name=name,
            category=category,
            sort_order=int(request.data.get('sort_order') or 0),
            is_enabled=_bool_value(request.data.get('is_enabled'), True),
        )
        _set_media(subcategory, 'icon', request.data.get('icon_id'))
        subcategory.save()
        return api_response(_admin_subcategory_payload(subcategory, request), msg='created')

    def partial_update(self, request, pk=None):
        subcategory = Subcategory.objects.get(pk=pk)
        if 'name' in request.data:
            subcategory.name = str(request.data.get('name') or '').strip()
        if 'category_id' in request.data:
            category = Category.objects.filter(id=request.data.get('category_id')).first()
            if category:
                subcategory.category = category
        if 'sort_order' in request.data:
            subcategory.sort_order = int(request.data.get('sort_order') or 0)
        if 'is_enabled' in request.data:
            subcategory.is_enabled = _bool_value(request.data.get('is_enabled'), subcategory.is_enabled)
        if 'icon_id' in request.data:
            _set_media(subcategory, 'icon', request.data.get('icon_id'))
        subcategory.save()
        return api_response(_admin_subcategory_payload(subcategory, request), msg='updated')

    def destroy(self, request, pk=None):
        subcategory = Subcategory.objects.get(pk=pk)
        subcategory.is_enabled = False
        subcategory.save(update_fields=['is_enabled'])
        return api_response(_admin_subcategory_payload(subcategory, request), msg='disabled')


class AdminBannerViewSet(viewsets.ViewSet):
    permission_classes = [IsAdminProfile]

    def list(self, request):
        banners = HomeBanner.objects.select_related('image').prefetch_related('products').order_by('sort_order', 'id')
        return api_response([_admin_banner_payload(banner, request) for banner in banners])

    def create(self, request):
        banner = HomeBanner()
        self._apply_banner_data(banner, request.data)
        banner.save()
        self._sync_banner_products(banner, request.data)
        return api_response(_admin_banner_payload(banner, request), msg='created')

    def partial_update(self, request, pk=None):
        banner = HomeBanner.objects.get(pk=pk)
        self._apply_banner_data(banner, request.data)
        banner.save()
        self._sync_banner_products(banner, request.data)
        return api_response(_admin_banner_payload(banner, request), msg='updated')

    def destroy(self, request, pk=None):
        banner = HomeBanner.objects.get(pk=pk)
        banner.is_enabled = False
        banner.save(update_fields=['is_enabled'])
        return api_response(_admin_banner_payload(banner, request), msg='disabled')

    def _apply_banner_data(self, banner, data):
        for field in ['tag', 'title', 'action_title', 'link', 'landing_badge', 'landing_subtitle', 'landing_description']:
            if field in data:
                setattr(banner, field, str(data.get(field) or '').strip())
        if 'gradient_type' in data:
            banner.gradient_type = int(data.get('gradient_type') or 0)
        if 'sort_order' in data:
            banner.sort_order = int(data.get('sort_order') or 0)
        if 'is_enabled' in data:
            banner.is_enabled = _bool_value(data.get('is_enabled'), banner.is_enabled)
        if 'image_id' in data:
            _set_media(banner, 'image', data.get('image_id'))

    def _sync_banner_products(self, banner, data):
        if 'product_ids' not in data:
            return
        ids = data.get('product_ids') or []
        if isinstance(ids, str):
            ids = [item.strip() for item in ids.split(',') if item.strip()]
        banner.products.set(Product.objects.filter(id__in=ids))


class AdminOrderViewSet(viewsets.ViewSet):
    permission_classes = [IsAdminProfile]

    def get_queryset(self):
        qs = Order.objects.select_related('user').prefetch_related('products__image', 'payment_transactions')
        q = (self.request.GET.get('q') or '').strip()
        status = self.request.GET.get('status')
        if q:
            qs = qs.filter(Q(id__icontains=q) | Q(user__username__icontains=q) | Q(address_phone__icontains=q))
        if status == 'after_sale':
            qs = qs.exclude(after_sale_status='none')
        elif status:
            qs = qs.filter(status=status)
        return qs.order_by('-created_at')

    def list(self, request):
        orders = self.get_queryset()
        return api_response({
            'items': [_admin_order_payload(order, request) for order in orders],
            'total': orders.count(),
        })

    def retrieve(self, request, pk=None):
        order = Order.objects.select_related('user').prefetch_related('products__image', 'payment_transactions').get(pk=pk)
        return api_response(_admin_order_payload(order, request))

    @action(detail=True, methods=['post'], url_path='mark-paid')
    def mark_paid(self, request, pk=None):
        order = Order.objects.select_related('user').get(pk=pk)
        if order.status != 'pending':
            return api_response(msg='只有待付款订单可以标记为已支付', code=400)
        order.status = 'paid'
        order.pay_time = timezone.now()
        order.payment = order.payment or order.total_amount
        order.save(update_fields=['status', 'pay_time', 'payment'])
        Notification.objects.create(
            user=order.user,
            type='order',
            name='订单已支付',
            time='刚刚',
            content=f'订单 {order.id} 已支付，商家正在准备商品。',
            action='查看订单'
        )
        return api_response(_admin_order_payload(order, request), msg='paid')

    @action(detail=True, methods=['post'])
    def ship(self, request, pk=None):
        order = Order.objects.select_related('user').get(pk=pk)
        if order.status != 'paid':
            return api_response(msg='只有待发货订单可以发货', code=400)
        now = timezone.now()
        order.status = 'shipped'
        order.shipped_at = now
        order.carrier = request.data.get('carrier') or '顺丰速运'
        order.tracking_number = request.data.get('tracking_number') or request.data.get('trackingNumber') or f"SF{now.strftime('%Y%m%d%H%M%S')}{order.id[-4:]}"
        order.save(update_fields=['status', 'shipped_at', 'carrier', 'tracking_number'])
        Notification.objects.create(
            user=order.user,
            type='logistics',
            name='订单已发货',
            time='刚刚',
            content=f'订单 {order.id} 已由 {order.carrier} 发出，运单号 {order.tracking_number}。',
            action='查看物流'
        )
        return api_response(_admin_order_payload(order, request), msg='shipped')

    @action(detail=True, methods=['post'], url_path='set-status')
    def set_status(self, request, pk=None):
        order = Order.objects.select_related('user').get(pk=pk)
        status = request.data.get('status')
        valid_statuses = [value for value, _ in Order.STATUS_CHOICES]
        if status not in valid_statuses:
            return api_response(msg='订单状态无效', code=400)
        order.status = status
        if status == 'paid' and not order.pay_time:
            order.pay_time = timezone.now()
        if status == 'completed' and not order.shipped_at:
            order.shipped_at = timezone.now()
        order.save()
        return api_response(_admin_order_payload(order, request), msg='updated')

    @action(detail=True, methods=['post'], url_path='after-sale')
    def after_sale(self, request, pk=None):
        order = Order.objects.select_related('user').get(pk=pk)
        status = request.data.get('after_sale_status')
        valid = ['none', 'requested', 'processing', 'refunded', 'rejected']
        if status not in valid:
            return api_response(msg='售后状态无效', code=400)
        order.after_sale_status = status
        if 'after_sale_reason' in request.data:
            order.after_sale_reason = str(request.data.get('after_sale_reason') or '').strip()
        if status != 'none' and not order.after_sale_applied_at:
            order.after_sale_applied_at = timezone.now()
        order.save(update_fields=['after_sale_status', 'after_sale_reason', 'after_sale_applied_at'])
        return api_response(_admin_order_payload(order, request), msg='updated')


class AdminUserViewSet(viewsets.ViewSet):
    permission_classes = [IsAdminProfile]

    def get_queryset(self):
        qs = User.objects.select_related('profile', 'vip').annotate(
            order_count=Count('orders', distinct=True),
            total_spent=Sum('orders__payment'),
            coupon_count=Count('coupons', distinct=True),
        )
        q = (self.request.GET.get('q') or '').strip()
        user_type = self.request.GET.get('type')
        if q:
            qs = qs.filter(Q(username__icontains=q) | Q(email__icontains=q) | Q(profile__phone__icontains=q))
        if user_type:
            qs = qs.filter(profile__user_type=user_type)
        return qs.order_by('-date_joined')

    def list(self, request):
        users = self.get_queryset()
        return api_response({
            'items': [_admin_user_payload(user) for user in users],
            'total': users.count(),
        })

    def partial_update(self, request, pk=None):
        user = User.objects.get(pk=pk)
        profile, _ = UserProfile.objects.get_or_create(user=user)
        vip, _ = VIPMembership.objects.get_or_create(user=user)
        if 'email' in request.data:
            user.email = str(request.data.get('email') or '').strip()
        if 'is_active' in request.data:
            user.is_active = _bool_value(request.data.get('is_active'), user.is_active)
        if 'phone' in request.data:
            profile.phone = str(request.data.get('phone') or '').strip()
        if 'gender' in request.data and request.data.get('gender') in GENDER_INPUT_MAP:
            profile.gender = GENDER_INPUT_MAP.get(request.data.get('gender'))
        if 'vip_level' in request.data and request.data.get('vip_level') in VIP_LEVEL_ORDER:
            vip.level = request.data.get('vip_level')
        if 'points' in request.data:
            vip.points = int(request.data.get('points') or 0)
            profile.points = vip.points
        user.save()
        profile.save()
        vip.save()
        return api_response(_admin_user_payload(user), msg='updated')


class AdminCouponViewSet(viewsets.ViewSet):
    permission_classes = [IsAdminProfile]

    def list(self, request):
        coupons = UserCoupon.objects.select_related('user').order_by('-id')
        status = request.GET.get('status')
        q = (request.GET.get('q') or '').strip()
        if status:
            coupons = coupons.filter(status=status)
        if q:
            coupons = coupons.filter(Q(name__icontains=q) | Q(user__username__icontains=q))
        return api_response({
            'items': [_admin_coupon_payload(coupon) for coupon in coupons],
            'total': coupons.count(),
        })

    def create(self, request):
        user_id = request.data.get('user_id')
        username = request.data.get('username')
        user = User.objects.filter(id=user_id).first() if user_id else User.objects.filter(username=username).first()
        if not user:
            return api_response(msg='用户不存在', code=400)
        coupon = UserCoupon.objects.create(
            user=user,
            name=str(request.data.get('name') or '专属优惠券').strip(),
            value=int(request.data.get('value') or 0),
            threshold=str(request.data.get('threshold') or '无门槛').strip(),
            description=str(request.data.get('description') or '').strip(),
            time=str(request.data.get('time') or '').strip(),
            status=request.data.get('status') or 'available',
        )
        Notification.objects.create(
            user=user,
            type='promo',
            name='获得优惠券',
            time='刚刚',
            content=f'你获得了 {coupon.name}，可在结算时使用。',
            action='去使用'
        )
        return api_response(_admin_coupon_payload(coupon), msg='created')

    def partial_update(self, request, pk=None):
        coupon = UserCoupon.objects.select_related('user').get(pk=pk)
        for field in ['name', 'threshold', 'description', 'time', 'status']:
            if field in request.data:
                setattr(coupon, field, str(request.data.get(field) or '').strip())
        if 'value' in request.data:
            coupon.value = int(request.data.get('value') or 0)
        coupon.save()
        return api_response(_admin_coupon_payload(coupon), msg='updated')


class AdminShopViewSet(viewsets.ViewSet):
    permission_classes = [IsAdminProfile]

    def list(self, request):
        info, _ = ShopInfo.objects.get_or_create(pk=1)
        return api_response(ShopInfoSerializer(info).data)

    @action(detail=False, methods=['patch'])
    def save(self, request):
        info, _ = ShopInfo.objects.get_or_create(pk=1)
        for field in ['name', 'description', 'sales', 'fans_count']:
            if field in request.data:
                setattr(info, field, str(request.data.get(field) or '').strip())
        if 'score' in request.data:
            info.score = _money(request.data.get('score'))
        if 'product_count' in request.data:
            info.product_count = int(request.data.get('product_count') or 0)
        info.save()
        return api_response(ShopInfoSerializer(info).data, msg='updated')


class CartViewSet(viewsets.ModelViewSet):
    serializer_class = CartItemSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'post', 'put', 'patch', 'delete']

    def get_queryset(self):
        return CartItem.objects.filter(user=self.request.user).select_related(
            'product__image', 'product__subcategory__category', 'sku__image'
        ).prefetch_related('sku__spec_values__group')

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = CartItemSerializer(queryset, many=True, context={'request': request})
        items = serializer.data
        total = sum(
            float(cart_item_price(item)) * item.quantity
            for item in queryset if item.is_selected
        )
        return Response({'code': 0, 'msg': 'success', 'data': {'items': items, 'total': total}})

    def create(self, request):
        user = request.user
        product_id = request.data.get('productId')
        sku_id = request.data.get('skuId') or request.data.get('sku_id') or None
        try:
            quantity = int(request.data.get('quantity', 1))
        except (TypeError, ValueError):
            return api_response(msg='invalid quantity', code=400)
        if quantity < 1:
            return api_response(msg='invalid quantity', code=400)

        try:
            product = Product.objects.get(id=product_id)
        except Product.DoesNotExist:
            return api_response(msg='商品不存在', code=404)

        sku = None
        if sku_id:
            try:
                sku = SKU.objects.get(id=sku_id, product=product)
            except SKU.DoesNotExist:
                return api_response(msg='规格不存在', code=404)
        elif product.skus.exists():
            sku = product.skus.order_by('id').first()

        if sku and sku.stock <= 0:
            return api_response(msg='库存不足', code=400)

        item, created = CartItem.objects.get_or_create(
            user=user,
            product=product,
            sku=sku,
            defaults={'quantity': quantity, 'is_selected': True}
        )
        if not created:
            item.quantity += quantity
            item.is_selected = True
            item.save()
        return api_response(CartItemSerializer(item, context={'request': request}).data, msg='added to cart')

    def update(self, request, pk=None):
        item = self.get_object()
        try:
            quantity = int(request.data.get('quantity', item.quantity))
        except (TypeError, ValueError):
            return api_response(msg='invalid quantity', code=400)
        if quantity < 1:
            return api_response(msg='invalid quantity', code=400)
        item.quantity = quantity
        item.save()
        return api_response(CartItemSerializer(item, context={'request': request}).data)

    def partial_update(self, request, pk=None):
        return self.update(request, pk=pk)

    @action(detail=True, methods=['patch'])
    def toggle(self, request, pk=None):
        item = self.get_object()
        item.is_selected = not item.is_selected
        item.save()
        return Response({'code': 0, 'msg': 'toggled'})

    @action(detail=False, methods=['put'])
    def select_all(self, request):
        selected = request.GET.get('selected', 'true') == 'true'
        CartItem.objects.filter(user=request.user).update(is_selected=selected)
        return Response({'code': 0, 'msg': 'success'})

    @action(detail=False, methods=['put'], url_path='select-all')
    def select_all_hyphen(self, request):
        return self.select_all(request)

    def destroy(self, request, pk=None):
        item = self.get_object()
        item.delete()
        return Response({'code': 0, 'msg': 'removed'})

    @action(detail=False, methods=['delete'])
    def clear(self, request):
        CartItem.objects.filter(user=request.user).delete()
        return Response({'code': 0, 'msg': 'cleared'})


class OrderViewSet(ResponseMixin, viewsets.ModelViewSet):
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'post', 'put', 'delete']

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance, context={'request': request})
        return api_response(serializer.data)

    def get_queryset(self):
        qs = Order.objects.filter(user=self.request.user).prefetch_related('products__image')
        status = self.request.GET.get('status')
        if status == 'refund':
            qs = qs.exclude(after_sale_status='none')
        elif status:
            qs = qs.filter(status=status)
        return qs.order_by('-created_at')

    def create(self, request):
        user = request.user
        cart_item_ids = request.data.get('cartItemIds', [])
        address_id = request.data.get('addressId')
        coupon_id = request.data.get('couponId')
        remark = request.data.get('remark', '')

        # 获取地址副本
        address = None
        if address_id:
            try:
                address = Address.objects.get(id=address_id, user=user)
            except Address.DoesNotExist:
                pass

        total = Decimal('0')
        order_items = []
        for cid in cart_item_ids:
            try:
                item = CartItem.objects.select_related(
                    'product__image', 'sku__image'
                ).prefetch_related('sku__spec_values__group').get(id=cid, user=user)
                unit_price = cart_item_price(item)
                total += unit_price * item.quantity
                order_items.append({
                    'product_id': item.product_id,
                    'name': item.product.name,
                    'spec': sku_spec_text(item.sku),
                    'price': unit_price,
                    'quantity': item.quantity,
                    'image': cart_item_image(item),
                })
            except CartItem.DoesNotExist:
                pass

        if not order_items:
            return Response({'code': 400, 'msg': '购物车为空'})

        freight = Decimal('0') if total >= Decimal('99') else Decimal('10')
        discount = Decimal('0')
        coupon = None
        if coupon_id:
            try:
                coupon = UserCoupon.objects.get(id=coupon_id, user=user, status='available')
                threshold = coupon_threshold_amount(coupon)
                if total >= threshold:
                    discount = Decimal(str(coupon.value))
                else:
                    coupon = None
            except UserCoupon.DoesNotExist:
                pass

        payment = max(Decimal('0'), total + freight - discount)

        order = Order.objects.create(
            user=user,
            id=f"ORH5{datetime.now().strftime('%Y%m%d%H%M%S%f')[:20]}",
            store='潮流优品官方旗舰店',
            status='pending',
            total_amount=total,
            payment=payment,
            freight=freight,
            discount=discount,
            address_name=address.name if address else '',
            address_phone=address.phone if address else '',
            address_province=address.province if address else '',
            address_city=address.city if address else '',
            address_district=address.district if address else '',
            address_detail=address.detail if address else '',
        )
        for item in order_items:
            OrderProduct.objects.create(order=order, **item)
        CartItem.objects.filter(id__in=cart_item_ids, user=user).delete()
        if coupon and discount > 0:
            coupon.status = 'used'
            coupon.save(update_fields=['status'])
        Notification.objects.create(
            user=user,
            type='order',
            name='订单已提交',
            time='刚刚',
            content=f'订单 {order.id} 已生成，请在支付页完成付款。',
            action='去支付'
        )
        return Response({'code': 0, 'msg': 'order created', 'data': OrderSerializer(order, context={'request': request}).data})

    @action(detail=False, methods=['post'])
    def preview(self, request):
        """预订单接口 - 不入库，只返回预览数据"""
        user = request.user
        cart_item_ids = request.data.get('cartItemIds', [])
        address_id = request.data.get('addressId')
        coupon_id = request.data.get('couponId')

        items = []
        total = 0
        for cid in cart_item_ids:
            try:
                item = CartItem.objects.select_related(
                    'product__image', 'sku__image'
                ).prefetch_related('sku__spec_values__group').get(id=cid, user=user)
                unit_price = cart_item_price(item)
                item_total = float(unit_price) * item.quantity
                total += item_total
                items.append({
                    'cartId': str(item.id),
                    'productId': str(item.product.id),
                    'name': item.product.name,
                    'skuId': str(item.sku_id or ''),
                    'spec': sku_spec_text(item.sku),
                    'price': float(unit_price),
                    'originalPrice': float(cart_item_original_price(item)),
                    'quantity': item.quantity,
                    'image': get_image_url(cart_item_image(item), context={'request': request}),
                })
            except CartItem.DoesNotExist:
                pass

        freight = 0 if total >= 99 else 10
        discount = 0
        if coupon_id:
            try:
                coupon = UserCoupon.objects.get(id=coupon_id, user=user, status='available')
                threshold = float(coupon_threshold_amount(coupon))
                if total >= threshold:
                    discount = float(coupon.value)
            except UserCoupon.DoesNotExist:
                pass
        payment = max(0, total + freight - discount)

        return Response({
            'code': 0,
            'msg': 'success',
            'data': {
                'items': items,
                'subtotal': total,
                'freight': freight,
                'discount': discount,
                'total': total + freight,
                'payment': payment,
                'store': '官方旗舰店',
            }
        })

    @action(detail=True, methods=['put'])
    def cancel(self, request, pk=None):
        order = self.get_object()
        if order.status == 'pending':
            order.status = 'cancelled'
            order.save()
            Notification.objects.create(
                user=request.user,
                type='order',
                name='订单已取消',
                time='刚刚',
                content=f'订单 {order.id} 已取消，未支付款项不会扣除。',
                action='查看订单'
            )
        return api_response(OrderSerializer(order, context={'request': request}).data, msg='order cancelled')

    @action(detail=True, methods=['put'])
    def pay(self, request, pk=None):
        order = self.get_object()
        if order.status != 'pending':
            return api_response(msg='订单状态不可支付', code=400)
        method = normalize_payment_method(
            request.data.get('paymentMethod')
            or request.data.get('payment_method')
            or request.data.get('provider')
        )
        active_payment = order.payment_transactions.filter(
            user=request.user,
            provider=method,
            status__in=['created', 'requires_action', 'processing'],
        ).first()
        if active_payment:
            payment = active_payment
        else:
            mode = payment_mode()
            payment = PaymentTransaction.objects.create(
                user=request.user,
                order=order,
                provider=method,
                amount=order.payment or Decimal('0'),
                status='requires_action',
                provider_payload={
                    'mode': mode,
                    'display_method': dict(PaymentTransaction.PROVIDER_CHOICES).get(method, method),
                },
            )

        if request.data.get('autoConfirm') is True:
            payment = complete_payment_transaction(payment, request)

        return api_response(
            PaymentTransactionSerializer(payment, context={'request': request}).data,
            msg='payment session created'
        )

    @action(detail=True, methods=['put'])
    def ship(self, request, pk=None):
        order = self.get_object()
        if order.status != 'paid':
            return api_response(msg='只有待发货订单可以发货', code=400)
        now = timezone.now()
        tracking_number = (
            request.data.get('trackingNumber')
            or request.data.get('tracking_number')
            or f"SF{now.strftime('%Y%m%d%H%M%S')}{order.id[-4:]}"
        )
        order.status = 'shipped'
        order.shipped_at = now
        order.carrier = request.data.get('carrier') or '顺丰速运'
        order.tracking_number = tracking_number
        order.save(update_fields=['status', 'shipped_at', 'carrier', 'tracking_number'])
        Notification.objects.create(
            user=request.user,
            type='logistics',
            name='订单已发货',
            time='刚刚',
            content=f'订单 {order.id} 已由 {order.carrier} 发出，运单号 {order.tracking_number}。',
            action='查看物流'
        )
        return api_response(OrderSerializer(order, context={'request': request}).data, msg='shipped')

    @action(detail=True, methods=['get'])
    def logistics(self, request, pk=None):
        order = self.get_object()
        data = OrderSerializer(order, context={'request': request}).data
        return api_response({
            'carrier': data.get('carrier') or '',
            'tracking_number': data.get('tracking_number') or '',
            'items': data.get('logistics') or [],
        })

    @action(detail=True, methods=['put'])
    def confirm(self, request, pk=None):
        order = self.get_object()
        if order.status != 'shipped':
            return api_response(msg='只有待收货订单可以确认收货', code=400)
        order.status = 'completed'
        order.save(update_fields=['status'])
        Notification.objects.create(
            user=request.user,
            type='logistics',
            name='确认收货',
            time='刚刚',
            content=f'订单 {order.id} 已完成，欢迎评价本次购物体验。',
            action='去评价'
        )
        return api_response(OrderSerializer(order, context={'request': request}).data, msg='confirmed')

    @action(detail=True, methods=['post'], url_path='after-sale')
    def after_sale(self, request, pk=None):
        order = self.get_object()
        if order.status not in ('shipped', 'completed'):
            return api_response(msg='当前订单状态不可申请售后', code=400)
        reason = str(request.data.get('reason') or '').strip()
        if not reason:
            return api_response(msg='请填写售后原因', code=400)
        order.after_sale_status = 'requested'
        order.after_sale_reason = reason
        order.after_sale_applied_at = timezone.now()
        order.save(update_fields=['after_sale_status', 'after_sale_reason', 'after_sale_applied_at'])
        Notification.objects.create(
            user=request.user,
            type='order',
            name='售后申请已提交',
            time='刚刚',
            content=f'订单 {order.id} 的售后申请已提交，客服将尽快处理。',
            action='查看订单'
        )
        return api_response(OrderSerializer(order, context={'request': request}).data, msg='after sale requested')

    @action(detail=True, methods=['post'], url_path='buy-again')
    def buy_again(self, request, pk=None):
        order = self.get_object()
        added_count = 0
        for item in order.products.all():
            if not item.product_id:
                continue
            try:
                product = Product.objects.get(id=item.product_id)
            except Product.DoesNotExist:
                continue
            sku = product.skus.order_by('id').first()
            cart_item, created = CartItem.objects.get_or_create(
                user=request.user,
                product=product,
                sku=sku,
                defaults={'quantity': item.quantity, 'is_selected': True}
            )
            if not created:
                cart_item.quantity += item.quantity
                cart_item.is_selected = True
                cart_item.save(update_fields=['quantity', 'is_selected'])
            added_count += item.quantity
        if added_count == 0:
            return api_response(msg='订单商品已下架，无法再次购买', code=400)
        return api_response({'added_count': added_count}, msg='added to cart')


class PaymentViewSet(ResponseMixin, viewsets.ReadOnlyModelViewSet):
    serializer_class = PaymentTransactionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return PaymentTransaction.objects.filter(user=self.request.user).select_related('order')

    def retrieve(self, request, *args, **kwargs):
        payment = self.get_object()
        return api_response(self.get_serializer(payment, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    @transaction.atomic
    def confirm(self, request, pk=None):
        payment = self.get_queryset().select_for_update().get(pk=pk)
        if payment.status == 'succeeded':
            return api_response(
                self.get_serializer(payment, context={'request': request}).data,
                msg='payment already succeeded'
            )
        if payment.status not in ('created', 'requires_action', 'processing'):
            return api_response(msg='当前支付单不可确认', code=400)

        mode = payment.provider_payload.get('mode') if isinstance(payment.provider_payload, dict) else ''
        allow_client_confirm = getattr(settings, 'PAYMENT_ALLOW_CLIENT_CONFIRM', settings.DEBUG)
        if mode != 'sandbox' and not allow_client_confirm:
            return api_response(msg='请等待支付服务商回调确认', code=400)

        payment = complete_payment_transaction(payment, request)
        return api_response(
            self.get_serializer(payment, context={'request': request}).data,
            msg='payment confirmed'
        )


class AddressViewSet(ResponseMixin, viewsets.ModelViewSet):
    serializer_class = AddressSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Address.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        return api_response(serializer.data)

    @action(detail=True, methods=['put'])
    def set_default(self, request, pk=None):
        Address.objects.filter(user=request.user).update(is_default=False)
        Address.objects.filter(id=pk, user=request.user).update(is_default=True)
        return api_response()

    @action(detail=False, methods=['get'])
    def region(self, request):
        return api_response(REGION_DATA)


class FavoriteViewSet(ResponseMixin, viewsets.ModelViewSet):
    serializer_class = FavoriteSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'post', 'delete']

    def get_queryset(self):
        return Favorite.objects.filter(user=self.request.user).select_related('image')

    def perform_create(self, serializer):
        product_id = self.request.data.get('productId')
        product = Product.objects.select_related('image').get(id=product_id)
        serializer.save(
            user=self.request.user,
            product_id=product_id,
            name=product.name,
            price=product.price,
            original_price=product.original_price,
            image=product.image,
            sales=f"{product.sales_count}+"
        )

    def create(self, request, *args, **kwargs):
        product_id = request.data.get('productId')
        existing = self.get_queryset().filter(product_id=product_id).first()
        if existing:
            return api_response(FavoriteSerializer(existing, context={'request': request}).data)
        return super().create(request, *args, **kwargs)

    @action(detail=False, methods=['get'])
    def check(self, request):
        product_id = request.GET.get('product_id', '')
        fav = self.get_queryset().filter(product_id=product_id).first()
        return api_response({'is_favorited': fav is not None, 'favorite_id': fav.id if fav else None})




class BrowseHistoryViewSet(ResponseMixin, viewsets.ModelViewSet):
    serializer_class = BrowseHistorySerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'post', 'delete']

    def get_queryset(self):
        return BrowseHistory.objects.filter(user=self.request.user).select_related(
            'product',
            'product__image',
            'product__subcategory',
        )

    def create(self, request, *args, **kwargs):
        product_id = request.data.get('productId') or request.data.get('product_id')
        if not product_id:
            return api_response(msg='缺少商品ID', code=400)
        try:
            product = Product.objects.get(id=product_id)
        except Product.DoesNotExist:
            return api_response(msg='商品不存在', code=404)

        history, _ = BrowseHistory.objects.update_or_create(
            user=request.user,
            product=product,
            defaults={},
        )
        serializer = self.get_serializer(history)
        return api_response(serializer.data)

    @action(detail=False, methods=['delete'])
    def clear(self, request):
        self.get_queryset().delete()
        return api_response()


class CouponViewSet(ResponseMixin, viewsets.ReadOnlyModelViewSet):
    serializer_class = CouponSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return UserCoupon.objects.filter(user=self.request.user).order_by('status', 'time')


class NotificationViewSet(ResponseMixin, viewsets.ModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'put']

    def get_queryset(self):
        qs = Notification.objects.filter(user=self.request.user)
        notif_type = self.request.GET.get('type')
        if notif_type:
            qs = qs.filter(type=notif_type)
        return qs

    @action(detail=False, methods=['get'])
    def count(self, request):
        count = Notification.objects.filter(user=request.user, is_read=False).count()
        return api_response({'count': count})

    @action(detail=False, methods=['put'])
    def read_all(self, request):
        Notification.objects.filter(user=request.user).update(is_read=True)
        return api_response()

    @action(detail=True, methods=['put'])
    def read(self, request, pk=None):
        Notification.objects.filter(id=pk, user=request.user).update(is_read=True)
        return api_response()


class UserViewSet(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get', 'patch'])
    def profile(self, request):
        user = request.user
        if request.method == 'PATCH':
            error = update_profile(user, request.data)
            if error:
                return api_response(msg=error, code=400)
        return api_response(profile_payload(user, request))


# Function-based views for direct URL mapping
def _do_login(request, allowed_types):
    """通用登录逻辑，allowed_types 为允许的用户类型列表"""
    username = request.data.get('username')
    password = request.data.get('password')
    if not username:
        return Response({'code': 400, 'msg': '请输入用户名'})
    if not password:
        return Response({'code': 400, 'msg': '请输入密码'})
    try:
        user = User.objects.get(username=username)
    except User.DoesNotExist:
        return Response({'code': 401, 'msg': '用户不存在'})
    if not user.check_password(password):
        return Response({'code': 401, 'msg': '密码错误'})
    # 角色校验
    profile = getattr(user, 'profile', None)
    user_type = profile.user_type if profile else 'user'
    if allowed_types and user_type not in allowed_types:
        return Response({'code': 403, 'msg': '无权限访问'})
    token, _ = Token.objects.get_or_create(user=user)
    return Response({'code': 0, 'msg': 'success', 'data': {'token': token.key, 'user_type': user_type}})


@api_view(['POST'])
@permission_classes([AllowAny])
def h5_login(request):
    """H5移动端登录 - 仅限普通用户"""
    return _do_login(request, ['user'])


@api_view(['POST'])
@permission_classes([AllowAny])
def ios_login(request):
    """iOS端登录 - 仅限普通用户"""
    return _do_login(request, ['user'])


@api_view(['POST'])
@permission_classes([AllowAny])
def admin_login(request):
    """管理端登录 - 仅限管理员"""
    return _do_login(request, ['admin'])


@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
def user_profile(request):
    user = request.user
    if request.method == 'PATCH':
        error = update_profile(user, request.data)
        if error:
            return Response({'code': 400, 'msg': error, 'data': None})
    return Response({'code': 0, 'msg': 'success', 'data': profile_payload(user, request)})


# ============== 店铺信息 ==============
class ShopInfoViewSet(viewsets.ViewSet):
    permission_classes = [AllowAny]

    def list(self, request):
        info, _ = ShopInfo.objects.get_or_create(pk=1)
        return api_response(ShopInfoSerializer(info).data)


# ============== VIP会员 ==============
class VIPViewSet(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    def list(self, request):
        vip, _ = VIPMembership.objects.get_or_create(user=request.user)
        return api_response(VIPSerializer(vip).data)

    @action(detail=False, methods=['post'])
    def upgrade(self, request):
        vip, _ = VIPMembership.objects.get_or_create(user=request.user)
        idx = VIP_LEVEL_ORDER.index(vip.level) if vip.level in VIP_LEVEL_ORDER else 0
        if idx < len(VIP_LEVEL_ORDER) - 1:
            from django.utils import timezone
            from datetime import timedelta
            vip.level = VIP_LEVEL_ORDER[idx + 1]
            vip.expire_date = (timezone.now() + timedelta(days=365)).date()
            vip.growth_value += 500
            vip.save()
        return api_response(VIPSerializer(vip).data)
