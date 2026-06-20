# TỔNG HỢP CÁC LỖI THƯỜNG GẶP VÀ CÁCH XỬ LÝ (TROUBLESHOOTING GUIDE)

Tài liệu này tổng hợp các lỗi kỹ thuật (Bugs & Exceptions) phổ biến có thể xảy ra trong quá trình chạy và Demo dự án KIDIO, cũng như phương án khắc phục (Fix) ngay lập tức để không bị lúng túng khi Thầy Cô hỏi.

---

## 1. NHÓM LỖI KẾT NỐI MẠNG (NETWORK ERRORS)

### Lỗi 1.1: `SocketException: Connection refused` hoặc `TimeoutException`
*   **Biểu hiện:** Bấm nút Đăng nhập thì vòng tròn cứ xoay mãi, hoặc hiện thông báo "Lỗi kết nối máy chủ", "Không thể kết nối đến máy chủ".
*   **Nguyên nhân chính:**
    1. Điện thoại/Máy ảo và Laptop **không dùng chung một mạng WiFi**.
    2. Chưa sửa địa chỉ IP trong file `api_client.dart` trùng với IP mạng hiện tại của Laptop.
    3. Tường lửa (Windows Defender Firewall) đang chặn cổng `7014`.
*   **Cách Fix ngay lúc Demo:**
    - Cầm điện thoại lên kiểm tra xem có đang xài mạng 4G không, tắt 4G và bắt đúng cục WiFi mà Laptop đang bắt.
    - Vào `cmd` -> gõ `ipconfig` -> lấy IPv4 dán đè vào dòng `static const String _baseUrl` trong `lib/api/api_client.dart`.
    - Dừng app và chạy lại `flutter run`.

### Lỗi 1.2: `HandshakeException: CERTIFICATE_VERIFY_FAILED`
*   **Biểu hiện:** Flutter chặn không cho gọi API vì Backend chạy `https` (Local) nhưng không có chứng chỉ SSL hợp lệ.
*   **Tình trạng:** **ĐÃ FIX THÀNH CÔNG TRONG CODE.**
*   **Cách giải thích với Thầy (Ăn điểm):** "Vì em chạy môi trường Development bằng HTTPS nội bộ (IP LAN) nên không có chứng chỉ SSL thật. Em đã cấu hình trong `api_client.dart` đoạn `badCertificateCallback = (cert, host, port) => true;` để Bypass (bỏ qua) bắt buộc chứng chỉ SSL ở môi trường Dev, giúp app chạy trơn tru."

---

## 2. NHÓM LỖI ĐĂNG NHẬP & XÁC THỰC (AUTH ERRORS)

### Lỗi 2.1: `PlatformException(sign_in_failed)` khi Đăng nhập bằng Google
*   **Biểu hiện:** Bấm nút "Đăng nhập Google", không hiện ra bảng chọn Email mà văng thẳng về trang cũ.
*   **Nguyên nhân:** Lỗi kinh điển của Firebase. Mã máy tính (mã SHA-1) đang chạy app không được khai báo trên server Google Firebase.
*   **Cách Fix:**
    - Nếu máy bạn chạy bình thường nhưng sang máy bạn khác (hoặc máy Thầy) bị lỗi này, hãy tự tin trả lời: *"Dạ chức năng Google Login bắt buộc phải xác thực chữ ký SHA-1 của đúng cái máy tính đang biên dịch code. Máy của em đã được đăng ký mã SHA-1 lên Firebase Console nên chạy được, còn máy chạy môi trường mới thì cần copy mã SHA-1 của máy đó add vào Firebase là sẽ hoạt động bình thường ạ."*
### Lỗi 2.2: Văng 2 hộp thoại mã PIN đè lên nhau sau khi Xác thực Email/Google
*   **Biểu hiện:** Sau khi click link xác thực hoặc login google lần đầu, hộp thoại tạo mã PIN nhảy ra 2 lớp, nhập xong lớp 1 phải nhập tiếp lớp 2 rất vô lý.
*   **Tình trạng:** **ĐÃ FIX THÀNH CÔNG TRONG CODE.**
*   **Cách giải thích:** "Ban đầu em gọi hộp thoại tạo PIN ở màn hình `VerifyEmailScreen`, nhưng vì luồng Google không đi qua màn hình này, nên em chuyển hộp thoại tạo PIN về `ChildSelectionScreen`. Vô tình điều đó làm cả 2 màn hình cùng gọi hộp thoại lên (đè nhau). Em đã xử lý triệt để bằng cách gỡ hàm tạo PIN khỏi màn hình Verify, giờ toàn bộ hệ thống quy về một mối kiểm tra tại màn hình Chọn bé."

