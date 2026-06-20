# GIẢI THÍCH CHI TIẾT KIẾN TRÚC THƯ MỤC CỦA DỰ ÁN (Dành cho người mới)

Tài liệu này giải thích chi tiết chức năng của từng thư mục và tệp tin trong dự án Frontend (thư mục `lib`), kèm theo các **ví dụ thực tế** rất gần gũi với cuộc sống để bạn dễ hình dung sự tương tác giữa các phần code với nhau.

---

## MÔ HÌNH HOẠT ĐỘNG CHUNG: "NHÀ HÀNG 5 SAO" (MVVM ARCHITECTURE)

Dự án KIDIO được tổ chức theo kiến trúc MVVM (Model-View-ViewModel) kết hợp với Repository Pattern. Để dễ hiểu nhất, hãy tưởng tượng toàn bộ App của chúng ta là một **Nhà hàng 5 Sao**:

1. **View (`screens`, `widgets`):** Là khu vực **Bàn ăn của khách**. Nơi thiết kế đẹp mắt, trưng bày Menu. Bàn ăn KHÔNG BAO GIỜ có chức năng tự chế biến đồ ăn, nó chỉ nhận lệnh từ khách (bấm nút).
2. **ViewModel (`providers`):** Là **Người Phục Vụ (Waiter)**. Đứng cạnh bàn, ghi nhận lệnh từ khách, sau đó chạy đi lấy đồ ăn. Khi có đồ ăn, phục vụ sẽ hô to để bàn ăn dọn món lên.
3. **Repository (`repositories`):** Là **Quản Lý Nhà Bếp**. Nhận order từ phục vụ. Quản lý bếp sẽ ưu tiên mở Tủ lạnh (Local Storage) xem đồ ăn có sẵn không để lấy cho nhanh. Nếu không có, quản lý sẽ viết phiếu đi chợ.
4. **API / Services (`services`, `api`):** Là **Người Đi Chợ**. Cầm phiếu của quản lý, lấy xe máy chạy đúng tới địa chỉ cái Chợ (Backend Server) để chở đồ ăn về.
5. **Models (`models`):** Là **Khuôn đúc đồ ăn**. Đồ ăn mang từ chợ về thường thô kệch và lộn xộn (JSON). Phải đổ vào các khuôn này thì đồ ăn (Dữ liệu) mới ra hình dáng rõ ràng (như hình con thú, ngôi sao) để đầu bếp dễ chế biến.

---

## GIẢI THÍCH CHI TIẾT TỪNG THƯ MỤC TRONG `lib/`

### 1. `screens/` (Màn hình chính)
*   **Chức năng (Code):** Chứa các màn hình đầy đủ (UI) của ứng dụng mà người dùng trực tiếp nhìn thấy và tương tác. Sử dụng các Widget để vẽ và lấy dữ liệu thông qua Provider.
*   **Ví dụ thực tế:** Là các không gian, mặt bằng của cửa hàng. Ví dụ: `login_screen.dart` là *Quầy tiếp tân*, `topics_list_screen.dart` là *Kệ trưng bày sách*, `vocabulary_quiz_screen.dart` là *Bàn chơi Flashcard của bé*.

### 2. `widgets/` (Các thành phần UI dùng lại)
*   **Chức năng (Code):** Chứa các mảnh giao diện nhỏ (Component) được cắt ra để dùng đi dùng lại ở nhiều màn hình khác nhau, tránh việc copy-paste code.
*   **Ví dụ thực tế:** Là những *Viên gạch* hoặc *Bóng đèn*. Một bóng đèn (`lesson_card.dart` - Ô hiển thị bài học) có thể được gắn ở phòng khách, phòng ngủ hay hành lang mà không cần phải chế tạo lại từ đầu. Khi sửa thiết kế bóng đèn, toàn bộ nhà đều đẹp lên.

### 3. `providers/` (Trạng thái và Logic điều khiển)
*   **Chức năng (Code):** Xử lý State Management (Quản lý trạng thái). Nó chứa các biến lưu trữ dữ liệu (VD: danh sách bài học hiện tại). Khi dữ liệu thay đổi, nó gọi hàm `notifyListeners()` để báo cho `screens` tự động vẽ lại UI.
*   **Ví dụ thực tế:** Giống như một **Phát Thanh Viên ở sân vận động** và bảng điểm điện tử. Khi có bàn thắng (dữ liệu đổi), phát thanh viên hô to lên loa (notifyListeners), lập tức màn hình bảng điểm lớn trên sân tự động cập nhật số mới mà khán giả (Screen) không cần phải làm gì cả.

