import SwiftUI

struct CheckoutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CheckoutViewModel()
    @State private var remarkText = ""
    @State private var showAddressSheet = false
    @State private var showCouponSheet = false

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                // Address Section
                addressSection

                // Order Items
                orderItemsSection

                // Coupon Section
                couponSection

                // Payment Section
                paymentSection

                // Remark Section
                remarkSection

                // Price Summary
                priceSummarySection

                Spacer(minLength: 80)
            }
            .padding(.top, 8)
        }
        .background(Color(hex: "F5F5F5"))
        .navigationTitle("确认订单")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
        .overlay(alignment: .bottom) {
            bottomBar
        }
        .sheet(isPresented: $showAddressSheet) {
            AddressSelectionSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showCouponSheet) {
            CouponSelectionSheet(viewModel: viewModel)
        }
    }

    // MARK: - Address Section
    private var addressSection: some View {
        Button(action: { showAddressSheet = true }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(red: 1.0, green: 0.94, blue: 0.92))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "location.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(accentColor)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(viewModel.selectedAddress?.name ?? "林小琳")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(.label))
                        Text(viewModel.selectedAddress?.phone ?? "138****8888")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(.secondaryLabel))
                        if viewModel.selectedAddress?.isDefault == true {
                            Text("默认")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }

                    Text(viewModel.selectedAddress?.fullAddress ?? "广东省 广州市 天河区 珠江新城花城大道88号华夏中心A栋1501室")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(.secondaryLabel))
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(.systemGray3))
            }
            .padding(16)
            .background(Color.white)
        }
    }

    // MARK: - Order Items Section
    private var orderItemsSection: some View {
        VStack(spacing: 0) {
            // Store Header
            HStack(spacing: 10) {
                Image(systemName: "store")
                    .font(.system(size: 16))
                    .foregroundStyle(accentColor)
                Text("潮流优品官方旗舰店")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(.label))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .overlay(
                Rectangle()
                    .fill(Color(hex: "F0F0F0"))
                    .frame(height: 1),
                alignment: .bottom
            )

            // Order Items
            ForEach(viewModel.orderItems) { item in
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                            .frame(width: 72, height: 72)
                            .overlay(
                                Image(item.imageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            )
                            .clipped()

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(.label))
                                .lineLimit(2)

                            Text(item.spec)
                                .font(.system(size: 12))
                                .foregroundStyle(Color(.secondaryLabel))

                            HStack {
                                Text("¥\(item.price)")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(accentColor)

                                Spacer()

                                Text("x\(item.quantity)")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color(.secondaryLabel))
                            }
                        }
                    }
                    .padding(12)

                    if item.id != viewModel.orderItems.last?.id {
                        Divider()
                            .background(Color(hex: "F5F5F5"))
                    }
                }
            }
        }
        .background(Color.white)
    }

    // MARK: - Coupon Section
    private var couponSection: some View {
        Button(action: { showCouponSheet = true }) {
            HStack {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(accentColor)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "ticket.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.white)
                        )

                    Text("优惠券")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color(.label))
                }

                Spacer()

                HStack(spacing: 6) {
                    Text(viewModel.couponStatusText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(accentColor)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(.systemGray3))
                }
            }
            .padding(14)
            .background(Color.white)
        }
    }

    // MARK: - Payment Section
    private var paymentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("支付方式")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(.label))
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)

            VStack(spacing: 12) {
                ForEach(viewModel.paymentMethods, id: \.id) { method in
                    Button(action: { viewModel.selectedPayment = method }) {
                        HStack(spacing: 10) {
                            Circle()
                                .stroke(viewModel.selectedPayment.id == method.id ? accentColor : Color(hex: "DDDDDD"), lineWidth: 2)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .fill(viewModel.selectedPayment.id == method.id ? accentColor : Color.clear)
                                        .frame(width: 10, height: 10)
                                )

                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: "F5F5F5"))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: method.icon)
                                        .font(.system(size: 14))
                                        .foregroundStyle(accentColor)
                                )

                            Text(method.name)
                                .font(.system(size: 14))
                                .foregroundStyle(Color(.label))

                            Spacer()

                            if method.name == "微信支付" {
                                Text("推荐")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(accentColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(red: 1.0, green: 0.94, blue: 0.92))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(Color.white)
    }

    // MARK: - Remark Section
    private var remarkSection: some View {
        HStack(spacing: 12) {
            Text("备注")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(.label))

            TextField("选填，可备注特殊需求", text: $remarkText)
                .font(.system(size: 14))
                .foregroundStyle(Color(.secondaryLabel))
        }
        .padding(14)
        .background(Color.white)
    }

    // MARK: - Price Summary Section
    private var priceSummarySection: some View {
        VStack(spacing: 0) {
            priceRow(label: "商品金额", value: "¥\(viewModel.subtotal)")
            priceRow(label: "优惠券", value: viewModel.discount > 0 ? "-¥\(viewModel.discount)" : "-¥0", isDiscount: true)
            priceRow(label: "运费", value: viewModel.freight == 0 ? "免运费" : "¥\(viewModel.freight)")

            Divider()
                .padding(.top, 12)

            HStack {
                Text("合计")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(.label))
                Spacer()
                Text("¥\(viewModel.totalAmount)")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(accentColor)
            }
            .padding(16)
        }
        .background(Color.white)
    }

    private func priceRow(label: String, value: String, isDiscount: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color(.secondaryLabel))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isDiscount ? accentColor : Color(.label))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                Text("¥\(viewModel.totalAmount)")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(accentColor)

                Spacer()

                Button(action: {}) {
                    Text("提交订单")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(height: 48)
                        .padding(.horizontal, 32)
                        .background(accentColor)
                        .clipShape(Capsule())
                }
            }
            .frame(height: 70)
            .padding(.horizontal, 16)
            .background(Color.white)
        }
    }
}

