# ĐIỀU HƯỚNG MÃ NGUỒN (CODE TRACING FLOW)

Tài liệu này tập trung 100% vào mã nguồn (Source Code). Nó giải thích luồng đi của dữ liệu từ file A sang file B, rồi gọi hàm C. 
Tất cả các đường link bên dưới đều là đường dẫn tuyệt đối, bạn hãy **Bấm giữ phím Ctrl + Click chuột trái** vào link màu xanh để VS Code tự động mở file và nhảy tới đúng dòng code đó.

---

## 1. LUỒNG KHỞI ĐỘNG VÀ ĐIỀU HƯỚNG ỨNG DỤNG (APP BOOT)

Luồng kiểm tra lúc người dùng vừa mở app lên để quyết định xem họ sẽ đi vào màn hình nào.

*   **Bước 1 (Khởi tạo lõi):** Tại hàm `main()`, ứng dụng khởi tạo toàn bộ các API, Repository và Provider.
    [main.dart (Line 42)](file:///c:/.PRM393/.FE/lib/main.dart#L42)
*   **Bước 2 (Chặn cửa tại AuthWrapper):** Ở `MaterialApp`, giao diện đầu tiên được nạp là thẻ `AuthWrapper`. Thẻ này có nhiệm vụ lắng nghe (watch) sự thay đổi trạng thái của `AuthProvider`.
    [main.dart (Line 115)](file:///c:/.PRM393/.FE/lib/main.dart#L115)
*   **Bước 3 (Phân loại người dùng):** Tùy vào biến `isAuthenticated` và `isAdmin` trong `AuthProvider`, `AuthWrapper` sẽ `return` màn hình tương ứng.
    - Nếu `!isAuthenticated` -> Return `LoginScreen()`.
    - Nếu `isAdmin` -> Return `AdminDashboardScreen()`.
    - Nếu User thường -> Return `ChildSelectionScreen()`.
    [main.dart (Line 132-155)](file:///c:/.PRM393/.FE/lib/main.dart#L132-L155)

---

## 2. LUỒNG ĐĂNG NHẬP (AUTHENTICATION TRACING)

Đây là ví dụ điển hình của mô hình `Screen -> Provider -> Repository -> API Client`.

*   **Bước 1 (Bấm nút ở UI):** Người dùng điền Email/Pass và bấm nút "ĐĂNG NHẬP". Sự kiện `onPressed` gọi đến hàm nội bộ `_handleEmailLogin`.
    [login_screen.dart (Line 160)](file:///c:/.PRM393/.FE/lib/screens/login_screen.dart#L160)
*   **Bước 2 (Gọi Provider):** Hàm `_handleEmailLogin` gọi tiếp hàm `login()` của `authProvider`.
    [login_screen.dart (Line 102)](file:///c:/.PRM393/.FE/lib/screens/login_screen.dart#L102)
*   **Bước 3 (Provider điều phối):** `AuthProvider` nhận thông tin, bật trạng thái `_isLoading = true` để UI xoay vòng, sau đó ném dữ liệu xuống `AuthRepository`.
    [auth_provider.dart (Line 45)](file:///c:/.PRM393/.FE/lib/providers/auth_provider.dart#L45)
*   **Bước 4 (Repository xử lý thô):** `AuthRepository` nhận lệnh, gọi thẳng xuống `AuthApi` để thực hiện HTTP POST.
    [auth_repository.dart (Line 28)](file:///c:/.PRM393/.FE/lib/repositories/auth_repository.dart#L28)
*   **Bước 5 (API gọi mạng):** `AuthApi` dùng `_dio.post('/Auth/login')` để đẩy request qua mạng lấy JSON về.
    [auth_api.dart (Line 15)](file:///c:/.PRM393/.FE/lib/services/auth_api.dart#L15)
*   **Bước 6 (Lưu Cache & Hoàn thành):** Sau khi `AuthApi` trả Token về, `AuthRepository` gọi hàm `_saveToken()` để lưu Token vào `FlutterSecureStorage`. Cuối cùng `AuthProvider` gọi `notifyListeners()`, kích hoạt lại **Bước 2 của Luồng Khởi Động**, đưa user vào app.
    [auth_repository.dart (Line 40)](file:///c:/.PRM393/.FE/lib/repositories/auth_repository.dart#L40)

---

## 3. LUỒNG BẢO MẬT MÃ PIN PHỤ HUYNH (PARENT PIN LOCK)

*   **Bước 1 (Bấm nút ở khu vực cấm):** Bé vô tình nhấn vào nút "PHỤ HUYNH" ở góc màn hình. Giao diện gọi hàm `_showParentVerification()`.
    [child_selection_screen.dart (Line 260)](file:///c:/.PRM393/.FE/lib/screens/child_selection_screen.dart#L260)
*   **Bước 2 (Kiểm tra trạng thái PIN):** Hàm kiểm tra xem tài khoản này đã tạo PIN bao giờ chưa (`hasParentPin()`). Nếu có rồi thì gọi Dialog yêu cầu nhập: `ParentPinDialogs.showVerifyPinDialog(context)`.
    [child_selection_screen.dart (Line 286-300)](file:///c:/.PRM393/.FE/lib/screens/child_selection_screen.dart#L286-L300)
*   **Bước 3 (Vẽ Hộp thoại nhập PIN):** Code chạy sang file UI của Dialog. Hiển thị 4 ô trống bằng thư viện `pinput`.
    [parent_pin_dialogs.dart (Line 150)](file:///c:/.PRM393/.FE/lib/widgets/parent_pin_dialogs.dart#L150)
*   **Bước 4 (So sánh mã PIN):** Khi user nhập đủ 4 số, Dialog lấy chuỗi 4 số đó so sánh với mã PIN được lưu trong `authProvider.verifyPin(pin)`. Nếu hàm này trả về `true` -> Pop cái dialog đi và `Navigator.push` sang `ParentDashboardScreen`.
    [parent_pin_dialogs.dart (Line 200)](file:///c:/.PRM393/.FE/lib/widgets/parent_pin_dialogs.dart#L200)

---

## 4. LUỒNG BẮT LỖI VÀ DỊCH TỰ ĐỘNG BẰNG SNACKBAR (ERROR HANDLING)

Quá trình bắt câu chữ tiếng Anh thô kệch của Backend và dịch thành tiếng Việt.

*   **Bước 1 (Xảy ra lỗi ở tầng API):** Khi Admin tạo trùng tên Bài học, `LessonApi` ném ra một `DioException` có chứa HTTP Status 400 và câu `Message: "A lesson with this name already exists"`.
*   **Bước 2 (Lỗi nảy lên Screen):** Lỗi này ném ngược lên `AdminLessonFormScreen` qua khối `try...catch`. Bắt được biến `e`. Code trên Screen gọi hàm `CustomSnackBar.showError(context, e)`.
    [admin_lesson_form_screen.dart (Line 110)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_lesson_form_screen.dart#L110)
*   **Bước 3 (Xử lý dịch thuật tại Utils):** Hàm `showError` truyền biến `e` vào màng lọc `_parseErrorMessage(e)`. Màng lọc này kiểm tra chuỗi string bên trong `e`. Nó thấy chữ `"already exists"` -> Nó tự động đổi biến nội dung thành `"Tên bài học đã tồn tại"`. Cuối cùng nó gọi hàm vẽ UI SnackBar màu đỏ hiện lên màn hình.
    [snackbar_utils.dart (Line 42-85)](file:///c:/.PRM393/.FE/lib/utils/snackbar_utils.dart#L42-L85)

---

## 5. LUỒNG AUTO-INCREMENT ORDER INDEX (NGHIỆP VỤ ADMIN)

Đây là luồng Backend tự động gợi ý điền số cho Admin.

*   **Bước 1 (Admin click Thêm Mới):** Đang ở danh sách Bài học (`AdminLessonListScreen`), Admin bấm nút dấu `(+)`. Nút này gọi hàm `_navigateToForm()`.
    [admin_lesson_list_screen.dart (Line 96)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_lesson_list_screen.dart#L96)
*   **Bước 2 (Tính toán số tiếp theo):** Trong hàm `_navigateToForm()`, code lấy mảng danh sách bài học hiện tại (`_lessons`). Nếu mảng rỗng thì gán số `1`. Nếu mảng có data, nó duyệt mảng tìm cái `orderIndex` lớn nhất (`reduce()`) rồi cộng (+) thêm `1`. Đặt tên biến là `nextOrderIndex`.
    [admin_lesson_list_screen.dart (Line 98)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_lesson_list_screen.dart#L98)
*   **Bước 3 (Đẩy sang Form):** Gọi `Navigator.push` và nhét biến `nextOrderIndex` ném sang class `AdminLessonFormScreen`.
    [admin_lesson_list_screen.dart (Line 105)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_lesson_list_screen.dart#L105)
*   **Bước 4 (Khởi tạo ô Text):** Tại `initState` của trang Form, code kiểm tra thấy có `nextOrderIndex` được ném qua. Nó gán ngay cái số đó vào `_orderIndexController.text`. Nên khi màn hình vừa bật lên, ô số thứ tự đã được điền sẵn.
    [admin_lesson_form_screen.dart (Line 45)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_lesson_form_screen.dart#L45)
