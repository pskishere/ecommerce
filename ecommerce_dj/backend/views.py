from rest_framework import viewsets, serializers
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token
from rest_framework.exceptions import AuthenticationFailed
from django.contrib.auth.models import User
import json
from datetime import datetime

from .models import (
    Category, Subcategory, Product, ProductDetail,
    HomeBanner, HomeFlashSale, HomeHotRank, HomeRecommend, HomeNewArrival, HomePromotion,
    CartItem, Order, OrderProduct, Address, Review, Favorite, UserCoupon, Notification,
    SpecGroup, SpecValue, SKU, SKUSpec
)
from .serializers import (
    ProductListSerializer, ProductDetailSerializer, SpecValueSerializer, SpecGroupSerializer,
    CategorySerializer, CategoryWithSubcategoriesSerializer, SubcategorySerializer, SubcategoryWithProductsSerializer,
    HomeBannerSerializer, HomeFlashSaleSerializer, HomeHotRankSerializer,
    HomeRecommendSerializer, HomeNewArrivalSerializer, HomePromotionSerializer,
    CartItemSerializer, OrderSerializer, OrderProductSerializer, AddressSerializer,
    FavoriteSerializer, CouponSerializer, NotificationSerializer,
    ReviewSerializer
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


def get_image_url(image_field, context=None):
    if image_field and image_field.file:
        if context and 'request' in context:
            return context['request'].build_absolute_uri(image_field.file.url)
        return image_field.file.url
    return None


# ============ SKU Algorithm ============
# Reference: https://github.com/xieyezi/sku-algorithm
# 权值说明: 0=互不相连, 1=同级(同规格组), >=2=可组合成有效SKU

class SKUService:
    WEIGHT_DISCONNECTED = 0
    WEIGHT_SAME_LEVEL = 1
    WEIGHT_COMBINABLE = 2

    def __init__(self, spec_groups, skus):
        self.spec_groups = spec_groups
        self.skus = skus
        self.vertex = []  # 所有规格值的code列表
        self.code_to_index = {}
        self.group_map = {}  # code -> group_id
        self.quantity = 0
        self.matrix = []  # 权值矩阵
        self._build_matrix()

    def _build_matrix(self):
        # 1. 收集所有顶点
        for group in self.spec_groups:
            for value in group.values.all():
                code = self._make_code(group.id, value.id)
                self.vertex.append(code)
                self.code_to_index[code] = self.quantity
                self.group_map[code] = group.id
                self.quantity += 1

        # 2. 初始化矩阵为0
        self.matrix = [0] * (self.quantity * self.quantity)

        # 3. 首先填写有效SKU组合 (weight >= 2) - 这会覆盖同组值的初始连接
        for sku in self.skus:
            spec_codes = []
            for sv in sku.spec_values.all():
                for group in self.spec_groups:
                    for value in group.values.all():
                        if value.id == sv.id:
                            code = self._make_code(group.id, value.id)
                            spec_codes.append(code)
                            break
            for i in range(len(spec_codes)):
                for j in range(len(spec_codes)):
                    if i != j:
                        self._set_weight(spec_codes[i], spec_codes[j], self.WEIGHT_COMBINABLE)

        # 4. 然后填写同组点 (weight = 1) - 只对还没有>=2权重的连接设置
        for group in self.spec_groups:
            group_codes = []
            for value in group.values.all():
                code = self._make_code(group.id, value.id)
                group_codes.append(code)
            for i in range(len(group_codes)):
                for j in range(len(group_codes)):
                    if i != j:
                        # 只设置weight=1如果当前是0（没有被SKU组合覆盖）
                        idx = self.code_to_index[group_codes[i]] * self.quantity + self.code_to_index[group_codes[j]]
                        if self.matrix[idx] == 0:
                            self.matrix[idx] = self.WEIGHT_SAME_LEVEL

    def _make_code(self, group_id, value_id):
        return f"{group_id}:{value_id}"

    def _set_weight(self, code1, code2, weight):
        if code1 not in self.code_to_index or code2 not in self.code_to_index:
            return
        i = self.code_to_index[code1]
        j = self.code_to_index[code2]
        idx = i * self.quantity + j
        current = self.matrix[idx]
        if current < weight:
            self.matrix[idx] = weight

    def get_available_spec_values(self, selected_ids):
        if not selected_ids:
            return self._all_available()

        # Build selected_codes
        selected_codes = []
        for group in self.spec_groups:
            for value in group.values.all():
                if value.id in selected_ids:
                    code = self._make_code(group.id, value.id)
                    selected_codes.append(code)

        if not selected_codes:
            return self._all_available()

        # Determine which groups have selections
        groups_with_selection = set()
        for code in selected_codes:
            for group in self.spec_groups:
                if code.startswith(f'{group.id}:'):
                    groups_with_selection.add(group.id)
                    break

        # For each group, determine available values
        results = []
        for group in self.spec_groups:
            avail_ids = []
            if group.id not in groups_with_selection:
                # This group has no selection - return values that can combine with ALL selected
                for value in group.values.all():
                    code = self._make_code(group.id, value.id)
                    if self._can_combine_with_all(code, selected_codes):
                        avail_ids.append(value.id)
            else:
                # This group has selection - only return selected values that can combine with ALL selected
                for value in group.values.all():
                    code = self._make_code(group.id, value.id)
                    is_selected = code in selected_codes
                    can_combine = self._can_combine_with_all(code, selected_codes)
                    if is_selected and can_combine:
                        avail_ids.append(value.id)

            results.append({'groupId': group.id, 'availableValues': avail_ids})

        return results

    def _can_combine_with_all(self, code, selected_codes):
        """Check if code can combine with ALL selected codes.
        If only one selected (code itself), allow same-level (weight=1).
        If multiple selected, require weight >= 2 for all connections.
        """
        if code not in self.code_to_index:
            return False

        # If only one selected and it's this code, allow same-level
        if len(selected_codes) == 1 and selected_codes[0] == code:
            return True

        idx = self.code_to_index[code]

        for sel_code in selected_codes:
            if sel_code == code:
                continue
            if sel_code not in self.code_to_index:
                return False
            sel_idx = self.code_to_index[sel_code]
            weight = self.matrix[sel_idx * self.quantity + idx]
            if weight < 2:  # Not combinable (must be >= 2 for multi-selection)
                return False
        return True

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


# ============ ViewSets ============
class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.filter(is_in_stock=True)
    serializer_class = ProductListSerializer
    permission_classes = [AllowAny]

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return ProductDetailSerializer
        return ProductListSerializer

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response({'code': 0, 'msg': 'success', 'data': serializer.data})

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
            user = get_user(request)
            serializer = ReviewSerializer(data=request.data)
            if serializer.is_valid():
                serializer.save(user=user, product_id=pk, user_name='用户', user_avatar=None)
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

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response({'code': 0, 'msg': 'success', 'data': serializer.data})

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

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response({'code': 0, 'msg': 'success', 'data': serializer.data})

    @action(detail=True, methods=['get'])
    def subcategories(self, request, pk=None):
        category = self.get_object()
        subcategories = category.subcategories.filter(is_enabled=True)
        return Response({'code': 0, 'msg': 'success', 'data': SubcategoryWithProductsSerializer(subcategories, many=True, context={'request': request}).data})

    @action(detail=True, methods=['get'])
    def products(self, request, pk=None):
        """获取一级分类下所有子分类的产品"""
        category = self.get_object()
        products = Product.objects.filter(subcategory__category=category, is_in_stock=True)
        return Response({'code': 0, 'msg': 'success', 'data': ProductListSerializer(products, many=True, context={'request': request}).data})

    @action(detail=True, methods=['get'])
    def all_products(self, request, pk=None):
        """获取一级分类下所有子分类的产品（兼容旧端点）"""
        category = self.get_object()
        products = Product.objects.filter(subcategory__category=category, is_in_stock=True)
        return Response({'code': 0, 'msg': 'success', 'data': ProductListSerializer(products, many=True, context={'request': request}).data})


class HomeBannerViewSet(viewsets.ModelViewSet):
    queryset = HomeBanner.objects.filter(is_enabled=True)
    serializer_class = HomeBannerSerializer
    permission_classes = [AllowAny]

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response({'code': 0, 'msg': 'success', 'data': serializer.data})


class HomeFlashSaleViewSet(viewsets.ModelViewSet):
    queryset = HomeFlashSale.objects.filter(is_enabled=True)
    serializer_class = HomeFlashSaleSerializer
    permission_classes = [AllowAny]

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response({'code': 0, 'msg': 'success', 'data': serializer.data})


class HomeHotRankViewSet(viewsets.ModelViewSet):
    queryset = HomeHotRank.objects.filter(is_enabled=True)
    serializer_class = HomeHotRankSerializer
    permission_classes = [AllowAny]

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response({'code': 0, 'msg': 'success', 'data': serializer.data})


class HomeRecommendViewSet(viewsets.ModelViewSet):
    queryset = HomeRecommend.objects.filter(is_enabled=True)
    serializer_class = HomeRecommendSerializer
    permission_classes = [AllowAny]

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response({'code': 0, 'msg': 'success', 'data': serializer.data})


class HomeNewArrivalViewSet(viewsets.ModelViewSet):
    queryset = HomeNewArrival.objects.filter(is_enabled=True)
    serializer_class = HomeNewArrivalSerializer
    permission_classes = [AllowAny]

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response({'code': 0, 'msg': 'success', 'data': serializer.data})

class HomePromotionViewSet(viewsets.ModelViewSet):
    queryset = HomePromotion.objects.filter(is_enabled=True)
    serializer_class = HomePromotionSerializer
    permission_classes = [AllowAny]

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response({'code': 0, 'msg': 'success', 'data': serializer.data})


class HomePromotionViewSet(viewsets.ModelViewSet):
    queryset = HomePromotion.objects.filter(is_enabled=True)
    serializer_class = HomePromotionSerializer
    permission_classes = [AllowAny]


class CartViewSet(viewsets.ModelViewSet):
    serializer_class = CartItemSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'post', 'put', 'patch', 'delete']

    def get_queryset(self):
        return CartItem.objects.filter(user=get_user(self.request)).select_related('product')

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = CartItemSerializer(queryset, many=True, context={'request': request})
        items = serializer.data
        total = sum(
            float(item['product']['price']) * item['quantity']
            for item in items if item['is_selected']
        )
        return Response({'code': 0, 'msg': 'success', 'data': {'items': items, 'total': total}})

    def create(self, request):
        user = get_user(request)
        product_id = request.data.get('productId')
        quantity = request.data.get('quantity', 1)
        item, _ = CartItem.objects.get_or_create(user=user, product_id=product_id, defaults={'quantity': quantity})
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
        CartItem.objects.filter(user=get_user(request)).update(is_selected=selected)
        return Response({'code': 0, 'msg': 'success'})

    def destroy(self, request, pk=None):
        item = self.get_object()
        item.delete()
        return Response({'code': 0, 'msg': 'removed'})

    @action(detail=False, methods=['delete'])
    def clear(self, request):
        CartItem.objects.filter(user=get_user(request)).delete()
        return Response({'code': 0, 'msg': 'cleared'})