// MARK: - Address Selection Sheet
struct AddressSelectionSheet: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @Environment(\.dismiss) private var dismiss

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(viewModel.addresses) { address in
                        addressItem(address)
                    }
                }
                .padding(16)
            }
            .navigationTitle("选择收货地址")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func addressItem(_ address: CheckoutAddress) -> some View {
        Button(action: {
            viewModel.selectAddress(address)
            dismiss()
        }) {
            HStack(spacing: 10) {
                // Radio
                Circle()
                    .stroke(viewModel.selectedAddress?.id == address.id ? accentColor : Color(hex: "DDDDDD"), lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(viewModel.selectedAddress?.id == address.id ? accentColor : Color.clear)
                            .frame(width: 10, height: 10)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(address.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color(.label))
                        Text(address.phone)
                            .font(.system(size: 14))
                            .foregroundStyle(Color(.secondaryLabel))
                        if address.isDefault {
                            Text("默认")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    Text(address.fullAddress)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(.secondaryLabel))
                        .lineSpacing(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.selectedAddress?.id == address.id ? Color(hex: "FFF8F6") : Color(hex: "F8F8F8"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(viewModel.selectedAddress?.id == address.id ? accentColor : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Coupon Selection Sheet
struct CouponSelectionSheet: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @Environment(\.dismiss) private var dismiss

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    // "不使用优惠券" option
                    couponNoneItem

                    ForEach(viewModel.availableCoupons) { coupon in
                        couponItem(coupon)
                    }
                }
                .padding(16)
            }
            .navigationTitle("选择优惠券")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var couponNoneItem: some View {
        Button(action: {
            viewModel.selectCoupon(nil)
            dismiss()
        }) {
            HStack(spacing: 10) {
                // Radio
                Circle()
                    .stroke(viewModel.selectedCoupon == nil ? accentColor : Color(hex: "DDDDDD"), lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(viewModel.selectedCoupon == nil ? accentColor : Color.clear)
                            .frame(width: 10, height: 10)
                    )

                Text("不使用优惠券")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(.secondaryLabel))

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.selectedCoupon == nil ? Color(hex: "FFF8F6") : Color(hex: "F8F8F8"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(viewModel.selectedCoupon == nil ? accentColor : Color.clear, lineWidth: 2)
            )
        }
    }

    private func couponItem(_ coupon: CheckoutCoupon) -> some View {
        Button(action: {
            if coupon.usable {
                viewModel.selectCoupon(coupon)
                dismiss()
            }
        }) {
            ZStack(alignment: .leading) {
                // Background white card with rounded right corners
                UnevenRoundedRectangle(
                    cornerRadii: .init(
                        topLeading: 0,
                        bottomLeading: 0,
                        bottomTrailing: 12,
                        topTrailing: 12
                    )
                )
                .fill(Color.white)

                // Orange left section
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: "FF6B4A"), Color(hex: "FF8E6B")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    VStack(spacing: 4) {
                        HStack(alignment: .top, spacing: 2) {
                            Text("¥")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                            Text("\(coupon.discount)")
                                .font(.system(size: 22, weight: .black))
                                .foregroundStyle(.white)
                        }
                        Text("满\(coupon.threshold)元可用")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .frame(width: 110)
                .clipShape(
                    UnevenRoundedRectangle(
                        cornerRadii: .init(
                            topLeading: 12,
                            bottomLeading: 12,
                            bottomTrailing: 0,
                            topTrailing: 0
                        )
                    )
                )

                // Content
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: 110)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(coupon.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: "1A1A1A"))
                            .lineLimit(1)

                        Text(coupon.desc)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "999999"))
                            .lineLimit(2)

                        Text(coupon.validUntil)
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "BBBBBB"))
                            .padding(.top, 6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .frame(height: 112)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(viewModel.selectedCoupon?.id == coupon.id ? accentColor : Color.clear, lineWidth: 2)
            )
            .opacity(coupon.usable ? 1.0 : 0.5)
        }
        .disabled(!coupon.usable)
    }
}

