import SwiftUI

struct CartView: View {
    @EnvironmentObject private var cart: Cart
    @EnvironmentObject private var appNavigation: AppNavigation
    @Binding var showCheckout: Bool
    @State private var isEditMode = false
    @State private var toast: String? = nil
    @State private var swipedItemId: String?
    @State private var showCoupons = false
    @State private var showDeleteSelectedConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            cartHeader

            Group {
                if cart.isLoading && cart.items.isEmpty {
                    CartSkeletonView()
                } else if cart.isEmpty {
                    emptyState
                } else {
                    cartContent
                }
            }
        }
        .background(DesignSystem.Colors.pageBackground)
        .toast($toast, bottomPadding: 180)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showCoupons) {
            CouponView()
        }
        .confirmationDialog("删除商品", isPresented: $showDeleteSelectedConfirm, titleVisibility: .visible) {
            Button("确认删除", role: .destructive) {
                deleteSelectedItems()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("确定要删除已选中的商品吗？")
        }
        .onChange(of: cart.errorMessage) { _, message in
            if let message {
                toast = message
            }
        }
        .task {
            await cart.loadCart()
        }
    }

    private var cartHeader: some View {
        HStack {
            Text("购物车")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(DesignSystem.Colors.dark)

            Spacer()

            if !cart.isEmpty {
                Button(action: { isEditMode.toggle() }) {
                    Text(isEditMode ? "完成" : "编辑")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isEditMode ? DesignSystem.Colors.accentSoft : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(Color.white.opacity(0.96))
        .overlay(
            Rectangle()
                .fill(DesignSystem.Colors.separator)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "bag")
                .font(.system(size: 60))
                .foregroundStyle(.gray.opacity(0.4))

            Text("购物车是空的")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)

            Text("快去挑选心仪的商品吧")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.gray)

            Button(action: { appNavigation.selectedTab = .category }) {
                Text("去逛逛")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 42)
                    .background(DesignSystem.Colors.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(TactileButtonStyle())
            .padding(.top, 4)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.pageBackground)
    }

    // MARK: - Cart Content
    private var cartContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    storeSection

                    VStack(spacing: 0) {
                        ForEach(cart.items) { item in
                            SwipeToDeleteItem(
                                item: item,
                                isSwiped: swipedItemId == item.id,
                                onSwipe: { swipedItemId = item.id },
                                onDelete: {
                                    removeItem(item)
                                    swipedItemId = nil
                                },
                                onToggleSelection: {
                                    toggleItemSelection(item)
                                },
                                onDecrement: {
                                    decrementItem(item)
                                },
                                onIncrement: {
                                    incrementItem(item)
                                },
                                onDismiss: { swipedItemId = nil }
                            )
                            .padding(.horizontal, 16)

                            if item.id != cart.items.last?.id {
                                Rectangle()
                                    .fill(DesignSystem.Colors.pageBackground)
                                    .frame(height: 1)
                                    .padding(.leading, 54)
                            }
                        }
                    }
                    .background(Color.white)

                    Spacer(minLength: 160)
                }
                .padding(.top, 12)
            }

            // Bottom bar
            bottomBar
        }
    }

    // MARK: - Store Section
    private var storeSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button(action: toggleStoreSelection) {
                    H5CheckCircle(isChecked: cart.isAllSelected)
                }

                Image(systemName: "storefront")
                    .font(.system(size: 16))
                    .foregroundStyle(DesignSystem.Colors.accent)

                Text("潮流优品官方旗舰店")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()

                Button(action: { showCoupons = true }) {
                    Text("领券")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(DesignSystem.Colors.accentSoft)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .overlay(
                Rectangle()
                    .fill(Color(hex: "F0F0F0"))
                    .frame(height: 1),
                alignment: .bottom
            )
        }
        .background(Color.white)
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                // Select all
                Button(action: toggleStoreSelection) {
                    HStack(spacing: 8) {
                        H5CheckCircle(isChecked: cart.isAllSelected)

                        Text("全选")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.dark)
                    }
                }

                Spacer()

                // Total price
                VStack(alignment: .trailing, spacing: 1) {
                    Text(cart.selectedTotalPrice.rmbText)
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(DesignSystem.Colors.accent)

                    if cart.selectedCount < cart.totalItems {
                        Text("共 \(cart.totalItems) 件")
                            .font(.system(size: 11))
                            .foregroundStyle(.gray)
                    }
                }

                if isEditMode {
                    // Delete button in edit mode
                    Button(action: requestDeleteSelectedItems) {
                        Text("删除")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(DesignSystem.Colors.accent)
                            .padding(.horizontal, 24)
                            .frame(height: 44)
                            .background(Color.white)
                            .overlay(
                                Capsule()
                                    .stroke(DesignSystem.Colors.accent, lineWidth: 1.5)
                            )
                    }
                } else {
                    // Checkout button
                    Button(action: { showCheckout = true }) {
                        Text("结算(\(cart.selectedCount))")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .frame(height: 44)
                            .background(cart.hasSelectedItems ? DesignSystem.Colors.accent : DesignSystem.Colors.gray2)
                            .clipShape(Capsule())
                    }
                    .disabled(!cart.hasSelectedItems || cart.isLoading)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
            .background(Color.white.opacity(0.97))
        }
    }

    // MARK: - Actions
    private func toggleStoreSelection() {
        let nextValue = !cart.isAllSelected
        Task {
            do {
                try await cart.selectAllItems(nextValue)
                await cart.loadCart()
                toast = nextValue ? "已全选" : "已取消全选"
            } catch {
                toast = userFacingErrorMessage(error, fallback: "全选操作失败")
            }
        }
    }

    private func removeItem(_ item: CartItem) {
        Task {
            do {
                try await cart.removeItem(cartItemId: item.id)
                await cart.loadCart()
                toast = "已删除"
            } catch {
                toast = userFacingErrorMessage(error, fallback: "删除失败")
            }
        }
    }

    private func deleteSelectedItems() {
        let selected = cart.selectedItems
        let count = selected.count
        isEditMode = false
        Task {
            do {
                for item in selected {
                    try await cart.removeItem(cartItemId: item.id)
                }
                await cart.loadCart()
                toast = "已删除 \(count) 件商品"
            } catch {
                await cart.loadCart()
                toast = userFacingErrorMessage(error, fallback: "批量删除失败")
            }
        }
    }

    private func requestDeleteSelectedItems() {
        guard !cart.selectedItems.isEmpty else {
            toast = "请先选择商品"
            return
        }
        showDeleteSelectedConfirm = true
    }

    private func toggleItemSelection(_ item: CartItem) {
        Task {
            do {
                try await cart.toggleSelected(cartItemId: item.id)
                await cart.loadCart()
            } catch {
                toast = userFacingErrorMessage(error, fallback: "选择状态更新失败")
            }
        }
    }

    private func incrementItem(_ item: CartItem) {
        updateQuantity(item, quantity: item.quantity + 1)
    }

    private func decrementItem(_ item: CartItem) {
        if item.quantity > 1 {
            updateQuantity(item, quantity: item.quantity - 1)
        } else {
            removeItem(item)
        }
    }

    private func updateQuantity(_ item: CartItem, quantity: Int) {
        Task {
            do {
                try await cart.updateQuantityItem(cartItemId: item.id, quantity: quantity)
                await cart.loadCart()
            } catch {
                toast = userFacingErrorMessage(error, fallback: "数量更新失败")
            }
        }
    }
}

