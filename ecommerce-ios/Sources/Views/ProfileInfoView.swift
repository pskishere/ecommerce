import SwiftUI

struct ProfileInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var nickname = "林小琳"
    @State private var gender = "女"
    @State private var birthday = "1998-06-15"
    @State private var email = "linxiaolin@email.com"
    @State private var showGenderPicker = false

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Avatar Section
                avatarSection

                // Form Section
                formSection
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("个人信息")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { dismiss() }) {
                    Text("保存")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
            }
        }
        .hideTabBar()
        .sheet(isPresented: $showGenderPicker) {
            GenderPickerSheet(selectedGender: $gender)
        }
    }

    // MARK: - Avatar Section
    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.gray)
                    )

                Button(action: {}) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(accentColor)
                        .clipShape(Circle())
                }
            }

            Button(action: {}) {
                Text("修改头像")
                    .font(.system(size: 13))
                    .foregroundStyle(accentColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.white)
    }

    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 0) {
            // Nickname
            formRow(label: "昵称", value: $nickname)

            Divider().padding(.leading, 100)

            // Gender
            Button(action: { showGenderPicker = true }) {
                HStack {
                    Text("性别")
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                        .frame(width: 80, alignment: .leading)

                    Spacer()

                    Text(gender)
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }

            Divider().padding(.leading, 100)

            // Birthday
            Button(action: {}) {
                HStack {
                    Text("生日")
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)
                        .frame(width: 80, alignment: .leading)

                    Spacer()

                    Text(birthday)
                        .font(.system(size: 15))
                        .foregroundStyle(.primary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }

            Divider().padding(.leading, 100)

            // Email
            formRow(label: "邮箱", value: $email, placeholder: "请输入邮箱")

            Spacer().frame(height: 12)

            // Phone Section
            phoneSection
        }
        .background(Color.white)
    }

    // MARK: - Phone Section
    private var phoneSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("手机号")
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .frame(width: 80, alignment: .leading)

                Text("138****8888")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: {}) {
                    Text("更换")
                        .font(.system(size: 13))
                        .foregroundStyle(accentColor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Form Row
    private func formRow(label: String, value: Binding<String>, placeholder: String = "") -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
                .frame(width: 80, alignment: .leading)

            TextField(placeholder.isEmpty ? label : placeholder, text: value)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Gender Picker Sheet
struct GenderPickerSheet: View {
    @Binding var selectedGender: String
    @Environment(\.dismiss) private var dismiss

    private let accentColor = Color(red: 1.0, green: 0.42, blue: 0.29)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ForEach(["男", "女", "保密"], id: \.self) { gender in
                    Button(action: {
                        selectedGender = gender
                        dismiss()
                    }) {
                        HStack {
                            Text(gender)
                                .font(.system(size: 16))
                                .foregroundStyle(.primary)

                            Spacer()

                            if selectedGender == gender {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(accentColor)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }

                    if gender != "保密" {
                        Divider()
                            .padding(.leading, 20)
                    }
                }
            }
            .background(Color.white)
            .navigationTitle("选择性别")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundStyle(accentColor)
                }
            }
        }
        .presentationDetents([.height(200)])
    }
}

#Preview {
    NavigationStack {
        ProfileInfoView()
    }
}