// MARK: - Checkout ViewModel
class CheckoutViewModel: ObservableObject {
    @Published var selectedPayment: PaymentMethod
    @Published var selectedAddress: CheckoutAddress?
    @Published var selectedCoupon: CheckoutCoupon?
    @Published var orderItems: [CheckoutOrderItem]

    let paymentMethods: [PaymentMethod] = [
        PaymentMethod(id: UUID(), name: "微信支付", icon: "checkmark.circle.fill", color: Color.green),
        PaymentMethod(id: UUID(), name: "支付宝", icon: "creditcard.fill", color: Color.blue)
    ]

    let addresses: [CheckoutAddress] = [
        CheckoutAddress(id: UUID(), name: "林小琳", phone: "138****8888", province: "广东省", city: "广州市", district: "天河区", detail: "珠江新城花城大道88号华夏中心A栋1501室", isDefault: true),
        CheckoutAddress(id: UUID(), name: "林小琳", phone: "139****6666", province: "广东省", city: "深圳市", district: "南山区", detail: "科技园南区高新南七道R2-B栋5楼", isDefault: false),
        CheckoutAddress(id: UUID(), name: "王明", phone: "158****2222", province: "北京市", city: "北京市", district: "朝阳区", detail: "建国路89号华贸中心写字楼A座12层", isDefault: false)
    ]

    let availableCoupons: [CheckoutCoupon] = [
        CheckoutCoupon(id: UUID(), name: "新人专享券", discount: 20, threshold: 100, desc: "满100减20", validUntil: "2026-04-30", usable: true),
        CheckoutCoupon(id: UUID(), name: "平台满减券", discount: 10, threshold: 50, desc: "满50减10", validUntil: "2026-04-15", usable: true),
        CheckoutCoupon(id: UUID(), name: "限时大额券", discount: 50, threshold: 300, desc: "满300减50", validUntil: "2026-04-30", usable: false)
    ]

    var subtotal: Decimal {
        orderItems.reduce(0) { $0 + $1.price * Decimal($1.quantity) }
    }

    var discount: Decimal {
        selectedCoupon.map { Decimal($0.discount) } ?? 0
    }

    var freight: Decimal {
        subtotal >= 99 ? 0 : 10
    }

    var totalAmount: Decimal {
        subtotal - discount + freight
    }

    var couponStatusText: String {
        if let coupon = selectedCoupon {
            return "-¥\(coupon.discount)"
        }
        let usableCount = availableCoupons.filter { $0.usable }.count
        if usableCount > 0 {
            return "\(usableCount)张可用"
        }
        return "暂无可用"
    }

    init() {
        selectedPayment = paymentMethods[0]
        selectedAddress = addresses.first { $0.isDefault } ?? addresses.first
        orderItems = [
            CheckoutOrderItem(
                id: UUID(),
                name: "时尚简约腕表",
                spec: "黑色经典款 / 标准版",
                price: 299,
                quantity: 1,
                imageName: "product_01_watch"
            ),
            CheckoutOrderItem(
                id: UUID(),
                name: "无线蓝牙耳机",
                spec: "白色 / 标配版",
                price: 199,
                quantity: 2,
                imageName: "product_02_earbuds"
            )
        ]
    }

    func selectAddress(_ address: CheckoutAddress) {
        selectedAddress = address
    }

    func selectCoupon(_ coupon: CheckoutCoupon?) {
        selectedCoupon = coupon
    }
}

#Preview {
    NavigationStack {
        CheckoutView()
    }
}