class OrderViewSet(viewsets.ModelViewSet):
    serializer_class = OrderSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'post', 'put', 'delete']

    def get_queryset(self):
        qs = Order.objects.filter(user=get_user(self.request))
        status = self.request.GET.get('status')
        if status:
            qs = qs.filter(status=status)
        return qs.order_by('-created_at')

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)
        return Response({'code': 0, 'msg': 'success', 'data': serializer.data})

    def create(self, request):
        user = get_user(request)
        cart_item_ids = request.data.get('cartItemIds', [])
        address_id = request.data.get('addressId')
        remark = request.data.get('remark', '')

        # 获取地址副本
        address = None
        if address_id:
            try:
                address = Address.objects.get(id=address_id, user=user)
            except Address.DoesNotExist:
                pass

        total = 0
        order_items = []
        for cid in cart_item_ids:
            try:
                item = CartItem.objects.select_related('product').get(id=cid, user=user)
                total += float(item.product.price) * item.quantity
                order_items.append({
                    'name': item.product.name,
                    'spec': '',
                    'price': float(item.product.price),
                    'quantity': item.quantity,
                    'image': item.product.image,
                })
                item.delete()
            except CartItem.DoesNotExist:
                pass

        if not order_items:
            return Response({'code': 400, 'msg': '购物车为空'})

        order = Order.objects.create(
            user=user,
            id=f"ORH5{datetime.now().strftime('%Y%m%d%H%M%S')}",
            store='潮流优品官方旗舰店',
            status='pending',
            total_amount=total,
            payment=total,
            freight=0,
            discount=0,
            address_name=address.name if address else '',
            address_phone=address.phone if address else '',
            address_province=address.province if address else '',
            address_city=address.city if address else '',
            address_district=address.district if address else '',
            address_detail=address.detail if address else '',
        )
        for item in order_items:
            OrderProduct.objects.create(order=order, **item)
        return Response({'code': 0, 'msg': 'order created', 'data': OrderSerializer(order, context={'request': request}).data})

    @action(detail=False, methods=['post'])
    def preview(self, request):
        """预订单接口 - 不入库，只返回预览数据"""
        user = get_user(request)
        cart_item_ids = request.data.get('cartItemIds', [])
        address_id = request.data.get('addressId')

        items = []
        total = 0
        for cid in cart_item_ids:
            try:
                item = CartItem.objects.select_related('product').get(id=cid, user=user)
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
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Address.objects.filter(user=get_user(self.request))

    def perform_create(self, serializer):
        serializer.save(user=get_user(self.request))

    @action(detail=True, methods=['put'])
    def set_default(self, request, pk=None):
        user = get_user(request)
        Address.objects.filter(user=user).update(is_default=False)
        Address.objects.filter(id=pk, user=user).update(is_default=True)
        return Response({'code': 0, 'msg': 'success'})

    @action(detail=False, methods=['get'])
    def region(self, request):
        return Response({'code': 0, 'data': REGION_DATA})


