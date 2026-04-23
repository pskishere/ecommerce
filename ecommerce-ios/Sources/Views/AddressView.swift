import SwiftUI

struct AddressView: View {
    @StateObject private var viewModel = AddressViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Address List
                if viewModel.addresses.isEmpty {
                    emptyState
                } else {
                    addressList
                }
            }
            .padding(.bottom, 80)

            // Bottom Add Button
            addButton
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("地址管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Text("新增")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.accent)
                }
            }
        }
        .hideTabBar()
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "location.slash")
                .font(.system(size: 60))
                .foregroundStyle(.gray.opacity(0.4))

            Text("暂无收货地址")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Address List
    private var addressList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.addresses) { address in
                    AddressCard(
                        address: address,
                        isDefault: address.isDefault,
                        onSetDefault: { viewModel.setDefault(address) },
                        onEdit: { },
                        onDelete: { viewModel.deleteAddress(address) }
                    )
                }
            }
            .padding(12)
        }
    }

    // MARK: - Add Button
    private var addButton: some View {
        VStack(spacing: 0) {
            Divider()

            Button(action: {}) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("新增地址")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(DesignSystem.Colors.accent)
                .clipShape(Capsule())
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Address Card
struct AddressCard: View {
    let address: AddressItem
    let isDefault: Bool
    let onSetDefault: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(address.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(address.phone)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                Spacer()

                if isDefault {
                    Text("默认")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            // Detail
            Text(address.detail)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineLimit(2)

            // Footer
            HStack {
                Button(action: onSetDefault) {
                    HStack(spacing: 4) {
                        Image(systemName: isDefault ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18))
                        Text(isDefault ? "默认地址" : "设为默认")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(isDefault ? DesignSystem.Colors.accent : .secondary)
                }

                Spacer()

                HStack(spacing: 16) {
                    Button(action: onEdit) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14))
                            Text("编辑")
                                .font(.system(size: 13))
                        }
                        .foregroundStyle(.secondary)
                    }

                    Button(action: onDelete) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                            Text("删除")
                                .font(.system(size: 13))
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Address Item Model
struct AddressItem: Identifiable {
    let id: UUID
    let name: String
    let phone: String
    let detail: String
    let isDefault: Bool
}

// MARK: - Address ViewModel
class AddressViewModel: ObservableObject {
    @Published var addresses: [AddressItem] = [
        AddressItem(
            id: UUID(),
            name: "林小琳",
            phone: "138****8888",
            detail: "广东省广州市天河区珠江新城花城大道88号华夏中心A栋1501室",
            isDefault: true
        ),
        AddressItem(
            id: UUID(),
            name: "林小琳",
            phone: "139****9999",
            detail: "广东省深圳市南山区科技园南区深南大道9996号松日鼎盛大厦8楼",
            isDefault: false
        )
    ]

    func setDefault(_ address: AddressItem) {
        addresses = addresses.map {
            AddressItem(
                id: $0.id,
                name: $0.name,
                phone: $0.phone,
                detail: $0.detail,
                isDefault: $0.id == address.id
            )
        }
    }

    func deleteAddress(_ address: AddressItem) {
        addresses.removeAll { $0.id == address.id }
    }
}

#Preview {
    NavigationStack {
        AddressView()
    }
}
