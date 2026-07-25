import SwiftUI

struct PaymentView: View {
    let order: Order
    var onComplete: (() -> Void)? = nil
    var onPaid: ((Order) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var selectedMethod: String
    @State private var phase: Phase = .selecting
    @State private var paidOrder: Order? = nil
    @State private var paymentSession: PaymentSession? = nil
    @State private var errorMessage: String? = nil

    enum Phase { case selecting, processing, awaitingConfirmation, success, failed }

    init(
        order: Order,
        initialMethod: String = "wxpay",
        onComplete: (() -> Void)? = nil,
        onPaid: ((Order) -> Void)? = nil
    ) {
        self.order = order
        self.onComplete = onComplete
        self.onPaid = onPaid
        _selectedMethod = State(initialValue: initialMethod)
    }

    private let methods: [(id: String, name: String, icon: String, tag: String?)] = [
        ("wxpay",  "微信支付",  "checkmark.circle.fill", "推荐"),
        ("alipay", "支付宝",    "creditcard.fill",       nil),
        ("balance","余额支付",  "dollarsign.circle.fill", nil),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch phase {
                case .selecting:  selectingView
                case .processing: processingView
                case .awaitingConfirmation: awaitingConfirmationView
                case .success:    successView
                case .failed:     failedView
                }
            }
        }
        .navigationTitle("收银台")
        .navigationBarTitleDisplayMode(.inline)
        .hideTabBar()
    }

    // MARK: - Selecting
    private var selectingView: some View {
        VStack(spacing: 0) {
            // Amount header
            VStack(spacing: 6) {
                Text("待支付金额")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.8))
                Text(order.payment.rmbText)
                    .font(.system(size: 38, weight: .black))
                    .foregroundStyle(.white)
                Text("订单号：\(order.id)")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
            .padding(.bottom, 36)
            .background(
                LinearGradient(
                    colors: [DesignSystem.Colors.accent, Color(red: 1.0, green: 0.55, blue: 0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Payment methods
            VStack(spacing: 0) {
                ForEach(methods, id: \.id) { method in
                    Button(action: { selectedMethod = method.id }) {
                        HStack(spacing: 14) {
                            Image(systemName: method.icon)
                                .font(.system(size: 22))
                                .foregroundStyle(methodColor(method.id))
                                .frame(width: 30)

                            Text(method.name)
                                .font(.system(size: 15))
                                .foregroundStyle(Color(.label))

                            if let tag = method.tag {
                                Text(tag)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(DesignSystem.Colors.accent)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(red: 1.0, green: 0.94, blue: 0.92))
                                    .clipShape(Capsule())
                            }

                            Spacer()

                            Image(systemName: selectedMethod == method.id ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundStyle(selectedMethod == method.id ? DesignSystem.Colors.accent : Color(.systemGray4))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)

                    if method.id != methods.last?.id {
                        Divider().padding(.leading, 64)
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(16)

            Spacer()

            // Pay button
            Button(action: startPayment) {
                Text("立即支付 \(order.payment.rmbText)")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(DesignSystem.Colors.accent)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
        }
        .background(DesignSystem.Colors.pageBackground)
    }

    // MARK: - Processing
    private var processingView: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView()
                .scaleEffect(1.8)
                .tint(DesignSystem.Colors.accent)
            Text("支付处理中…")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Awaiting Confirmation
    private var awaitingConfirmationView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.accent.opacity(0.12))
                        .frame(width: 96, height: 96)
                    Image(systemName: "wallet.pass")
                        .font(.system(size: 46, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.accent)
                }

                VStack(spacing: 8) {
                    Text("等待支付确认")
                        .font(.system(size: 23, weight: .bold))
                        .foregroundStyle(Color(.label))
                    Text(awaitingMessage)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                if let paymentSession {
                    VStack(spacing: 6) {
                        Text("支付单号")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(.tertiaryLabel))
                        Text(paymentSession.id)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(.secondaryLabel))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 30)

            Spacer()

            VStack(spacing: 12) {
                if canOpenExternalPayment {
                    Button(action: openPaymentAppOrPage) {
                        Text("打开支付")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(DesignSystem.Colors.accent)
                            .clipShape(Capsule())
                    }
                }

                Button(action: confirmPayment) {
                    Text(confirmButtonTitle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(Capsule())
                }

                Button(action: {
                    paymentSession = nil
                    phase = .selecting
                }) {
                    Text("更换支付方式")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(red: 1.0, green: 0.94, blue: 0.92))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Success
    private var successView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.green)
                        .symbolEffect(.bounce, value: phase == .success)
                }

                VStack(spacing: 8) {
                    Text("支付成功")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color(.label))
                    Text(order.payment.rmbText)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                NavigationLink(destination: OrderDetailView(order: paidOrder ?? order)) {
                    Text("查看订单")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(Capsule())
                }

                Button(action: {
                    onComplete?()
                    dismiss()
                }) {
                    Text("继续购物")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(DesignSystem.Colors.accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(red: 1.0, green: 0.94, blue: 0.92))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Failed
    private var failedView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.red)
            Text("支付失败")
                .font(.system(size: 22, weight: .bold))
            Text(errorMessage ?? "请检查网络后重试")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
            Button(action: {
                errorMessage = nil
                phase = .selecting
            }) {
                Text("重新支付")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(DesignSystem.Colors.accent)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Actions
    private func startPayment() {
        guard phase == .selecting else { return }
        errorMessage = nil
        phase = .processing
        Task {
            do {
                let session = try await Order.startPayment(id: order.id, method: selectedMethod)
                handlePaymentSession(session)
            } catch {
                errorMessage = userFacingErrorMessage(error, fallback: "支付失败，请稍后重试")
                phase = .failed
            }
        }
    }

    private func confirmPayment() {
        guard let paymentSession else {
            errorMessage = "支付单不存在，请重新支付"
            phase = .failed
            return
        }
        phase = .processing
        Task {
            do {
                let session = try await Order.confirmPayment(id: paymentSession.id)
                handlePaymentSession(session)
            } catch {
                errorMessage = userFacingErrorMessage(error, fallback: "支付确认失败，请稍后重试")
                phase = .failed
            }
        }
    }

    private func handlePaymentSession(_ session: PaymentSession) {
        paymentSession = session
        if session.status == "succeeded", let updatedOrder = session.order {
            paidOrder = updatedOrder
            onPaid?(updatedOrder)
            phase = .success
        } else if session.status == "failed" || session.status == "cancelled" || session.status == "expired" {
            errorMessage = session.failureReason ?? "支付未完成"
            phase = .failed
        } else {
            phase = .awaitingConfirmation
            if canOpenExternalPayment {
                openPaymentAppOrPage()
            }
        }
    }

    private var awaitingMessage: String {
        if paymentSession?.nextAction?.type == "sandbox_confirm" {
            return "当前后端使用本地沙箱支付。确认后会走服务端支付完成逻辑，订单、积分和通知都会同步更新。"
        }
        return "请在支付服务商页面完成付款，完成后回到商城确认支付结果。"
    }

    private var confirmButtonTitle: String {
        paymentSession?.nextAction?.label ?? "确认支付结果"
    }

    private var canOpenExternalPayment: Bool {
        guard let value = paymentSession?.paymentUrl,
              URL(string: value) != nil else {
            return false
        }
        return paymentSession?.nextAction?.type == "external_redirect"
    }

    private func openPaymentAppOrPage() {
        guard let value = paymentSession?.paymentUrl,
              let url = URL(string: value) else {
            return
        }
        openURL(url)
    }

    private func methodColor(_ id: String) -> Color {
        switch id {
        case "wxpay":  return .green
        case "alipay": return .blue
        default:       return DesignSystem.Colors.accent
        }
    }
}
