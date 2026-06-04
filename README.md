# KIDIO CLIENT (Mobile App)

Tài liệu tóm tắt tiến độ và hướng dẫn kỹ thuật cho dự án KIDIO (Frontend - Flutter).

---

## 1. Tổng quan hệ thống

### Mục tiêu project
- Ứng dụng di động học tiếng Anh dành cho trẻ em với trải nghiệm người dùng sinh động.
- Giao diện được thiết kế theo phong cách "Khan Academy Kids": màu sắc tươi sáng, bo tròn, icon trực quan.
- Tích hợp đa phương tiện: văn bản truyện, thẻ từ vựng sinh động và phát âm thanh.

### Đối tượng sử dụng
- **Phụ huynh:** Đăng ký tài khoản, đăng nhập xác thực.
- **Trẻ em:** Tham gia các cuộc phiêu lưu học tập qua danh sách chủ đề và bài học.

### Công nghệ sử dụng
- **Framework:** Flutter (Dart)
- **State Management:** `Provider` (kết hợp `ChangeNotifierProxyProvider`)
- **Networking:** `Dio` (với cấu hình Interceptor, Logger và Timeout)
- **Local Storage/Cache:** `Hive` (Lưu cache bài học), `Flutter Secure Storage` (Lưu JWT Token)
- **Media:** `AudioPlayers` (phát âm thanh), `CachedNetworkImage` (tối ưu tải ảnh)
- **Authentication:** `Google Sign-In SDK`

---

## 2. Phân tích chức năng (Frontend)

### Danh sách chức năng đã hoàn thành
- **Authentication:** 
    - Đăng nhập Google (OAuth2).
    - Đăng ký tài khoản mới (Email, Password, Name).
    - Đăng nhập thông thường bằng tài khoản Kidio.
    - Tự động khôi phục phiên đăng nhập (Restore Session).
- **Chủ đề (Topics):**
    - Hiển thị danh sách dạng Grid 2 cột sinh động.
    - Hiển thị số lượng bài học thực tế từ Backend.
- **Bài học (Lessons):**
    - Danh sách bài học theo số thứ tự màu sắc.
    - Màn hình chi tiết bài học với layout truyện và danh sách từ vựng cuộn ngang (Horizontal List).
- **Hạ tầng mạng:**
    - Bypass SSL cho Server Local.
    - Tự động làm mới Token (Refresh Token Interceptor).
    - Chế độ Offline: Tự động hiển thị dữ liệu từ cache khi mất mạng.

---

## 3. Cấu hình kết nối & Hệ thống

### Thông số Backend
- **Base URL:** `https://192.168.88.147:7014/api/` (IP máy chủ local).
- **Timeout:** 30 giây (đảm bảo các thao tác đăng ký không bị ngắt).
- **SSL Security:** Đã cấu hình `badCertificateCallback` để chấp nhận chứng chỉ HTTPS tự ký từ máy tính cá nhân.

### Google OAuth2 Configuration
- **Project ID:** `374569495508` (Thống nhất dùng chung với Backend).
- **Client ID:** `374569495508-vuonlvgep7ike3cps4f8n1bsv88v2kgm.apps.googleusercontent.com`
- **Android Integration:** Đã đăng ký mã SHA-1 của máy dev vào Google Cloud Console.

---

## 4. Kiến trúc mã nguồn (Project Structure)

- `lib/api/` — Cấu hình `ApiClient` (Dio), xử lý SSL và Interceptors.
- `lib/models/` — Các thực thể dữ liệu (`Topic`, `Lesson`, `Vocabulary`) khớp với DTO của Backend.
- `lib/providers/` — Quản lý trạng thái ứng dụng:
    - `AuthProvider`: Xử lý đăng nhập/đăng ký/đăng xuất.
    - `TopicProvider`: Quản lý danh sách chủ đề, phân trang và trạng thái offline.
- `lib/repositories/` — Lớp trung gian xử lý logic lấy dữ liệu (API vs Cache).
- `lib/screens/` — Giao diện người dùng (Login, Register, TopicsList, LessonDetail).
- `lib/services/` — Gọi API trực tiếp (`AuthApi`).
- `lib/local/` — Dịch vụ lưu trữ cache bằng Hive (`CacheService`).
- `lib/utils/` — Các hàm xử lý nội dung, parser.

---

## 5. Luồng hoạt động chính

### Luồng Đăng nhập (Auth Flow)
1. User chọn Login Google hoặc gõ Email/Password.
2. `AuthProvider` gọi `AuthRepository` -> `AuthApi` thực hiện gửi request tới Backend.
3. Nhận về `accessToken` và `refreshToken`, lưu vào `SecureStorage`.
4. `ApiClient` được cập nhật Header `Authorization: Bearer <token>`.

### Luồng Học tập (Learning Flow)
1. App gọi `GET /api/Topics` để hiển thị Grid chủ đề.
2. Khi chọn Topic, gọi `GET /api/Topics/{id}` để lấy danh sách bài học.
3. Khi chọn Lesson, gọi `GET /api/Lessons/{id}` để lấy nội dung `contentJson` và `audioUrl`.
4. Toàn bộ dữ liệu này được lưu vào `Hive Box` để phục vụ xem offline lần sau.

---

## 6. Hướng dẫn chạy dự án (Local Development)

### Yêu cầu
- Flutter SDK >= 3.0.0
- Android Studio / VS Code
- Thiết bị thật Android (Khuyến nghị cắm dây USB để dùng Hot Reload).

### Các bước thực hiện
1. **Kiểm tra IP:** Đảm bảo máy tính và điện thoại chung Wi-Fi. Cập nhật IPv4 vào `lib/api/api_client.dart` nếu cần.
2. **Cài đặt thư viện:**
   ```bash
   flutter pub get
   ```
3. **Chạy ứng dụng:**
   ```bash
   flutter run
   ```
4. **Hot Reload:** Nhấn `r` (trong terminal) hoặc biểu tượng tia sét (trong IDE) để cập nhật UI ngay lập tức.

---

## Tệp quan trọng cần chú ý
- `lib/api/api_client.dart` — Nơi đổi địa chỉ IP của Server.
- `lib/screens/login_screen.dart` — Chứa cấu hình Google Client ID.
- `google-services.json` — File cấu hình định danh Firebase/Google.

---

*Tài liệu này sẽ được cập nhật liên tục theo tiến độ của dự án.*