### Lỗi 2.3: `401 Unauthorized` (Hết hạn Token)
*   **Biểu hiện:** Đang sử dụng bình thường, tự nhiên không tải được bài học, báo lỗi xác thực.
*   **Cách Fix:** Vào khu vực Phụ huynh -> Bấm **Đăng xuất (Logout)**. Sau đó đăng nhập lại bình thường để hệ thống cấp cặp Token mới. (Hoặc nếu Thầy hỏi thì nói app đã có cơ chế tự động gọi `/api/Auth/refresh-token` nhờ Interceptors, nhưng nếu Refresh Token cũng chết luôn do quá hạn 30 ngày thì app sẽ ép văng ra màn hình Login).

---

## 3. NHÓM LỖI QUẢN TRỊ VIÊN (ADMIN ERRORS)

### Lỗi 3.1: Lỗi tạo trùng tên Chủ đề / Bài học / Từ vựng (400 Bad Request)
*   **Biểu hiện gốc:** Khi Admin cố tình tạo nội dung bị trùng, Backend chặn lại và ném ra cái lỗi nguyên gốc tiếng Anh: `"A topic with this name already exists"` hoặc `"A topic with this orderindex already exists"`, làm app hiện thông báo lỗi xấu xí hoặc bị crash.
*   **Tình trạng:** **ĐÃ FIX CỰC KỲ XỊN SÒ TRONG CODE.**
*   **Cách giải thích với Thầy:** "Tụi em không để Frontend phơi bày lỗi thô (Raw Error) của Backend ra. Em đã xây dựng một bộ lưới lọc trung tâm tại `lib/utils/snackbar_utils.dart`. Bộ lọc này sẽ bắt lỗi `DioException`, phân tích xem Backend đang chửi câu tiếng Anh gì, sau đó dịch ngược lại thành thông báo Tiếng Việt siêu thân thiện (Ví dụ: *'Tên chủ đề này đã tồn tại, vui lòng chọn tên khác'*). Sau đó hiển thị màu đỏ trên cùng màn hình. Vừa đẹp, vừa an toàn."

### Lỗi 3.2: Quên điền Thứ tự hiển thị (Order Index) làm dữ liệu lộn xộn
*   **Tình trạng:** **ĐÃ FIX THÀNH CÔNG TÍNH NĂNG SMART AUTO-FILL.**
*   **Cách giải thích:** "Lúc đầu admin tạo bài học phải tự nhớ xem đang có bao nhiêu bài học rồi để điền Order Index. Rất bất tiện và dễ bị trùng. Tụi em đã code thêm logic: Cứ mỗi khi Admin ấn [Thêm mới], app sẽ tự quét list hiện tại, lấy con số lớn nhất cộng (+) thêm 1, rồi điền sẵn vào ô Input luôn. Admin chỉ việc gõ tên bài rồi lưu, nhàn hơn 100 lần ạ."

---

## 4. NHÓM LỖI BACKEND (SERVER ERRORS)

### Lỗi 4.1: Báo lỗi đỏ chót `Cannot open database "KidioDB" requested by the login` hoặc `Relation "Topics" does not exist`
*   **Biểu hiện:** Khi vừa bấm Ctrl F5 chạy Backend lên thì báo lỗi tùm lum.
*   **Nguyên nhân:** Máy đó có cài PostgreSQL nhưng chưa chạy Migration để tạo bảng. Data trống không.
*   **Cách Fix:**
    - Mở Visual Studio -> Package Manager Console.
    - Gõ: `Update-Database`. Chờ báo Done là xong.

### Lỗi 4.2: Postgres Password Authentication Failed
*   **Biểu hiện:** Lỗi sai mật khẩu Database.
*   **Cách Fix:** Vào `appsettings.json` bên dự án Backend, nhìn dòng `DefaultConnection`, sửa chỗ `Password=12345` thành đúng mật khẩu tài khoản PostgreSQL trên máy của bạn. Khởi động lại Server.