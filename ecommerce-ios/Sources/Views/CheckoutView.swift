import SwiftUI

struct CheckoutView: View {
    @EnvironmentObject private var cart: Cart
    @Environment(\.dismiss) private var dismiss
    @State private var addresses: [Address] = []
    @State private var selectedAddress: Address?
    @State private var coupons: [CheckoutCoupon] = []
    @State private var selectedCoupon: CheckoutCoupon?
    @State private var selectedPayment: PaymentMethod = PaymentMethod.mockMethods[0]
    @State private var remarkText = ""
    @State private var showAddressSheet = false
    @State private var showCouponSheet = false
    @State private var isLoading = true
    @State private var isSubmitting = false

    private let accentColor = DesignSystem.Colors.accent

    private var subtotal: Decimal {
        cart.selectedTotalPrice
    }

    private var discount: Decimal {
        selectedCoupon.map { $0.value } ?? 0
    }

    private var freight: Decimal {
        subtotal >= 99 ? 0 : 10
    }

    private var totalAmount: Decimal {
        subtotal - discount + freight
    }

    private var couponStatusText: String {
        if let coupon = selectedCoupon {
            return "-¥\(coupon.discountValue)"
        }
        let usableCount = coupons.filter { $0.usable }.count
        if usableCount > 0 {
            return "\(usableCount)张可用"
        }
        return "暂无可用"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                addressSection
                orderItemsSection
                couponSection
                paymentSection
                remarkSection
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
            AddressSelectionSheet(
                addresses: addresses,
                selectedAddress: $selectedAddress
            )
        }
        .sheet(isPresented: $showCouponSheet) {
            CouponSelectionSheet(
                coupons: coupons,
                selectedCoupon: $selectedCoupon
            )
        }
        .task {
            do {
                addresses = try await Address.getAddresses()
                selectedAddress = addresses.first { $0.isDefault } ?? addresses.first

                let userCoupons = try await UserCoupon.getCoupons()
                coupons = userCoupons.map { coupon in
                    CheckoutCoupon(
                        id: coupon.id,
                        name: coupon.name,
                        value: coupon.value,
                        threshold: coupon.threshold,
                        description: coupon.description,
                        time: coupon.time,
                        usable: cart.selectedTotalPrice >= coupon.threshold
                    )
                }
            } catch {
                print("Failed to load checkout data: \(error)")
            }
            isLoading = false
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
                        Text(selectedAddress?.name ?? "请选择收货地址")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color(.label))
                        if let phone = selectedAddress?.phone {
                            Text(phone)
                                .font(.system(size: 14))
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                        if selectedAddress?.isDefault == true {
                            Text("默认")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }

                    if let addr = selectedAddress {
                        Text(addr.fullAddress)
                            .font(.system(size: 13))
                            .foregroundStyle(Color(.secondaryLabel))
                            .lineSpacing(2)
                            .multilineTextAlignment(.leading)
                    }
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

            ForEach(cart.selectedItems) { item in
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 12) {
                        AsyncImage(url: item.product.imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 72, height: 72)
                                .clipped()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                                .frame(width: 72, height: 72)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.product.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(.label))
                                .lineLimit(2)

                            Text("黑色经典款 / 标准版")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(.secondaryLabel))

                            HStack {
                                Text(item.product.formattedPrice)
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

                    if item.id != cart.selectedItems.last?.id {
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
                    Text(couponStatusText)
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
                ForEach(PaymentMethod.mockMethods) { method in
                    Button(action: { selectedPayment = method }) {
                        HStack(spacing: 10) {
                            Circle()
                                .stroke(selectedPayment.id == method.id ? accentColor : Color(hex: "DDDDDD"), lineWidth: 2)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .fill(selectedPayment.id == method.id ? accentColor : Color.clear)
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
            priceRow(label: "商品金额", value: "¥\(subtotal)")
            priceRow(label: "优惠券", value: discount > 0 ? "-¥\(discount)" : "-¥0", isDiscount: true)
            priceRow(label: "运费", value: freight == 0 ? "免运费" : "¥\(freight)")

            Divider()
                .padding(.top, 12)

            HStack {
                Text("合计")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(.label))
                Spacer()
                Text("¥\(totalAmount)")
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
                Text("¥\(totalAmount)")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(accentColor)

                Spacer()

                Button(action: submitOrder) {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("提交订单")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(height: 48)
                .padding(.horizontal, 32)
                .background(cart.hasSelectedItems ? accentColor : Color.gray)
                .clipShape(Capsule())
                .disabled(!cart.hasSelectedItems || isSubmitting)
            }
            .frame(height: 70)
            .padding(.horizontal, 16)
            .background(Color.white)
        }
    }

    private func submitOrder() {
        guard let address = selectedAddress else { return }
        isSubmitting = true
        Task {
            await cart.clearCart()
            isSubmitting = false
            dismiss()
        }
    }
}

// MARK: - Address Selection Sheet
struct AddressSelectionSheet: View {
    let addresses: [Address]
    @Binding var selectedAddress: Address?
    @Environment(\.dismiss) private var dismiss

    private let accentColor = DesignSystem.Colors.accent

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(addresses) { address in
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

    private func addressItem(_ address: Address) -> some View {
        Button(action: {
            selectedAddress = address
            dismiss()
        }) {
            HStack(spacing: 10) {
                Circle()
                    .stroke(selectedAddress?.id == address.id ? accentColor : Color(hex: "DDDDDD"), lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(selectedAddress?.id == address.id ? accentColor : Color.clear)
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
                    .fill(selectedAddress?.id == address.id ? Color(hex: "FFF8F6") : Color(hex: "F8F8F8"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedAddress?.id == address.id ? accentColor : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Coupon Selection Sheet
struct CouponSelectionSheet: View {
    let coupons: [CheckoutCoupon]
    @Binding var selectedCoupon: CheckoutCoupon?
    @Environment(\.dismiss) private var dismiss

    private let accentColor = DesignSystem.Colors.accent

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    couponNoneItem

                    ForEach(coupons) { coupon in
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
            selectedCoupon = nil
            dismiss()
        }) {
            HStack(spacing: 10) {
                Circle()
                    .stroke(selectedCoupon == nil ? accentColor : Color(hex: "DDDDDD"), lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(selectedCoupon == nil ? accentColor : Color.clear)
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
                    .fill(selectedCoupon == nil ? Color(hex: "FFF8F6") : Color(hex: "F8F8F8"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedCoupon == nil ? accentColor : Color.clear, lineWidth: 2)
            )
        }
    }

    private func couponItem(_ coupon: CheckoutCoupon) -> some View {
        Button(action: {
            if coupon.usable {
                selectedCoupon = coupon
                dismiss()
            }
        }) {
            ZStack(alignment: .leading) {
                UnevenRoundedRectangle(
                    cornerRadii: .init(
                        topLeading: 0,
                        bottomLeading: 0,
                        bottomTrailing: 12,
                        topTrailing: 12
                    )
                )
                .fill(Color.white)

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
                            Text("\(coupon.discountValue)")
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

                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: 110)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(coupon.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: "1A1A1A"))
                            .lineLimit(1)

                        Text(coupon.description)
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "999999"))
                            .lineLimit(2)

                        Text(coupon.time)
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
                    .stroke(selectedCoupon?.id == coupon.id ? accentColor : Color.clear, lineWidth: 2)
            )
            .opacity(coupon.usable ? 1.0 : 0.5)
        }
        .disabled(!coupon.usable)
    }
}

#Preview {
    NavigationStack {
        CheckoutView()
            .environmentObject(Cart())
    }
}
