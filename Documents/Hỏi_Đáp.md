# Tài liệu Hỏi & Đáp về Chức năng và Luồng Code - Dự án KIDIO

## 1. Chức năng chính hiện tại của ứng dụng là gì?

Hiện tại, ứng dụng **KIDIO** đang tập trung vào 3 chức năng cốt lõi:
1.  **Học tập tương tác:** Cho phép trẻ em học tiếng Anh qua các Chủ đề (Topics), Bài học (Lessons) và Từ vựng (Vocabulary) sinh động.
2.  **Quản lý trẻ em (Child Management):** Phụ huynh có thể tạo nhiều hồ sơ cho các con để theo dõi tiến trình học tập riêng biệt.
3.  **Kiểm soát của phụ huynh (Parental Control):** Đây là chức năng trọng tâm hiện tại. Sử dụng **Mã PIN Phụ huynh** để khóa các khu vực nhạy cảm (như Dashboard quản lý, cài đặt thanh toán) nhằm đảm bảo trẻ em không tự ý thay đổi dữ liệu hoặc truy cập nội dung không phù hợp.

---

## 2. Luồng hoạt động chi tiết trong Code (Ví dụ: Luồng Xác thực Mã PIN)

Khi thầy hỏi về luồng code, bạn có thể trình bày theo mô hình **"Từ Giao diện đến Server"** như sau:

### Bước 1: Tầng Giao diện (UI Layer)
*   **File:** `lib/widgets/parent_pin_dialogs.dart`
*   **Hoạt động:** Khi người dùng nhấn vào nút "Bảng điều khiển phụ huynh", hàm `showVerifyPinDialog(context)` được gọi. Người dùng nhập 4 số PIN vào các ô `TextField`.
*   **Code:** Khi nhập đủ 4 số, nút "Xác nhận" sẽ gọi hàm `_verifyPin()`.

### Bước 2: Tầng Quản lý trạng thái (State Management - Provider)
*   **File:** `lib/providers/auth_provider.dart`
*   **Hoạt động:** Giao diện gọi hàm `authProvider.verifyParentPin(inputPin)`.
*   **Code:** 
    ```dart
    Future<bool> verifyParentPin(String pin) async {
      return await _repository.verifyParentPin(_currentUser!.id, pin);
    }
    ```
    Provider không trực tiếp xử lý dữ liệu mà đóng vai trò trung gian điều phối và thông báo cho UI cập nhật (loading, báo lỗi).

### Bước 3: Tầng Dữ liệu (Repository)
*   **File:** `lib/repositories/auth_repository.dart`
*   **Hoạt động:** Repository nhận yêu cầu và kiểm tra trong bộ nhớ bảo mật (`FlutterSecureStorage`).
*   **Code:**
    ```dart
    Future<bool> verifyParentPin(String userId, String inputPin) async {
      final savedPin = await _storage.read(key: 'parent_pin_$userId');
      return savedPin == inputPin;
    }
    ```
    *(Ghi chú: Mã PIN hiện được lưu local để tốc độ xử lý nhanh, nhưng các thao tác nhạy cảm khác như Đổi mật khẩu sẽ gọi lên API).*

### Bước 4: Tầng Kết nối API (Service/API Layer)
*   **File:** `lib/services/auth_api.dart` & `lib/api/api_client.dart`
*   **Hoạt động:** Nếu cần xác thực mật khẩu để reset PIN, Service sẽ dùng `Dio` (trong `ApiClient`) để gửi yêu cầu `POST` lên Server.
*   **Code:** `_dio.post('users/verify-password', data: {...})`.

### Bước 5: Tầng Máy chủ (Backend - .NET)
*   **File:** `KIDIO.API/Controllers/UsersController.cs`
*   **Hoạt động:** Server nhận request, dùng `BCrypt` để kiểm tra mật khẩu trong Database SQL Server.
*   **Code:**
    ```csharp
    [HttpPost("verify-password")]
    public async Task<ActionResult<ApiResponse<bool>>> VerifyPassword(...) {
        var result = await _userService.VerifyPasswordAsync(request);
        return Ok(ApiResponse<bool>.Ok(result));
    }
    ```

---

## Tóm tắt mô hình kiến trúc (Mnemonic cho thầy):
*   **UI (Widgets/Screens):** Nơi nhận input của người dùng.
*   **Provider:** Nơi giữ "linh hồn" (dữ liệu) của màn hình.
*   **Repository:** Nơi quyết định lấy dữ liệu từ "túi" (Local) hay từ "chợ" (Server).
*   **Service/API:** Nơi thực hiện việc đi "mua" dữ liệu (HTTP Request).
*   **Backend:** Nơi xử lý logic nghiệp vụ và lưu trữ vĩnh viễn (Database).
