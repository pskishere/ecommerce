import SwiftUI

struct AddressEditView: View {
    let address: Address?
    var onSaved: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var phone: String
    @State private var province: String
    @State private var city: String
    @State private var district: String
    @State private var detail: String
    @State private var isDefault: Bool
    @State private var regionData: [String: [String: [String]]] = [:]
    @State private var showRegionPicker = false
    @State private var isSaving = false
    @State private var toast: String? = nil

    init(address: Address? = nil, onSaved: (() -> Void)? = nil) {
        self.address = address
        self.onSaved = onSaved
        _name = State(initialValue: address?.name ?? "")
        _phone = State(initialValue: address?.phone ?? "")
        _province = State(initialValue: address?.province ?? "")
        _city = State(initialValue: address?.city ?? "")
        _district = State(initialValue: address?.district ?? "")
        _detail = State(initialValue: address?.detail ?? "")
        _isDefault = State(initialValue: address?.isDefault ?? false)
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 0) {
                        formSection

                        if address != nil {
                            deleteButton
                        }
                    }
                    .padding(.bottom, 80)
                }
                .background(DesignSystem.Colors.pageBackground)

                saveButton
            }
        }
        .toast($toast, bottomPadding: 96)
        .navigationTitle(address == nil ? "新增地址" : "编辑地址")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { Task { await saveAddress() } }) {
                    Text(isSaving ? "保存中..." : "保存")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(canSubmit ? DesignSystem.Colors.accent : Color.gray)
                }
                .disabled(!canSubmit || isSaving)
            }
        }
        .sheet(isPresented: $showRegionPicker) {
            RegionPickerSheet(
                regionData: regionData,
                province: $province,
                city: $city,
                district: $district
            )
        }
        .task {
            await loadRegions()
        }
        .hideTabBar()
    }

    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 0) {
            Group {
                formRow(label: "收货人", placeholder: "请输入收货人姓名", text: $name)
                Divider().padding(.leading, 100)
                formRow(label: "手机号", placeholder: "请输入手机号", text: $phone, keyboardType: .phonePad)
            }

            Spacer().frame(height: 12)

            Group {
                locationRow
                Divider().padding(.leading, 100)
                formRow(label: "详细地址", placeholder: "请输入详细地址", text: $detail)
            }

            Spacer().frame(height: 12)
            defaultToggle
        }
        .background(Color.white)
    }

    private func formRow(label: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
                .frame(width: 80, alignment: .leading)

            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .padding(.vertical, 14)
        }
        .padding(.horizontal, 16)
    }

    private var locationRow: some View {
        Button(action: { showRegionPicker = true }) {
            HStack(spacing: 0) {
                Text("所在地区")
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .frame(width: 80, alignment: .leading)

                Spacer()

                Text(regionText)
                    .font(.system(size: 15))
                    .foregroundStyle(hasRegion ? .primary : .secondary)
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 6)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    private var defaultToggle: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("设为默认地址")
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)

                Text("便捷购物时无需重复选择")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isDefault)
                .labelsHidden()
                .tint(DesignSystem.Colors.accent)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white)
    }

    private var deleteButton: some View {
        Button(role: .destructive, action: { Task { await deleteAddress() } }) {
            Text("删除地址")
                .font(.system(size: 15))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .background(Color.white)
        .padding(.top, 12)
    }

    private var saveButton: some View {
        VStack(spacing: 0) {
            Divider()

            Button(action: { Task { await saveAddress() } }) {
                Text(isSaving ? "保存中..." : "保存")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(canSubmit ? DesignSystem.Colors.accent : Color.gray)
                    .clipShape(Capsule())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .disabled(!canSubmit || isSaving)
            .background(Color(.systemBackground))
        }
    }

    private var hasRegion: Bool {
        !province.isEmpty && !city.isEmpty && !district.isEmpty
    }

    private var regionText: String {
        hasRegion ? "\(province) \(city) \(district)" : "请选择省市区"
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        hasRegion &&
        !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func loadRegions() async {
        do {
            regionData = try await Address.getRegion()
        } catch {
            regionData = [:]
        }
    }

    private func validate() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            toast = "请输入收货人姓名"
            return false
        }
        if trimmedPhone.range(of: #"^1\d{10}$"#, options: .regularExpression) == nil {
            toast = "请输入正确的手机号"
            return false
        }
        if !hasRegion {
            toast = "请选择完整的省市区"
            return false
        }
        if trimmedDetail.count < 5 {
            toast = "详细地址不能少于5个字符"
            return false
        }
        return true
    }

    private func saveAddress() async {
        guard validate() else { return }
        isSaving = true
        let payload = Address(
            id: address?.id ?? "",
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            province: province,
            city: city,
            district: district,
            detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
            isDefault: isDefault
        )

        do {
            if address == nil {
                try await Address.createAddress(payload)
            } else {
                try await Address.updateAddress(payload)
            }
            onSaved?()
            dismiss()
        } catch {
            toast = "保存失败，请重试"
        }
        isSaving = false
    }

    private func deleteAddress() async {
        guard let address else { return }
        isSaving = true
        do {
            try await Address.deleteAddress(id: address.id)
            onSaved?()
            dismiss()
        } catch {
            toast = "删除失败，请重试"
        }
        isSaving = false
    }
}

private struct RegionPickerSheet: View {
    let regionData: [String: [String: [String]]]
    @Binding var province: String
    @Binding var city: String
    @Binding var district: String
    @Environment(\.dismiss) private var dismiss

    private var provinces: [String] {
        regionData.keys.sorted()
    }

    private var cities: [String] {
        guard !province.isEmpty else { return [] }
        return (regionData[province]?.keys.sorted()) ?? []
    }

    private var districts: [String] {
        guard !province.isEmpty, !city.isEmpty else { return [] }
        return regionData[province]?[city] ?? []
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("省", selection: $province) {
                    Text("请选择省").tag("")
                    ForEach(provinces, id: \.self) { Text($0).tag($0) }
                }
                .onChange(of: province) { _, _ in
                    city = ""
                    district = ""
                }

                Picker("市", selection: $city) {
                    Text("请选择市").tag("")
                    ForEach(cities, id: \.self) { Text($0).tag($0) }
                }
                .disabled(province.isEmpty)
                .onChange(of: city) { _, _ in
                    district = ""
                }

                Picker("区", selection: $district) {
                    Text("请选择区").tag("")
                    ForEach(districts, id: \.self) { Text($0).tag($0) }
                }
                .disabled(city.isEmpty)
            }
            .navigationTitle("选择地区")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                        .disabled(province.isEmpty || city.isEmpty || district.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    NavigationStack {
        AddressEditView()
    }
}
