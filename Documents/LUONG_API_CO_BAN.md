# MÔ TẢ LUỒNG HOẠT ĐỘNG API CƠ BẢN NHẤT TRONG DỰ ÁN

Tài liệu này trình bày luồng hoạt động giao tiếp qua lại giữa ứng dụng Frontend (Mobile/Web) và hệ thống Backend (Server) thông qua API, theo chuẩn kiến trúc đang được áp dụng trong hệ thống KIDIO.
Tất cả các đường link bên dưới đều là đường dẫn tuyệt đối, bạn hãy **Bấm giữ phím Ctrl + Click chuột trái** vào link màu xanh để VS Code tự động mở file và nhảy tới đúng dòng code đó.

---

## 1. MÔ HÌNH TỔNG QUAN (ARCHITECTURE)

Ứng dụng tuân thủ kiến trúc phân tầng để đảm bảo tính dễ bảo trì và khả năng mở rộng. Luồng đi chuẩn của một API sẽ đi qua 5 tầng chính như sau:

**UI (Màn hình) ➔ Provider (Trạng thái) ➔ Repository (Nghiệp vụ) ➔ API Service (Gọi mạng) ➔ Backend (Máy chủ)**

Và kết quả sẽ trả về theo chiều ngược lại:

**Backend ➔ API Service ➔ Repository ➔ Provider ➔ UI (Cập nhật giao diện)**

---

## 2. GIẢI THÍCH CHI TIẾT TỪNG BƯỚC (QUÁ TRÌNH REQUEST)

Để ví dụ cụ thể, chúng ta xét chức năng **"Người dùng ấn nút lấy danh sách Chủ đề (Topics)"**:

### Bước 1: Tầng Giao diện (UI Layer)
- Màn hình (`TopicsListScreen`) được khởi tạo.
- Người dùng mở màn hình hoặc nhấn nút refresh. Code tại UI gọi hàm `loadTopics()` của tầng Provider (Ví dụ: thông qua `context.read<TopicProvider>()`). Tầng này **chỉ chịu trách nhiệm vẽ giao diện**, tuyệt đối không chứa logic gọi mạng hay xử lý dữ liệu phức tạp.
  [topics_list_screen.dart (Line 14)](file:///c:/.PRM393/.FE/lib/screens/topics_list_screen.dart#L14)

### Bước 2: Tầng Quản lý Trạng thái (Provider Layer)
- `TopicProvider` tiếp nhận yêu cầu từ UI thông qua hàm `loadTopics()`.
- Nó lập tức bật trạng thái `_isLoading = true` và gọi `notifyListeners()` để báo UI xoay vòng loading. Sau đó, nó gọi tiếp xuống tầng Repository: `await repository.fetchTopics()`.
  [topic_provider.dart (Line 61)](file:///c:/.PRM393/.FE/lib/providers/topic_provider.dart#L61)

### Bước 3: Tầng Nghiệp vụ Data (Repository Layer)
- `TopicRepository` là trạm trung chuyển. Nó gọi thẳng hàm `fetchTopics()` từ tầng kết nối mạng `_topicApi`.
- Việc chia tách Repository giúp che giấu cách thức lấy dữ liệu (API hay Local Database) khỏi Provider.
  [topic_repository.dart (Line 13)](file:///c:/.PRM393/.FE/lib/repositories/topic_repository.dart#L13)

### Bước 4: Tầng Kết nối Mạng (API Service Layer & ApiClient)
- Hàm `fetchTopics()` trong `TopicApi` khởi tạo HTTP GET request lên API Endpoint (`/Topic`). Nó kế thừa bộ khung cấu hình mạng từ thư viện `Dio` thông qua file cấu hình tổng `ApiClient`.
  [topic_api.dart (Line 9)](file:///c:/.PRM393/.FE/lib/services/topic_api.dart#L9)
- Bản thân `ApiClient` chịu trách nhiệm chặn bắt request để nhét Token Bảo Mật, cài đặt timeout và kết nối đến đúng địa chỉ Server.
  [api_client.dart (Line 14)](file:///c:/.PRM393/.FE/lib/api/api_client.dart#L14)

### Bước 5: Tầng Máy chủ (Backend Layer)
- Server backend (C# .NET) nhận HTTP GET Request từ Frontend.
- Chạy qua Controller ➔ Service ➔ Query Database (SQL Server).
- Đóng gói dữ liệu lại dưới dạng chuỗi `JSON` và trả về kèm theo mã HTTP Status (Ví dụ: `200 OK`).

---

## 3. QUÁ TRÌNH NHẬN KẾT QUẢ (RESPONSE)

Sau khi Backend phản hồi, luồng dữ liệu chạy ngược lại lên UI:

### Bước 6: Tầng API xử lý JSON thô
- `ApiClient` hứng kết quả JSON. Nếu kết quả là lỗi (VD: Mất mạng, Lỗi Server), các Interceptor nội bộ sẽ chặn lại và ném ra Exception.
  [api_client.dart (Line 126)](file:///c:/.PRM393/.FE/lib/api/api_client.dart#L126)
- Nếu thành công, `TopicApi` đẩy mảng dữ liệu JSON thô trở ngược lên trên.

### Bước 7: Tầng Repository chuyển đổi dữ liệu (Parsing/Mapping)
- Dữ liệu JSON thô được chuyển hóa (Deserialize/Parse) thành các Model chuẩn Dart (ở đây là biến thành object kiểu `PagedResult<Topic>`).
- Object có cấu trúc đàng hoàng này được trả về cho `TopicProvider`.
  [topic_repository.dart (Line 9)](file:///c:/.PRM393/.FE/lib/repositories/topic_repository.dart#L9)

### Bước 8: Tầng Provider lưu trữ trạng thái
- `TopicProvider` nhận được object. Nó lưu vào danh sách `_topics`.
- Nó tắt vòng loading bằng cách gán `_isLoading = false` rồi gọi `notifyListeners()`.
  [topic_provider.dart (Line 64)](file:///c:/.PRM393/.FE/lib/providers/topic_provider.dart#L64)

### Bước 9: Tầng UI tự động cập nhật
- Tín hiệu `notifyListeners()` đánh thức `TopicsListScreen`.
- UI tự động chạy hàm `build()`. Nó phát hiện `_isLoading` đã tắt và biến `_topics` có chứa dữ liệu. Vòng tròn loading biến mất, danh sách các thẻ bài Chủ đề (Topics) tuyệt đẹp được vẽ ra màn hình.
  [topics_list_screen.dart (Line 21)](file:///c:/.PRM393/.FE/lib/screens/topics_list_screen.dart#L21)

---
**TỔNG KẾT LẠI:** Bằng việc chia nhỏ từng bước (UI ➔ Provider ➔ Repo ➔ API), luồng hoạt động này đảm bảo code không bị dính chặt vào nhau. Nếu sau này API thay đổi cấu trúc JSON, ta chỉ cần sửa đúng 1 chỗ ở tầng Repository mà không cần đụng tới UI hay Provider. Đây là tiêu chuẩn cơ bản và quan trọng nhất khi làm việc với kiến trúc Mobile app hiện đại.
