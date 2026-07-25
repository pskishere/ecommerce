import PhotosUI
import SwiftUI
import UIKit

struct ProfileInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var nickname = ""
    @State private var gender = "保密"
    @State private var birthday = "未填写"
    @State private var selectedBirthday = Date()
    @State private var email = ""
    @State private var phone = ""
    @State private var avatarURL: URL?
    @State private var selectedAvatarItem: PhotosPickerItem?
    @State private var avatarImageData: Data?
    @State private var showGenderPicker = false
    @State private var showBirthdayPicker = false
    @State private var isSaving = false
    @State private var toast: String? = nil


    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    // Avatar Section
                    avatarSection

                    // Form Section
                    formSection
                }
            }
        }
        .background(DesignSystem.Colors.pageBackground)
        .navigationTitle("个人信息")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { Task { await saveProfile() } }) {
                    if isSaving {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Text("保存")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.accent)
                    }
                }
                .disabled(isSaving)
            }
        }
        .hideTabBar()
        .toast($toast, bottomPadding: 80)
        .sheet(isPresented: $showGenderPicker) {
            GenderPickerSheet(selectedGender: $gender)
        }
        .sheet(isPresented: $showBirthdayPicker) {
            BirthdayPickerSheet(selectedDate: $selectedBirthday) { date in
                birthday = Self.dateFormatter.string(from: date)
            } onClear: {
                birthday = "未填写"
            }
        }
        .onChange(of: selectedAvatarItem) { _, item in
            Task { await loadAvatarImage(item) }
        }
        .task { await loadProfile() }
    }

    private func loadProfile() async {
        do {
            let user = try await User.getProfile()
            nickname = user.name
            email = user.email
            phone = user.phone
            gender = user.genderLabel
            birthday = user.birthday.isEmpty ? "未填写" : user.birthday
            avatarURL = URL(string: user.avatarName)
            if let date = Self.dateFormatter.date(from: user.birthday) {
                selectedBirthday = date
            }
        } catch {
            toast = userFacingErrorMessage(error, fallback: "个人信息加载失败")
        }
    }

    private func saveProfile() async {
        guard validateProfile() else { return }
        isSaving = true
        do {
            _ = try await User.updateProfile(
                username: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
                gender: gender,
                birthday: birthday == "未填写" ? "" : birthday,
                avatar: avatarPayload
            )
            dismiss()
        } catch {
            toast = userFacingErrorMessage(error, fallback: "保存失败")
        }
        isSaving = false
    }

    private func validateProfile() -> Bool {
        let trimmedName = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            toast = "请输入昵称"
            return false
        }
        if !trimmedEmail.isEmpty,
           trimmedEmail.range(of: #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#, options: [.regularExpression, .caseInsensitive]) == nil {
            toast = "请输入正确的邮箱"
            return false
        }
        if !trimmedPhone.isEmpty,
           trimmedPhone.range(of: #"^1\d{10}$"#, options: .regularExpression) == nil {
            toast = "请输入正确的手机号"
            return false
        }
        return true
    }

    // MARK: - Avatar Section
    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                ProfileAvatarImage(data: avatarImageData, url: avatarURL)

                PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(DesignSystem.Colors.accent)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            PhotosPicker(selection: $selectedAvatarItem, matching: .images) {
                Text("修改头像")
                    .font(.system(size: 13))
                    .foregroundStyle(DesignSystem.Colors.accent)
            }
            .buttonStyle(.plain)
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
            Button(action: { showBirthdayPicker = true }) {
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
        formRow(label: "手机号", value: $phone, placeholder: "请输入手机号")
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

private extension ProfileInfoView {
    var avatarPayload: String? {
        guard let avatarImageData else { return nil }
        return "data:image/jpeg;base64,\(avatarImageData.base64EncodedString())"
    }

    func loadAvatarImage(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let rawData = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: rawData),
                  let jpegData = image.jpegData(compressionQuality: 0.82) else {
                await MainActor.run { toast = "头像读取失败" }
                return
            }
            await MainActor.run {
                avatarImageData = jpegData
            }
        } catch {
            await MainActor.run {
                toast = userFacingErrorMessage(error, fallback: "头像读取失败")
            }
        }
    }

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
}

private struct ProfileAvatarImage: View {
    let data: Data?
    let url: URL?

    var body: some View {
        if let data, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.gray)
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                )
        }
    }
}

// MARK: - Gender Picker Sheet
struct GenderPickerSheet: View {
    @Binding var selectedGender: String
    @Environment(\.dismiss) private var dismiss


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
                                    .foregroundStyle(DesignSystem.Colors.accent)
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
                    .foregroundStyle(DesignSystem.Colors.accent)
                }
            }
        }
        .presentationDetents([.height(200)])
    }
}

// MARK: - Birthday Picker Sheet
struct BirthdayPickerSheet: View {
    @Binding var selectedDate: Date
    let onDone: (Date) -> Void
    let onClear: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DatePicker(
                "生日",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle("选择生日")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("清空") {
                        onClear()
                        dismiss()
                    }
                    .foregroundStyle(Color(.secondaryLabel))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        onDone(selectedDate)
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.accent)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileInfoView()
    }
}