private struct CartSkeletonView: View {
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            SkeletonView(width: 22, height: 22)
                                .clipShape(Circle())
                            SkeletonView(width: 120, height: 16)
                            Spacer()
                            SkeletonView(width: 34, height: 14)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)

                        ForEach(0..<4, id: \.self) { _ in
                            HStack(spacing: 12) {
                                SkeletonView(width: 22, height: 22)
                                    .clipShape(Circle())
                                SkeletonView(width: 88, height: 88)
                                VStack(alignment: .leading, spacing: 10) {
                                    SkeletonView(height: 15)
                                    SkeletonView(width: 96, height: 14)
                                    Spacer()
                                    HStack {
                                        SkeletonView(width: 68, height: 18)
                                        Spacer()
                                        SkeletonView(width: 96, height: 32)
                                    }
                                }
                                .frame(height: 88)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                    }
                    .background(Color.white)
                    .padding(.top, 12)
                    Spacer(minLength: 160)
                }
            }

            VStack(spacing: 0) {
                Divider()
                HStack {
                    SkeletonView(width: 64, height: 20)
                    Spacer()
                    SkeletonView(width: 88, height: 24)
                    SkeletonView(width: 104, height: 44)
                }
                .padding(.horizontal, 16)
                .frame(height: 60)
                .background(Color.white.opacity(0.97))
            }
        }
        .background(DesignSystem.Colors.pageBackground)
    }
}

