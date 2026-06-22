# ĐIỀU HƯỚNG MÃ NGUỒN (CODE TRACING FLOW)

Tài liệu này tập trung 100% vào mã nguồn (Source Code). Nó giải thích chi tiết luồng đi của dữ liệu từ file này sang file khác, cách các hàm được gọi và logic xử lý của hệ thống Kidio.
Tất cả các đường link bên dưới đều là đường dẫn tuyệt đối, bạn hãy **Bấm giữ phím Ctrl + Click chuột trái** vào link màu xanh để VS Code tự động mở file và nhảy tới đúng dòng code tương ứng.

---

## 1. LUỒNG KHỞI ĐỘNG VÀ ĐIỀU HƯỚNG ỨNG DỤNG (APP BOOT)

Luồng kiểm tra lúc người dùng vừa mở app lên để quyết định xem họ sẽ đi vào màn hình nào.

*   **Bước 1 (Khởi tạo lõi):** Tại hàm `main()`, ứng dụng khởi tạo toàn bộ các API, Repository và Provider.
    [main.dart (Line 42)](file:///c:/.PRM393/.FE/lib/main.dart#L42)
*   **Bước 2 (Chặn cửa tại AuthWrapper):** Ở `MaterialApp`, giao diện đầu tiên được nạp là thẻ `AuthWrapper`. Thẻ này có nhiệm vụ lắng nghe (watch) sự thay đổi trạng thái của `AuthProvider`.
    [main.dart (Line 115)](file:///c:/.PRM393/.FE/lib/main.dart#L115)
*   **Bước 3 (Phân loại người dùng):** Tùy vào biến `isAuthenticated` và `isAdmin` trong `AuthProvider`, `AuthWrapper` sẽ `return` màn hình tương ứng:
    - Nếu `!isAuthenticated` -> Return `LoginScreen()`.
    - Nếu `isAdmin` -> Return `AdminDashboardScreen()`.
    - Nếu User thường -> Return `ChildSelectionScreen()`.
    [main.dart (Line 132-155)](file:///c:/.PRM393/.FE/lib/main.dart#L132-L155)

---

## 2. LUỒNG ĐĂNG NHẬP VÀ XÁC THỰC GOOGLE (AUTHENTICATION)

Đây là ví dụ điển hình của mô hình kiến trúc: `Screen -> Provider -> Repository -> API Client`.

*   **Bước 1 (Bấm nút ở UI):** Người dùng điền Email/Pass và bấm nút "ĐĂNG NHẬP", hoặc bấm nút "Continue with Google". Sự kiện `onPressed` gọi đến hàm nội bộ `_handleEmailLogin` hoặc `_handleGoogleSignIn`.
    [login_screen.dart (Line 344)](file:///c:/.PRM393/.FE/lib/screens/login_screen.dart#L344)
*   **Bước 2 (Gọi Provider):** Hàm `_handleEmailLogin` gọi tiếp hàm `login()` của `authProvider`. Đối với Google, nó lấy `idToken` từ Google Auth rồi truyền vào `loginWithGoogle()`.
    [login_screen.dart (Line 73)](file:///c:/.PRM393/.FE/lib/screens/login_screen.dart#L73)
*   **Bước 3 (Provider điều phối):** `AuthProvider` nhận thông tin, bật trạng thái `_isLoading = true` để UI xoay vòng Loading, sau đó ném dữ liệu xuống tầng dưới `AuthRepository`.
    [auth_provider.dart (Line 45)](file:///c:/.PRM393/.FE/lib/providers/auth_provider.dart#L45)
*   **Bước 4 (API gọi mạng):** `AuthRepository` truyền lệnh cho `AuthApi`, sử dụng thư viện Dio `_dio.post('/Auth/login')` hoặc `_dio.post('/Auth/google')` để đẩy request qua mạng lấy JSON về.
    [auth_api.dart (Line 29)](file:///c:/.PRM393/.FE/lib/services/auth_api.dart#L29)
*   **Bước 5 (Lưu Cache & Hoàn thành):** Sau khi `AuthApi` trả Token về, `AuthRepository` gọi hàm `_saveToken()` để lưu Token vào `FlutterSecureStorage` (bộ nhớ mã hóa). Cuối cùng `AuthProvider` gọi `notifyListeners()`, kích hoạt lại **Bước 2 của Luồng Khởi Động**, đưa user vào app.
    [auth_repository.dart (Line 40)](file:///c:/.PRM393/.FE/lib/repositories/auth_repository.dart#L40)

---

## 3. LUỒNG QUẢN LÝ DỮ LIỆU TỪ VỰNG (ADMIN CRUD FLOW)

Luồng điển hình khi Admin thao tác Quản trị hệ thống (Thêm, Sửa, Tải danh sách).

*   **Bước 1 (Truy cập danh sách):** Từ `AdminDashboardScreen`, bấm chọn "Quản lý Từ vựng", hệ thống chuyển hướng sang `AdminVocabularyListScreen`. Hàm `initState` sẽ gọi API lấy danh sách.
    [admin_dashboard_screen.dart (Line 290)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_dashboard_screen.dart#L290)
*   **Bước 2 (Mở Form Thêm/Sửa):** Bấm nút "Thêm mới" (+), màn hình gọi hàm `_navigateToForm()` và đẩy sang màn `AdminVocabularyFormScreen`.
    [admin_vocabulary_list_screen.dart (Line 81)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_vocabulary_list_screen.dart#L81)
*   **Bước 3 (Gửi dữ liệu lên BE):** Admin điền thông tin và bấm "Lưu". Hàm `_submit()` được kích hoạt, gọi `LessonApi.createVocabulary()` hoặc `updateVocabulary()` tùy vào trạng thái.
    [admin_vocabulary_form_screen.dart (Line 94)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_vocabulary_form_screen.dart#L94)
*   **Bước 4 (Quay về và Cập nhật Data):** Khi lưu thành công, Form gọi `Navigator.pop(context, true)`. Màn hình List nhận được kết quả `true` liền tự động gọi lại hàm `_loadVocabularies()` để re-render lại danh sách mới nhất.
    [admin_vocabulary_list_screen.dart (Line 118)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_vocabulary_list_screen.dart#L118)

---

## 4. LUỒNG HỌC TỪ VỰNG VÀ MINI GAMES (LESSON PROGRESS & MINI GAMES)

Luồng điều hướng cốt lõi khi một em bé học một chủ đề mới và trải qua các vòng Mini-game.

*   **Bước 1 (Mở Bài học):** Bé nhấn vào một bài học trong màn hình `TopicDetailScreen`. Ứng dụng điều hướng sang `LessonDetailScreen`.
    [lesson_detail_screen.dart (Line 60)](file:///c:/.PRM393/.FE/lib/screens/lesson_detail_screen.dart#L60)
*   **Bước 2 (Thực hiện Mini-game):** Trong màn `LessonDetailScreen`, tiến trình được chia thành 5 nút tương ứng với 5 hoạt động (Học từ -> Quiz -> Luyện nghe -> Phát âm -> Đánh Boss).
    [lesson_detail_screen.dart (Line 294)](file:///c:/.PRM393/.FE/lib/screens/lesson_detail_screen.dart#L294)
*   **Bước 3 (Ghi nhận kết quả Game):** Khi bấm vào 1 Game (ví dụ: Boss Battle), ứng dụng gọi `await Navigator.push(...)`.
    Khi bé hoàn thành hoặc giết được Boss, trong các game sẽ gọi `Navigator.pop(context, true)`.
    [boss_battle_screen.dart (Line 268)](file:///c:/.PRM393/.FE/lib/screens/boss_battle_screen.dart#L268)
*   **Bước 4 (Mở khóa chặn tiếp theo):** Màn `LessonDetailScreen` nhận biến `true` trả về, lập tức cập nhật trạng thái của Game đó thành đã hoàn thành (ví dụ: `setState(() { _bossCompleted = true; })`) để bật sáng tick xanh và mở khóa Game tiếp theo.
    [lesson_detail_screen.dart (Line 599)](file:///c:/.PRM393/.FE/lib/screens/lesson_detail_screen.dart#L599)

---

## 5. LUỒNG TÍNH ĐIỂM, LƯU TRỮ VÀ HUY HIỆU (PROGRESS SUBMIT & ACHIEVEMENTS)

Sau khi bé hoàn thành chặng cuối (Đánh Boss), điểm số sẽ được gửi lên Server và nhận phần thưởng.

*   **Bước 1 (Gọi hàm Finish Lesson):** Sau khi biến `_bossCompleted` được bật thành `true` ở bước 4 của luồng trên, hệ thống gọi tự động hàm `_finishLesson()`.
    [lesson_detail_screen.dart (Line 167)](file:///c:/.PRM393/.FE/lib/screens/lesson_detail_screen.dart#L167)
*   **Bước 2 (Gửi API Submit):** Hàm này thu thập % điểm số của toàn bộ 5 vòng chơi, tính thời gian chơi và gọi `progressProvider.submitProgress(...)` để đẩy lên Backend.
    [progress_provider.dart (Line 120)](file:///c:/.PRM393/.FE/lib/providers/progress_provider.dart#L120)
*   **Bước 3 (Hiển thị Pop-up Huy hiệu):** Khi Backend báo thành công, UI sẽ hiển thị một Dialog rực rỡ chức mừng bé nhận được Sao (Stars) và Huy hiệu mới.
    [lesson_detail_screen.dart (Line 206)](file:///c:/.PRM393/.FE/lib/screens/lesson_detail_screen.dart#L206)
*   **Bước 4 (Cập nhật tab Thành Tích):** Khi sang màn hình `AchievementsScreen`, ứng dụng kiểm tra danh sách `progressProvider.completedLessons.length`. Dựa vào số lượng bài học hoàn thành, nó sẽ tự động render các Huy Hiệu Pokemon (Mock Badges từ Frontend) để hiển thị lên lưới Thành Tích.
    [achievements_screen.dart (Line 145)](file:///c:/.PRM393/.FE/lib/screens/achievements_screen.dart#L145)

---

## 6. LUỒNG BẮT LỖI VÀ DỊCH TỰ ĐỘNG BẰNG SNACKBAR (ERROR HANDLING)

Quá trình bắt câu chữ tiếng Anh thô kệch của Backend và dịch tự động sang tiếng Việt thân thiện.

*   **Bước 1 (Xảy ra lỗi ở tầng API):** Khi Admin tạo trùng tên Bài học, `LessonApi` ném ra một `DioException` chứa Status 400 và `Message: "A lesson with this name already exists"`.
*   **Bước 2 (Lỗi nảy lên Screen):** Lỗi này ném ngược lên `AdminLessonFormScreen` qua khối `try...catch`. Code trên Screen gọi hàm `CustomSnackBar.showError(context, e)`.
    [admin_lesson_form_screen.dart (Line 110)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_lesson_form_screen.dart#L110)
*   **Bước 3 (Xử lý dịch thuật tại Utils):** Hàm `showError` truyền biến `e` vào màng lọc `_parseErrorMessage(e)`. Màng lọc này kiểm tra chuỗi string bên trong. Nếu nó thấy chữ `"already exists"` -> Tự động đổi biến nội dung thành `"Tên bài học đã tồn tại"`. Cuối cùng, gọi hàm hiển thị một SnackBar màu đỏ lên màn hình.
    [snackbar_utils.dart (Line 42)](file:///c:/.PRM393/.FE/lib/utils/snackbar_utils.dart#L42)

---

## 7. LUỒNG AUTO-INCREMENT ORDER INDEX (NGHIỆP VỤ ADMIN)

Đây là luồng Backend tự động gợi ý điền số (Auto-increment) tiện dụng cho Admin khi tạo mới Dữ liệu.

*   **Bước 1 (Admin click Thêm Mới):** Đang ở danh sách Bài học (`AdminLessonListScreen`), Admin bấm nút dấu `(+)`. Nút này gọi hàm `_navigateToForm()`.
    [admin_lesson_list_screen.dart (Line 96)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_lesson_list_screen.dart#L96)
*   **Bước 2 (Tính toán số tiếp theo):** Trong hàm `_navigateToForm()`, code lấy mảng danh sách bài học hiện tại (`_lessons`). Nếu mảng rỗng thì gán số `1`. Nếu mảng có data, nó duyệt mảng tìm cái `orderIndex` lớn nhất (`reduce()`) rồi cộng (+) thêm `1`. Đặt tên biến là `nextOrderIndex`.
*   **Bước 3 (Đẩy sang Form):** Gọi `Navigator.push` và nhét biến `nextOrderIndex` ném sang class `AdminLessonFormScreen`.
    [admin_lesson_list_screen.dart (Line 105)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_lesson_list_screen.dart#L105)
*   **Bước 4 (Khởi tạo ô Text):** Tại `initState` của trang Form, code kiểm tra thấy có `nextOrderIndex` được ném qua. Nó gán ngay cái số đó vào ô Text field. Nên khi màn hình vừa bật lên, ô số thứ tự đã được điền sẵn.
    [admin_lesson_form_screen.dart (Line 45)](file:///c:/.PRM393/.FE/lib/screens/admin/admin_lesson_form_screen.dart#L45)

---

## 8. LUỒNG THU ÂM VÀ CHẤM ĐIỂM PHÁT ÂM AI (AI PRONUNCIATION FLOW)

Luồng chủ chốt khi bé luyện phát âm, app sẽ ghi âm và AI sẽ chấm điểm độ chính xác.

*   **Bước 1 (Bắt đầu Ghi âm):** Bé nhấn vào biểu tượng Micro, hệ thống gọi hàm `_startRecording()` sử dụng thư viện `record` lưu tạm thời file âm thanh `.wav` vào bộ nhớ máy.
    [pronunciation_challenge_screen.dart (Line 87)](file:///c:/.PRM393/.FE/lib/screens/pronunciation_challenge_screen.dart#L87)
*   **Bước 2 (Kết thúc & Đóng gói):** Bé nhấn lại nút Micro để dừng. Hàm `_stopAndSubmit()` được gọi, đóng gói file `.wav` và hiện màn hình "AI is evaluating...".
    [pronunciation_challenge_screen.dart (Line 116)](file:///c:/.PRM393/.FE/lib/screens/pronunciation_challenge_screen.dart#L116)
*   **Bước 3 (Gửi lên Server chấm):** Giao diện gọi `pronProvider.submitPronunciation(...)` đẩy audio file lên Backend dưới dạng Form Data để AI phân tích.
    [pronunciation_challenge_screen.dart (Line 139)](file:///c:/.PRM393/.FE/lib/screens/pronunciation_challenge_screen.dart#L139)
*   **Bước 4 (Hiển thị Kết quả & Động viên):** Backend trả về `PronunciationScore`. UI vẽ Vòng tròn điểm số (Xanh lá nếu >= 60đ, Cam nếu thấp hơn) và gọi `_playTtsFeedback(score)` phát giọng AI động viên (VD: "Excellent", "Great job", "Try again").
    [pronunciation_challenge_screen.dart (Line 168)](file:///c:/.PRM393/.FE/lib/screens/pronunciation_challenge_screen.dart#L168)

---

## 9. LUỒNG BẢNG ĐIỀU KHIỂN PHỤ HUYNH (PARENT DASHBOARD FLOW)

Luồng Phụ huynh theo dõi thông tin, tạo hồ sơ mới và xem kết quả học tập.

*   **Bước 1 (Mở Dashboard):** Bấm vào icon Phụ Huynh, sau khi nhập mã PIN (nếu có), hệ thống mở màn hình `ParentDashboardScreen`.
    [parent_dashboard_screen.dart (Line 15)](file:///c:/.PRM393/.FE/lib/screens/parent_dashboard_screen.dart#L15)
*   **Bước 2 (Tải dữ liệu tổng quan):** Khi giao diện khởi tạo, hàm `initState` gọi `_reloadData()`, từ đó kích hoạt `DashboardProvider.loadOverview()` và `ChildProvider.loadChildren()`.
    [parent_dashboard_screen.dart (Line 36)](file:///c:/.PRM393/.FE/lib/screens/parent_dashboard_screen.dart#L36)
*   **Bước 3 (Xem nhật ký học tập):** Khi Phụ huynh chọn Tab "Nhật Ký Học", giao diện gọi `_buildActivityLogTab()` để render dữ liệu `progressProvider.recentActivities` (Lịch sử bài học, điểm số, và số sao của bé).
    [parent_dashboard_screen.dart (Line 164)](file:///c:/.PRM393/.FE/lib/screens/parent_dashboard_screen.dart#L164)
*   **Bước 4 (Quản lý Hồ sơ trẻ):** Khi Phụ huynh chuyển sang Tab "Quản Lý Trẻ", họ có thể thêm bé mới bằng cách bấm nút "Thêm Bé Mới". Hành động này mở `CreateProfileScreen` qua lệnh `Navigator.push()`.
    [parent_dashboard_screen.dart (Line 448)](file:///c:/.PRM393/.FE/lib/screens/parent_dashboard_screen.dart#L448)
