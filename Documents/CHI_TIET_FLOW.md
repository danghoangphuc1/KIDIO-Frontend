# ĐIỀU HƯỚNG MÃ NGUỒN (CODE TRACING FLOW)

Tài liệu này tập trung 100% vào mã nguồn (Source Code). Nó giải thích chi tiết luồng đi của dữ liệu từ file nào sang file nào, thực thi qua các tầng kiến trúc ra sao.
Tất cả các đường link bên dưới đều là đường dẫn tuyệt đối, bạn hãy **Bấm giữ phím Ctrl + Click chuột trái** vào link màu xanh để VS Code tự động mở file và nhảy tới đúng dòng code đó.

---

## 1. LUỒNG KHỞI ĐỘNG VÀ ĐIỀU HƯỚNG ỨNG DỤNG (APP BOOT)

Luồng kiểm tra lúc người dùng khởi chạy ứng dụng để quyết định màn hình đích.

*   **Bước 1 (Khởi tạo lõi):** Tại hàm `main()`, ứng dụng tiến hành khởi tạo toàn bộ các API, Repository và Provider.
    [main.dart (Line 42)](file:///c:/.PRM393/.FE/lib/main.dart#L42)
*   **Bước 2 (Định tuyến tại AuthWrapper):** Ở `MaterialApp`, widget đầu tiên được nạp là `AuthWrapper`. Widget này lắng nghe sự thay đổi trạng thái xác thực từ `AuthProvider`.
    [main.dart (Line 115)](file:///c:/.PRM393/.FE/lib/main.dart#L115)
*   **Bước 3 (Phân loại người dùng):** Tùy vào biến `isAuthenticated` và `isAdmin` trong `AuthProvider`, `AuthWrapper` sẽ điều hướng đến màn hình tương ứng.
    - Nếu `!isAuthenticated` -> Trả về `LoginScreen()`.
    - Nếu `isAdmin` -> Trả về `AdminDashboardScreen()`.
    - Nếu là người dùng thường -> Trả về `ChildSelectionScreen()`.
    [main.dart (Line 132-155)](file:///c:/.PRM393/.FE/lib/main.dart#L132-L155)

---

## 2. LUỒNG ĐĂNG NHẬP (AUTHENTICATION TRACING)

Quá trình luân chuyển dữ liệu theo mô hình chuẩn: `Screen -> Provider -> Repository -> API Client`.

*   **Bước 1 (Giao diện UI):** Người dùng nhập Email/Password và nhấn "ĐĂNG NHẬP". Sự kiện `onPressed` gọi đến hàm nội bộ `_handleEmailLogin`.
    [login_screen.dart (Line 160)](file:///c:/.PRM393/.FE/lib/screens/login_screen.dart#L160)
*   **Bước 2 (Tầng Provider):** Hàm `_handleEmailLogin` gọi tiếp hàm `login()` của `AuthProvider`.
    [login_screen.dart (Line 102)](file:///c:/.PRM393/.FE/lib/screens/login_screen.dart#L102)
*   **Bước 3 (Provider điều phối):** `AuthProvider` nhận thông tin, thay đổi trạng thái `_isLoading = true` để hiển thị loading, sau đó truyền dữ liệu xuống `AuthRepository`.
    [auth_provider.dart (Line 45)](file:///c:/.PRM393/.FE/lib/providers/auth_provider.dart#L45)
*   **Bước 4 (Tầng Repository):** `AuthRepository` nhận yêu cầu, gọi tiếp xuống `AuthApi` để thực hiện giao thức HTTP POST.
    [auth_repository.dart (Line 28)](file:///c:/.PRM393/.FE/lib/repositories/auth_repository.dart#L28)
*   **Bước 5 (Tầng API):** `AuthApi` dùng `_dio.post('/Auth/login')` để gửi HTTP Request và nhận về JSON response.
    [auth_api.dart (Line 15)](file:///c:/.PRM393/.FE/lib/services/auth_api.dart#L15)
*   **Bước 6 (Lưu trữ & Hoàn thành):** Sau khi `AuthApi` trả về JWT Token, `AuthRepository` gọi hàm `_saveToken()` để lưu Token vào `FlutterSecureStorage`. Cuối cùng `AuthProvider` gọi `notifyListeners()`, kích hoạt lại quá trình kiểm tra tại `AuthWrapper` (Bước 2 của Luồng Khởi Động).
    [auth_repository.dart (Line 40)](file:///c:/.PRM393/.FE/lib/repositories/auth_repository.dart#L40)

---

## 3. LUỒNG BẢO MẬT MÃ PIN PHỤ HUYNH (PARENT PIN LOCK)

Luồng kiểm chứng bảo mật khi truy cập vào khu vực cấm của phụ huynh.

*   **Bước 1 (Giao diện ChildSelection):** Khi nhấn vào nút "PHỤ HUYNH" ở góc màn hình. Ứng dụng gọi hàm `_showParentVerification()`.
    [child_selection_screen.dart (Line 260)](file:///c:/.PRM393/.FE/lib/screens/child_selection_screen.dart#L260)
*   **Bước 2 (Kiểm tra dữ liệu PIN):** Hàm kiểm tra xem tài khoản này đã có mã PIN hay chưa (`hasParentPin()`). Nếu có, hệ thống gọi Dialog yêu cầu nhập: `ParentPinDialogs.showVerifyPinDialog(context)`.
    [child_selection_screen.dart (Line 286-300)](file:///c:/.PRM393/.FE/lib/screens/child_selection_screen.dart#L286-L300)
*   **Bước 3 (Vẽ Hộp thoại nhập PIN):** Khởi chạy UI của Dialog hiển thị 4 ô trống thông qua thư viện `pinput`.
    [parent_pin_dialogs.dart (Line 150)](file:///c:/.PRM393/.FE/lib/widgets/parent_pin_dialogs.dart#L150)
*   **Bước 4 (So sánh & Cấp quyền):** Khi nhập đủ 4 số, Dialog truyền chuỗi này vào hàm `authProvider.verifyPin(pin)`. Nếu trả về `true`, hệ thống tắt Dialog và dùng `Navigator.push` chuyển hướng sang `ParentDashboardScreen`.
    [parent_pin_dialogs.dart (Line 200)](file:///c:/.PRM393/.FE/lib/widgets/parent_pin_dialogs.dart#L200)

---

## 4. LUỒNG BẮT LỖI VÀ DỊCH TỰ ĐỘNG BẰNG SNACKBAR (ERROR HANDLING)

Quá trình đánh chặn Exception từ Backend và biên dịch lại thành thông báo tiếng Việt trên UI.

*   **Bước 1 (Tầng API ném lỗi):** Khi thực hiện thao tác sai (ví dụ tạo trùng tên Bài học), `LessonApi` ném ra một `DioException` mang HTTP Status 400 kèm `Message: "A lesson with this name already exists"`.
*   **Bước 2 (Tầng Screen nhận lỗi):** Exception này được đẩy ngược lên `AdminLessonFormScreen` thông qua khối `try...catch`. Code xử lý lỗi gọi hàm `CustomSnackBar.showError(context, e)`.
    [admin_lesson_form_screen.dart (Line 110)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_lesson_form_screen.dart#L110)
*   **Bước 3 (Xử lý chuỗi tại Utils):** Hàm `showError` truyền biến `e` vào hàm phân tích `_parseErrorMessage(e)`. Hàm này dùng RegEx và chuỗi khớp lệnh để tìm từ khóa như `"already exists"`, sau đó trả về chuỗi thay thế tiếng Việt: `"Tên bài học đã tồn tại"`. Cuối cùng gọi UI vẽ SnackBar màu đỏ lên màn hình.
    [snackbar_utils.dart (Line 42-85)](file:///c:/.PRM393/.FE/lib/utils/snackbar_utils.dart#L42-L85)

---

## 5. LUỒNG AUTO-INCREMENT ORDER INDEX (NGHIỆP VỤ ADMIN)

Luồng tự động hóa tính toán chỉ số Order Index trên giao diện quản trị viên.

*   **Bước 1 (Tương tác UI):** Tại `AdminLessonListScreen`, khi nhấn nút `(+)`, giao diện gọi hàm `_navigateToForm()`.
    [admin_lesson_list_screen.dart (Line 96)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_lesson_list_screen.dart#L96)
*   **Bước 2 (Logic tính toán):** Trong `_navigateToForm()`, hàm trích xuất mảng dữ liệu `_lessons`. Nếu mảng rỗng gán `nextOrderIndex = 1`. Nếu mảng có phần tử, thực hiện `reduce()` để tìm `orderIndex` lớn nhất rồi cộng thêm `1`.
    [admin_lesson_list_screen.dart (Line 98)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_lesson_list_screen.dart#L98)
*   **Bước 3 (Truyền tham số):** Sử dụng `Navigator.push` để mở `AdminLessonFormScreen`, đồng thời truyền biến `nextOrderIndex` thông qua constructor.
    [admin_lesson_list_screen.dart (Line 105)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_lesson_list_screen.dart#L105)
*   **Bước 4 (Cập nhật Form):** Tại hàm `initState` của form, giá trị `nextOrderIndex` được khởi tạo thẳng vào `_orderIndexController.text`, giúp ô số thứ tự được điền sẵn ngay khi render.
    [admin_lesson_form_screen.dart (Line 45)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_lesson_form_screen.dart#L45)

---

## 6. LUỒNG HỌC TẬP DÀNH CHO TRẺ (KIDS LEARNING FLOW)

Luồng tải nội dung học tập, quản lý bài học và hiển thị bộ Flashcard cho trẻ em.

1. **Hiển thị danh sách Chủ đề:** `TopicsListScreen` yêu cầu dữ liệu từ `TopicProvider`.
    [topics_list_screen.dart (Line 14)](file:///c:/.PRM393/.FE/lib/screens/topics_list_screen.dart#L14)
2. **Chi tiết Chủ đề:** `TopicDetailScreen` render danh sách các bài học (Lessons) thuộc chủ đề vừa chọn.
    [topic_detail_screen.dart (Line 11)](file:///c:/.PRM393/.FE/lib/screens/topic_detail_screen.dart#L11)
3. **Chi tiết Bài học:** `LessonDetailScreen` nạp thông tin cụ thể của một bài học dạng truyện hoặc từ vựng.
    [lesson_detail_screen.dart (Line 25)](file:///c:/.PRM393/.FE/lib/screens/lesson_detail_screen.dart#L25)
4. **Học qua thẻ bài (Flashcard):** `VocabularyQuizScreen` chịu trách nhiệm render chữ và hình ảnh, đồng thời kích hoạt Audio API đọc tiếng Anh khi quẹt thẻ.
    [vocabulary_quiz_screen.dart (Line 16)](file:///c:/.PRM393/.FE/lib/screens/vocabulary_quiz_screen.dart#L16)
5. **Phân tích dữ liệu JSON:** File `content_parser.dart` bóc tách chuỗi JSON Content trả về từ API và chuyển đổi thành danh sách object thực tế để render.
    [content_parser.dart (Line 3)](file:///c:/.PRM393/.FE/lib/utils/content_parser.dart#L3)
6. **Truy xuất dữ liệu (Data Layer):** Các tác vụ gọi mạng đều tuân thủ quy trình `Provider -> Repository -> API`:
   - Chủ đề: [topic_provider.dart (Line 7)](file:///c:/.PRM393/.FE/lib/providers/topic_provider.dart#L7) -> [topic_repository.dart (Line 4)](file:///c:/.PRM393/.FE/lib/repositories/topic_repository.dart#L4) -> [topic_api.dart (Line 4)](file:///c:/.PRM393/.FE/lib/services/topic_api.dart#L4)
   - Bài học: [lesson_repository.dart (Line 4)](file:///c:/.PRM393/.FE/lib/repositories/lesson_repository.dart#L4) -> [lesson_api.dart (Line 4)](file:///c:/.PRM393/.FE/lib/services/lesson_api.dart#L4)
   - Từ vựng: [vocabulary_repository.dart (Line 4)](file:///c:/.PRM393/.FE/lib/repositories/vocabulary_repository.dart#L4) -> [vocabulary_api.dart (Line 4)](file:///c:/.PRM393/.FE/lib/services/vocabulary_api.dart#L4)

---

## 7. LUỒNG ĐA PHƯƠNG TIỆN & TEXT-TO-SPEECH (MEDIA & TTS FLOW)

Luồng thực thi phát âm thanh và chuyển đổi văn bản thành giọng nói chuẩn.

1. **Điều khiển âm thanh:** `AudioPlayerService` quản lý vòng đời của âm thanh (Play, Pause, Stop) bằng cách bọc thư viện `audioplayers`.
    [audio_player_service.dart (Line 4)](file:///c:/.PRM393/.FE/lib/services/audio_player_service.dart#L4)
2. **Text-to-Speech (TTS):** Gửi chuỗi ký tự Text xuống Backend thông qua `TtsRepository` và `TtsApi`. Backend sẽ synthesize text thành một file audio stream (hoặc `.mp3`) và trả về URL để service phát.
    [tts_repository.dart (Line 4)](file:///c:/.PRM393/.FE/lib/repositories/tts_repository.dart#L4) -> [tts_api.dart (Line 4)](file:///c:/.PRM393/.FE/lib/services/tts_api.dart#L4)

---

## 8. LUỒNG CHẤM ĐIỂM PHÁT ÂM (PRONUNCIATION SCORING FLOW)

Luồng thu âm của người dùng, phân tích AI và trả về kết quả độ chính xác.

1. **Quản lý thu âm:** `PronunciationProvider` kích hoạt plugin microphone thu giọng nói. Sau khi ngắt, file audio `.wav` (hoặc `.m4a`) được sinh ra và nạp vào bộ nhớ.
    [pronunciation_provider.dart (Line 6)](file:///c:/.PRM393/.FE/lib/providers/pronunciation_provider.dart#L6)
2. **Đóng gói Payload:** `PronunciationRepository` tiếp nhận file âm thanh và nén dữ liệu dưới dạng `FormData` (Multipart request) để chuẩn bị truyền đi.
    [pronunciation_repository.dart (Line 5)](file:///c:/.PRM393/.FE/lib/repositories/pronunciation_repository.dart#L5)
3. **Thực thi API:** `PronunciationApi` đảm nhận việc gửi `FormData` lên Backend (được tích hợp với nền tảng AI như Azure Speech Services).
    [pronunciation_api.dart (Line 5)](file:///c:/.PRM393/.FE/lib/services/pronunciation_api.dart#L5)
4. **Xử lý kết quả:** Sau khi Backend phân tích và trả về `PronunciationScore` (thang điểm 1-100), `PronunciationProvider` cập nhật UI để hiển thị điểm số và thông báo.

---

## 9. LUỒNG NHẬT KÝ & THÀNH TÍCH (PROGRESS & ACHIEVEMENTS)

Luồng đồng bộ tiến độ học tập và mở khóa danh hiệu thành tích.

1. **Giao diện Thành tích:** `AchievementsScreen` phụ trách việc hiển thị các huy hiệu/cúp đã mở khóa.
    [achievements_screen.dart (Line 9)](file:///c:/.PRM393/.FE/lib/screens/achievements_screen.dart#L9)
2. **Cập nhật Tiến độ:** `ProgressProvider` gọi hàm update progress ngay khi một bài học hoàn tất diễn ra.
    [progress_provider.dart (Line 6)](file:///c:/.PRM393/.FE/lib/providers/progress_provider.dart#L6)
3. **Đồng bộ hóa Tiến độ:** Lệnh update đi qua `ProgressRepository` và gọi HTTP PUT/POST bằng `ProgressApi` để lưu trạng thái lên database.
    [progress_repository.dart (Line 4)](file:///c:/.PRM393/.FE/lib/repositories/progress_repository.dart#L4) -> [progress_api.dart (Line 4)](file:///c:/.PRM393/.FE/lib/services/progress_api.dart#L4)
4. **Đồng bộ hóa Thành tích:** Tương tự, `AchievementRepository` và `AchievementApi` được dùng để fetch danh sách các thành tích mà người dùng đã đạt được.
    [achievement_repository.dart (Line 4)](file:///c:/.PRM393/.FE/lib/repositories/achievement_repository.dart#L4) -> [achievement_api.dart (Line 4)](file:///c:/.PRM393/.FE/lib/services/achievement_api.dart#L4)

---

## 10. LUỒNG QUẢN TRỊ VIÊN TOÀN QUYỀN (ADMIN CRUD FLOW)

Luồng thực thi các hành động Create/Read/Update/Delete (CRUD) trên Dashboard của Admin.

1. **Dashboard Tổng:** `AdminDashboardScreen` hiển thị biểu đồ và thông số tổng. Tác vụ fetch dữ liệu đi từ `DashboardProvider` -> `DashboardRepository` -> `DashboardApi`.
    [admin_dashboard_screen.dart (Line 8)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_dashboard_screen.dart#L8) | [dashboard_provider.dart (Line 5)](file:///c:/.PRM393/.FE/lib/providers/dashboard_provider.dart#L5)
2. **Quản lý Chủ đề:** UI quản lý nằm ở `AdminTopicListScreen` (Hiển thị mảng) và `AdminTopicFormScreen` (Form điền).
    [admin_topic_list_screen.dart (Line 9)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_topic_list_screen.dart#L9) | [admin_topic_form_screen.dart (Line 7)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_topic_form_screen.dart#L7)
3. **Quản lý Bài học:** UI quản lý nằm ở `AdminLessonListScreen` và `AdminLessonFormScreen`.
    [admin_lesson_list_screen.dart (Line 9)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_lesson_list_screen.dart#L9) | [admin_lesson_form_screen.dart (Line 24)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_lesson_form_screen.dart#L24)
4. **Quản lý Từ vựng:** UI quản lý nằm ở `AdminVocabularyListScreen` và `AdminVocabularyFormScreen`.
    [admin_vocabulary_list_screen.dart (Line 8)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_vocabulary_list_screen.dart#L8) | [admin_vocabulary_form_screen.dart (Line 8)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_vocabulary_form_screen.dart#L8)

---

## 11. TIỆN ÍCH DÙNG CHUNG (UTILITIES)

Các class tiện ích dùng để hỗ trợ hệ thống (Logging, Formatting, UI Helpers).

1. **Định dạng SnackBar:** `CustomSnackBar` nằm trong `snackbar_utils.dart` chứa các hàm tĩnh (static) để render giao diện báo lỗi hoặc thành công.
    [snackbar_utils.dart (Line 5)](file:///c:/.PRM393/.FE/lib/utils/snackbar_utils.dart#L5)
   - Hàm `showError` và `showSuccess` bọc sẵn UI chuẩn của ứng dụng.
   - Hàm `_parseErrorMessage` xử lý Regex chuỗi thô từ Backend và transform thành chuỗi UI thân thiện hơn (User-Friendly).