// MARK: - Swipe To Delete Item
struct SwipeToDeleteItem: View {
    let item: CartItem
    let isSwiped: Bool
    let onSwipe: () -> Void
    let onDelete: () -> Void
    let onToggleSelection: () -> Void
    let onDecrement: () -> Void
    let onIncrement: () -> Void
    let onDismiss: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isDragging = false

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button behind
            HStack {
                Spacer()
                Button(action: onDelete) {
                    Text("删除")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 78)
                }
                .frame(maxHeight: .infinity)
                .background(Color(red: 1.0, green: 0.29, blue: 0.29))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Product card
            CartItemRow(
                item: item,
                isSwiped: isSwiped,
                onToggleSelection: {
                    onToggleSelection()
                },
                onDecrement: {
                    onDecrement()
                },
                onIncrement: {
                    onIncrement()
                }
            )
            .background(Color.white)
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            offset = max(value.translation.width, -80)
                        }
                    }
                    .onEnded { value in
                        if value.translation.width < -40 {
                            withAnimation(.spring(duration: 0.25)) {
                                offset = -80
                            }
                            onSwipe()
                        } else {
                            withAnimation(.spring(duration: 0.25)) {
                                offset = 0
                            }
                            onDismiss()
                        }
                    }
            )
        }
        .onTapGesture {
            if isSwiped {
                withAnimation(.spring(duration: 0.25)) {
                    offset = 0
                }
                onDismiss()
            }
        }
    }
}

// MARK: - Cart Item Row
struct CartItemRow: View {
    let item: CartItem
    var isSwiped: Bool = false
    let onToggleSelection: () -> Void
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    @EnvironmentObject private var cart: Cart

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggleSelection) {
                H5CheckCircle(isChecked: item.isSelected)
            }

            NavigationLink(destination: ProductDetailView(product: item.product)) {
                AsyncImage(url: item.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 88, height: 88)
                        .clipped()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.1))
                }
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            // Product info
            VStack(alignment: .leading, spacing: 4) {
                NavigationLink(destination: ProductDetailView(product: item.product)) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.product.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        if let spec = item.spec, !spec.isEmpty {
                            Text(spec)
                                .font(.system(size: 11))
                                .foregroundStyle(DesignSystem.Colors.gray2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(DesignSystem.Colors.pageBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(.plain)

                HStack {
                    Text(item.displayPrice.rmbText)
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(DesignSystem.Colors.accent)

                    Spacer()

                    quantityControls
                }
            }
        }
        .padding(.vertical, 14)
        .background(Color.white)
    }

    private var quantityControls: some View {
        HStack(spacing: 0) {
            Button(action: onDecrement) {
                Text("−")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.gray)
                    .frame(width: 32, height: 32)
            }

            Text("\(item.quantity)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primary)
                .frame(width: 36)

            Button(action: onIncrement) {
                Text("+")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.gray)
                    .frame(width: 32, height: 32)
            }
        }
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct H5CheckCircle: View {
    let isChecked: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isChecked ? DesignSystem.Colors.accent : Color.clear)
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .stroke(isChecked ? DesignSystem.Colors.accent : Color(hex: "DDDDDD"), lineWidth: 2)
                )

            if isChecked {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 22, height: 22)
    }
}

#Preview {
    NavigationStack {
        CartView(showCheckout: .constant(false))
            .environmentObject(Cart())
    }
}