### 4. `repositories/` (Kho phân phối dữ liệu)
*   **Chức năng (Code):** Lớp trung gian nằm giữa `Provider` và `Service`. Nó gom dữ liệu từ nhiều nguồn: từ API mạng hoặc từ Database cục bộ, xử lý logic thô, rồi mới trả kết quả sạch sẽ lên cho `Provider`.
*   **Ví dụ thực tế:** Là **Bếp trưởng thông thái**. Khi phục vụ (Provider) báo cần Món Súp, Bếp trưởng sẽ ưu tiên kiểm tra xem Súp có sẵn trong Tủ lạnh (`local/cache`) hay không để lấy luôn cho nhanh. Nếu hết, ổng mới sai người đi mua nguyên liệu (`services`). Nhờ vậy, khách hàng luôn được phục vụ với tốc độ nhanh nhất.

### 5. `services/` (Tương tác với máy chủ)
*   **Chức năng (Code):** Chỉ làm đúng 1 việc: Gọi API (GET, POST, PUT, DELETE) xuống Backend. Gửi dữ liệu thô đi và nhận chuỗi JSON về.
*   **Ví dụ thực tế:** Là **Người giao vận (Shipper)**. Họ chỉ quan tâm đến việc: Lấy đúng tờ giấy (Endpoint API) và chở thùng hàng (JSON) từ kho tổng (Backend) về nhà hàng. Họ không quan tâm trong thùng có gì.

### 6. `api/` (Cấu hình lõi của mạng)
*   **Chức năng (Code):** File `api_client.dart` cài đặt thư viện `Dio`, định nghĩa BaseURL chung, cấu hình Timeout. Đặc biệt nó chứa `Interceptor` để tự động chèn `JWT Token` vào mọi Request.
*   **Ví dụ thực tế:** Tưởng tượng `Interceptor` là **Hành động tự động giơ thẻ VIP**. JWT Token giống như cái vòng tay VIP bạn nhận được lúc Đăng nhập. Khi bạn đi vòng quanh các khu vực trong quán (Gọi các API khác nhau), thay vì mỗi lần qua cửa đều phải móc vé ra trình (viết code thủ công), `Interceptor` sẽ tự động giơ tay cho bảo vệ xem vé giúp bạn.

### 7. `models/` (Định dạng dữ liệu)
*   **Chức năng (Code):** Chứa định nghĩa các Object (Class). Có các hàm `.fromJson()` và `.toJson()` để chuyển đổi qua lại giữa chuỗi văn bản JSON từ Backend thành Object trong Dart.
*   **Ví dụ thực tế:** Là **Cái khuôn đúc kẹo**. Thùng hàng (JSON) chứa một cục bột dẻo lộn xộn. Lập trình viên không thể làm việc với cục bột đó được. Phải ép cục bột qua cái khuôn hình gấu (`ChildModel`), khuôn hình sao (`TopicModel`) thì mới lấy ra ăn (Hiển thị lên màn hình) được.

### 8. `utils/` (Công cụ hỗ trợ)
*   **Chức năng (Code):** Chứa các hàm tiện ích tái sử dụng toàn cục: Định dạng ngày tháng, kiểm tra chuỗi, dịch lỗi API.
*   **Ví dụ thực tế:** Là cái **Hộp dụng cụ (Tua vít, cờ lê)**. Đi đâu cần vặn đinh ốc (xử lý chữ, bắt lỗi `snackbar_utils.dart`) thì cứ lôi hộp dụng cụ ra xài, không cần chế tạo lại cái tua vít. Đỉnh cao nhất là cái Tua Vít dịch thuật: Backend chửi lỗi tiếng Anh, Tua Vít này dịch thành thông báo Tiếng Việt đẹp mắt!

### 9. `local/` (Lưu trữ cục bộ)
*   **Chức năng (Code):** Cấu hình thư viện Hive / FlutterSecureStorage để lưu dữ liệu trực tiếp vào bộ nhớ máy tính/điện thoại mà không cần mạng.
*   **Ví dụ thực tế:** Là cái **Két sắt và Tủ lạnh**. `FlutterSecureStorage` là Két sắt để cất giấu Token và Mã PIN (rất bảo mật). Còn `Hive` là tủ lạnh để cất dữ liệu bài học tạm thời để nếu lỡ rớt mạng (Offline) thì mở tủ lạnh ra vẫn có bài học cho bé học.
