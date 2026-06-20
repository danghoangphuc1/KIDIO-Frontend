# HƯỚNG DẪN CÀI ĐẶT VÀ CHẠY DỰ ÁN KIDIO TỪ A ĐẾN Z

Tài liệu này được viết theo cách "Cầm tay chỉ việc", dù bạn là người chưa từng code bao giờ, chỉ cần làm đúng theo thứ tự từng bước một dưới đây là chắc chắn 100% ứng dụng sẽ chạy lên thành công.

---

## PHẦN 1: CẦN CÀI ĐẶT NHỮNG PHẦN MỀM NÀO? (PREREQUISITES)
Trước khi bắt đầu, hãy đảm bảo máy tính của bạn đã cài sẵn 4 công cụ sau (lên Google gõ tên và tải bản mới nhất về cài Next -> Next là xong):
1. **PostgreSQL:** Phần mềm quản lý Cơ sở dữ liệu. *(RẤT QUAN TRỌNG: Lúc cài đặt, nó sẽ hỏi bạn đặt mật khẩu cho tài khoản `postgres`, hãy đặt là `12345` để khớp với code Backend nhé).*
2. **.NET 8.0 SDK:** Phần mềm để chạy được code Backend (C#).
3. **Flutter SDK:** Phần mềm để chạy được code Frontend (App điện thoại).
4. **Visual Studio 2022** (Để mở Backend) và **VS Code / Android Studio** (Để mở Frontend và bật máy ảo điện thoại).

---

## PHẦN 2: KHỞI ĐỘNG MÁY CHỦ (BACKEND)

**Bước 1: Mở source code Backend**
*   Vào thư mục chứa source Backend của nhóm (Ví dụ: `.BE/BE`).
*   Bấm đúp chuột vào file có đuôi `.sln` (KIDIO.sln) để mở dự án bằng phần mềm **Visual Studio 2022**.

**Bước 2: Kiểm tra kết nối Cơ sở dữ liệu**
*   Ở cột bên phải của Visual Studio (cột Solution Explorer), tìm thư mục **KIDIO.API** -> Mở file `appsettings.json`.
*   Tìm dòng: `"DefaultConnection": "Host=localhost;Database=KidioDB;Username=postgres;Password=12345"`
*   *(Nếu lúc cài PostgreSQL ở Phần 1 bạn lỡ đặt mật khẩu khác, hãy sửa lại số 12345 thành mật khẩu của bạn).*

**Bước 3: Khởi tạo Database tự động (Migration)**
*   Ở thanh menu trên cùng, chọn **Tools** -> **NuGet Package Manager** -> **Package Manager Console**.
*   Một cái bảng đen hiện ra ở dưới đáy màn hình, bạn hãy gõ dòng lệnh này vào và nhấn Enter:
    `Update-Database`
*   *(Chờ 1 lúc cho chữ chạy chạy báo xanh Done là hệ thống đã tự động tạo xong toàn bộ các bảng trong Database PostgreSQL).*

**Bước 4: Chạy Server**
*   Nhấn tổ hợp phím **Ctrl + F5** (Hoặc bấm nút mũi tên Play màu xanh lá ở phía trên).
*   Đợi vài giây, trình duyệt Web sẽ bật lên hiển thị màn hình Swagger (Danh sách các API). Tới đây là Server đã chạy thành công! **Tuyệt đối không được tắt cái cửa sổ đen (Console) của Server đi nhé.**

---

## PHẦN 3: KẾT NỐI VÀ CHẠY ỨNG DỤNG ĐIỆN THOẠI (FRONTEND)
Vì bạn đang chạy App trên điện thoại (hoặc máy ảo Android), cái điện thoại đó không thể hiểu chữ `localhost` là máy tính của bạn được. Nên bạn phải bắt cái điện thoại kết nối vào đúng **Địa chỉ IP WiFi** của máy tính.

**Bước 1: Lấy địa chỉ IP WiFi của bạn**
*   Nhấn tổ hợp phím `Windows + R` -> gõ chữ `cmd` rồi nhấn Enter để mở bảng đen.
*   Gõ lệnh `ipconfig` rồi nhấn Enter.
*   Tìm dòng có chữ **IPv4 Address**. Lấy dãy số đó. (Ví dụ: `192.168.1.15`).

**Bước 2: Cài IP đó vào trong App**
*   Dùng VS Code mở thư mục Frontend của nhóm (Ví dụ: `.FE`).
*   Mở file theo đường dẫn: `lib/api/api_client.dart`.
*   Tìm đến dòng số 17: `static const String _baseUrl = 'https://192.168.88.147:7014/api/';`
*   Hãy XÓA dải số cũ `192.168.88.147` và SỬA thành **địa chỉ IP WiFi IPv4** mà bạn vừa lấy được ở Bước 1. *(Lưu ý: Giữ nguyên cái cổng `:7014/api/` ở đuôi).*
*   Lưu file lại (Ctrl + S).

**Bước 3: Cài đặt thư viện cho App**
*   Cũng trong VS Code, mở Terminal lên (Bấm thanh Menu trên cùng: **Terminal** -> **New Terminal**).
*   Gõ lệnh này vào và nhấn Enter:
    `flutter pub get`
*   Chờ nó tải thư viện về xong (khoảng 30 giây).

**Bước 4: Bật điện thoại và Chạy App**
*   **Cách 1:** Cắm dây cáp nối điện thoại thật của bạn vào máy tính. (Nhớ bật chế độ Gỡ lỗi USB/USB Debugging trên điện thoại).
*   **Cách 2:** Bật máy ảo điện thoại (Emulator) bằng Android Studio.
*   Nhìn xuống góc dưới cùng bên phải của VS Code, kiểm tra xem nó đã nhận tên điện thoại của bạn chưa.
*   Cuối cùng, gõ dòng lệnh này vào Terminal rồi nhấn Enter:
    `flutter run`

**🔥 THÀNH CÔNG!**
Lần đầu tiên chạy có thể tốn khoảng 3-5 phút để máy tính Build file cài đặt ném vào điện thoại. Hãy kiên nhẫn. Sau khi chữ chạy xong, ứng dụng KIDIO sẽ tự động bật lên trên điện thoại. Bạn có thể bấm Đăng ký hoặc Login Google để test thoải mái nhé!

---
*(Ghi chú: Nếu hôm sau bạn mang máy tính lên trường kết nối WiFi của trường, IP của bạn sẽ bị đổi. Bạn chỉ cần làm lại Phần 3 - Bước 1 và Bước 2 để cập nhật lại IP mới vào code là app lại chạy ngon lành).*