class FavoriteViewSet(viewsets.ModelViewSet):
    serializer_class = FavoriteSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'post', 'delete']

    def get_queryset(self):
        return Favorite.objects.filter(user=get_user(self.request))

    def perform_create(self, serializer):
        product_id = self.request.data.get('productId')
        product = Product.objects.get(id=product_id)
        serializer.save(
            user=get_user(self.request),
            name=product.name,
            price=product.price,
            original_price=product.original_price,
            image=get_image_url(product.image, context={'request': self.request}),
            sales=f"{product.sales_count}+"
        )




class CouponViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = CouponSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return UserCoupon.objects.filter(user=get_user(self.request))


class NotificationViewSet(viewsets.ModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]
    http_method_names = ['get', 'put']

    def get_queryset(self):
        qs = Notification.objects.filter(user=get_user(self.request))
        notif_type = self.request.GET.get('type')
        if notif_type:
            qs = qs.filter(type=notif_type)
        return qs

    @action(detail=False, methods=['get'])
    def count(self, request):
        user = get_user(request)
        count = Notification.objects.filter(user=user, is_read=False).count()
        return Response({'code': 0, 'msg': 'success', 'data': {'count': count}})

    @action(detail=False, methods=['put'])
    def read_all(self, request):
        Notification.objects.filter(user=get_user(request)).update(is_read=True)
        return Response({'code': 0, 'msg': 'success'})

    @action(detail=True, methods=['put'])
    def read(self, request, pk=None):
        Notification.objects.filter(id=pk, user=get_user(request)).update(is_read=True)
        return Response({'code': 0, 'msg': 'success'})


