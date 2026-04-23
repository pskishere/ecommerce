import SwiftUI

struct AddressEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var province = "广东省"
    @State private var city = "广州市"
    @State private var district = "天河区"
    @State private var detail = ""
    @State private var isDefault = false

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    // Form
                    formSection

                    // Delete Button (if editing)
                    deleteButton
                }
                .padding(.bottom, 80)
            }
            .background(Color(.systemGroupedBackground))

            // Save Button
            saveButton
        }
        .navigationTitle("编辑地址")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { }) {
                    Text("保存")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
            }
        }
        .hideTabBar()
    }

    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 0) {
            // Contact Info
            Group {
                formRow(label: "收货人", placeholder: "请输入收货人姓名", text: $name)
                Divider().padding(.leading, 100)
                formRow(label: "手机号", placeholder: "请输入手机号", text: $phone, keyboardType: .phonePad)
            }

            Spacer().frame(height: 12)

            // Location
            Group {
                locationRow
                Divider().padding(.leading, 100)
                formRow(label: "详细地址", placeholder: "请输入详细地址", text: $detail)
            }

            Spacer().frame(height: 12)

            // Default Toggle
            defaultToggle
        }
        .background(Color.white)
    }

    // MARK: - Form Row
    private func formRow(label: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
                .frame(width: 80, alignment: .leading)

            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .keyboardType(keyboardType)
                .padding(.vertical, 14)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Location Row
    private var locationRow: some View {
        HStack(spacing: 0) {
            Text("所在地区")
                .font(.system(size: 15))
                .foregroundStyle(.primary)
                .frame(width: 80, alignment: .leading)

            Spacer()

            HStack(spacing: 4) {
                Text("\(province) \(city) \(district)")
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }

    // MARK: - Default Toggle
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
                .tint(accentColor)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white)
    }

    // MARK: - Delete Button
    private var deleteButton: some View {
        Button(action: { }) {
            Text("删除地址")
                .font(.system(size: 15))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .background(Color.white)
        .padding(.top, 12)
    }

    // MARK: - Save Button
    private var saveButton: some View {
        VStack(spacing: 0) {
            Divider()

            Button(action: { dismiss() }) {
                Text("保存")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(name.isEmpty ? Color.gray : accentColor)
                    .clipShape(Capsule())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .disabled(name.isEmpty)
            .background(Color(.systemBackground))
        }
    }
}

#Preview {
    NavigationStack {
        AddressEditView()
    }
}
