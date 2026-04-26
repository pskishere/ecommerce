import SwiftUI

struct CartView: View {
    @EnvironmentObject private var cart: Cart
    @Binding var showCheckout: Bool
    @State private var isEditMode = false
    @State private var showingToast = false
    @State private var toastMessage = ""
    @State private var swipedItemId: String?

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

    var body: some View {
        ZStack(alignment: .top) {
            if cart.isEmpty {
                emptyState
            } else {
                cartContent
            }

            // Toast overlay
            if showingToast {
                toastView
            }
        }
        .navigationTitle("购物车")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isEditMode.toggle() }) {
                    Text(isEditMode ? "完成" : "编辑")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
            }
        }
        .task {
            await cart.loadCart()
        }
    }

    // MARK: - Toast
    private var toastView: some View {
        VStack {
            Spacer()
            Text(toastMessage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.75))
                .clipShape(Capsule())
                .padding(.bottom, 180)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(.spring(duration: 0.35), value: showingToast)
    }

    private func showToast(_ message: String) {
        toastMessage = message
        withAnimation {
            showingToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showingToast = false
            }
        }
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

            Spacer()
        }
    }

    // MARK: - Cart Content
    private var cartContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    // Store section
                    storeSection

                    // Cart items with swipe-to-delete
                    ForEach(cart.items) { item in
                        SwipeToDeleteItem(
                            item: item,
                            isSwiped: swipedItemId == item.id,
                            onSwipe: { swipedItemId = item.id },
                            onDelete: {
                                removeItem(item)
                                swipedItemId = nil
                            },
                            onDismiss: { swipedItemId = nil }
                        )
                    }

                    Spacer(minLength: 160)
                }
                .padding(.top, 8)
            }

            // Bottom bar
            bottomBar
        }
    }

    // MARK: - Store Section
    private var storeSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                // Store checkbox
                Button(action: toggleStoreSelection) {
                    Image(systemName: cart.isAllSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(cart.isAllSelected ? accentColor : .gray)
                }

                Image(systemName: "storefront")
                    .font(.system(size: 16))
                    .foregroundStyle(accentColor)

                Text("潮流优品官方旗舰店")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()

                Text("领券")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accentColor)
            }
            .padding(14)
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
                        Image(systemName: cart.isAllSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundStyle(cart.isAllSelected ? accentColor : .gray)

                        Text("全选")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }

                Spacer()

                // Total price
                VStack(alignment: .trailing, spacing: 1) {
                    Text("¥\(cart.selectedTotalPrice as NSDecimalNumber)")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(accentColor)

                    if cart.selectedCount < cart.totalItems {
                        Text("共 \(cart.totalItems) 件")
                            .font(.system(size: 11))
                            .foregroundStyle(.gray)
                    }
                }

                if isEditMode {
                    // Delete button in edit mode
                    Button(action: deleteSelectedItems) {
                        Text("删除")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 24)
                            .frame(height: 44)
                            .background(Color.white)
                            .overlay(
                                Capsule()
                                    .stroke(accentColor, lineWidth: 1.5)
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
                            .background(cart.hasSelectedItems ? accentColor : Color.gray)
                            .clipShape(Capsule())
                    }
                    .disabled(!cart.hasSelectedItems)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Actions
    private func toggleStoreSelection() {
        cart.selectAll(!cart.isAllSelected)
    }

    private func removeItem(_ item: CartItem) {
        cart.removeFromCart(item.product)
        showToast("已删除")
    }

    private func deleteSelectedItems() {
        let selected = cart.selectedItems
        if selected.isEmpty {
            showToast("请先选择商品")
            return
        }
        for item in selected {
            cart.removeFromCart(item.product)
        }
        showToast("已删除 \(selected.count) 件商品")
        isEditMode = false
    }
}

// MARK: - Swipe To Delete Item
struct SwipeToDeleteItem: View {
    let item: CartItem
    let isSwiped: Bool
    let onSwipe: () -> Void
    let onDelete: () -> Void
    let onDismiss: () -> Void

    @EnvironmentObject private var cart: Cart
    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

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
            }

            // Product card
            CartItemRow(
                item: item,
                isSwiped: isSwiped,
                onToggleSelection: {
                    cart.toggleSelection(for: item.product)
                },
                onDecrement: {
                    if item.quantity > 1 {
                        cart.decrementQuantity(for: item.product)
                    } else {
                        onDelete()
                    }
                },
                onIncrement: {
                    cart.incrementQuantity(for: item.product)
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
    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggleSelection) {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(item.isSelected ? accentColor : .gray)
            }

            // Product image
            AsyncImage(url: item.product.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 88, height: 88)
                    .clipped()
            } placeholder: {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.1))
            }
            .frame(width: 88, height: 88)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Product info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.product.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                // Spec badge
                Text("黑色经典款 / 标准版")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                HStack {
                    Text("¥\(item.product.price)")
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(accentColor)

                    Spacer()

                    quantityControls
                }
            }
        }
        .padding(14)
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

#Preview {
    NavigationStack {
        CartView(showCheckout: .constant(false))
            .environmentObject(Cart())
    }
}