class LoginViewSet(viewsets.ViewSet):
    permission_classes = [AllowAny]
    authentication_classes = []

    @action(detail=False, methods=['post'])
    def login(self, request):
        user_id = request.data.get('user_id')
        if not user_id:
            return Response({'code': 400, 'msg': '请输入用户名'})
        try:
            user = User.objects.get(username=user_id)
        except User.DoesNotExist:
            return Response({'code': 401, 'msg': '用户不存在'})
        token, _ = Token.objects.get_or_create(user=user)
        return Response({'code': 0, 'msg': 'success', 'data': {'token': token.key}})


class UserViewSet(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'])
    def profile(self, request):
        user = get_user(request)
        return Response({'code': 0, 'msg': 'success', 'data': {
            'id': user.id, 'username': user.username, 'email': user.email or '',
            'avatar_name': 'https://picsum.photos/200/200?random=100',
            'followCount': 128, 'fansCount': 356, 'points': 2860,
        }})


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


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_profile(request):
    user = get_user(request)
    return Response({'code': 0, 'msg': 'success', 'data': {
        'id': user.id, 'username': user.username, 'email': user.email or '',
        'avatar_name': 'https://picsum.photos/200/200?random=100',
        'followCount': 128, 'fansCount': 356, 'points': 2860,
    }})
