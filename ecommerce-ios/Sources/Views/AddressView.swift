import SwiftUI

struct AddressView: View {
    @State private var addresses: [Address] = []
    @State private var isLoading = true
    @State private var showingAddAddress = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if addresses.isEmpty {
                    emptyState
                } else {
                    addressList
                }
            }
            .padding(.bottom, 80)

            addButton
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("地址管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddAddress = true }) {
                    Text("新增")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.accent)
                }
            }
        }
        .hideTabBar()
        .task {
            do {
                addresses = try await Address.getAddresses()
            } catch {
                print("Failed to load addresses: \(error)")
            }
            isLoading = false
        }
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
                ForEach(addresses) { address in
                    AddressCard(
                        address: address,
                        isDefault: address.isDefault,
                        onSetDefault: { Task { await setDefault(address) } },
                        onEdit: { },
                        onDelete: { Task { await deleteAddress(address) } }
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

            Button(action: { showingAddAddress = true }) {
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

    private func setDefault(_ address: Address) async {
        do {
            try await Address.setDefaultAddress(id: address.id)
            addresses = try await Address.getAddresses()
        } catch {
            print("Failed to set default address: \(error)")
        }
    }

    private func deleteAddress(_ address: Address) async {
        do {
            try await Address.deleteAddress(id: address.id)
            addresses = try await Address.getAddresses()
        } catch {
            print("Failed to delete address: \(error)")
        }
    }
}

// MARK: - Address Card
struct AddressCard: View {
    let address: Address
    let isDefault: Bool
    let onSetDefault: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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

            Text(address.fullAddress)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineLimit(2)

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

#Preview {
    NavigationStack {
        AddressView()
    }
}
