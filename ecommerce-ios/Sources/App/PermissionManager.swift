import AVFoundation
import Photos
import CoreLocation
import UserNotifications

// MARK: - Permission Manager
@MainActor
final class PermissionManager: ObservableObject {
    static let shared = PermissionManager()

    @Published var cameraStatus: AVAuthorizationStatus = .notDetermined
    @Published var photoLibraryStatus: PHAuthorizationStatus = .notDetermined
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()

    private init() {
        refreshStatuses()
    }

    func refreshStatuses() {
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        photoLibraryStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        locationStatus = locationManager.authorizationStatus
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationStatus = settings.authorizationStatus
        }
    }

    // MARK: - Camera
    func requestCamera() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard status == .notDetermined else {
            return status == .authorized
        }
        return await AVCaptureDevice.requestAccess(for: .video)
    }

    // MARK: - Photo Library
    func requestPhotoLibrary() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .notDetermined else {
            return status == .authorized || status == .limited
        }
        let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return newStatus != .denied
    }

    // MARK: - Location
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Notification
    func requestNotification() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    // MARK: - Check Status
    var isCameraAuthorized: Bool { cameraStatus == .authorized }
    var isPhotoLibraryAuthorized: Bool { photoLibraryStatus == .authorized || photoLibraryStatus == .limited }
    var isLocationAuthorized: Bool { locationStatus == .authorizedWhenInUse || locationStatus == .authorizedAlways }
    var isNotificationAuthorized: Bool { notificationStatus == .authorized }
}
