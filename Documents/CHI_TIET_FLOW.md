# CHI TIẾT LUỒNG HOẠT ĐỘNG TOÀN DIỆN (TỪ A-Z)

Tài liệu này là bản phân tích "giải phẫu" cực kỳ chi tiết toàn bộ dự án KIDIO (Frontend).
Tài liệu được viết với mục tiêu: **Dù bạn là một người mới hoàn toàn (Newbie) hay không rành về kỹ thuật, bạn vẫn có thể hiểu tường tận cách ứng dụng hoạt động thông qua các ví dụ thực tế.**

Bạn có thể **bấm trực tiếp vào các đường link màu xanh** để IDE nhảy ngay đến đúng dòng code/file đó.

---

## MỞ ĐẦU: HIỂU VỀ KIẾN TRÚC NHÀ HÀNG (MVVM PATTERN)
Toàn bộ dự án này được viết theo mô hình phân tầng. Để dễ hiểu, hãy tưởng tượng ứng dụng của chúng ta là một **Nhà Hàng 5 Sao**:

1. **Screen / Widget (Tầng Giao diện):** Chính là *Bàn ăn của khách*. Khách chỉ việc ngồi xem Menu (Giao diện) và bấm nút gọi món. Bàn ăn KHÔNG BAO GIỜ tự chạy vào bếp nấu ăn.
2. **Provider (Người Quản lý Trạng thái):** Chính là *Anh phục vụ (Waiter)*. Khi khách bấm nút, anh phục vụ sẽ ghi nhận. Anh ta chạy vào bếp báo order. Khi đồ ăn chín, anh ta mang ra bàn và hô to (notifyListeners) "Đồ ăn ra rồi!". Lúc này bàn ăn tự động hiện món. Khái niệm này gọi là **State Management (Quản lý trạng thái)**.
3. **Repository (Quản lý kho nguyên liệu):** Chính là *Bếp trưởng*. Bếp trưởng không trực tiếp nấu, nhưng ông ta biết chỗ để lấy nguyên liệu. Nếu nguyên liệu có sẵn trong tủ lạnh (Local Cache), ông lấy luôn cho nhanh. Nếu không có, ông sai người ra chợ mua (Gọi API xuống Backend).
4. **API Service (Người đi chợ):** Đi xe máy tới địa chỉ cái chợ (BaseURL của Backend) để chở nguyên liệu (Data) về.
5. **Models (Khuôn mẫu):** Chợ bán đồ thô, lộn xộn (chuỗi JSON). Khi mang về, nhân viên phải phân loại, đổ vào từng cái khuôn định hình sẵn (Dart Object) để đầu bếp dễ dùng. Quá trình này gọi là **JSON Serialization**.

---

## 1. Cấu hình Cốt lõi & Kiến trúc mạng (Core & Network Layer)

1. **[main.dart](file:///c:/.PRM393/.FE/lib/main.dart)**: Cánh cửa chính của nhà hàng. Khi mở app lên, file này sẽ khởi tạo toàn bộ *Nhân viên* (Provider, Repo). Nó dùng một bảo vệ tên là `AuthWrapper` đứng ở cửa để phân loại khách: Khách chưa có vé -> Đuổi ra `LoginScreen`. Khách VIP (Admin) -> Mời vào `AdminDashboardScreen`. Khách vãng lai -> Mời vào `ChildSelectionScreen`.
2. **[api_client.dart](file:///c:/.PRM393/.FE/lib/api/api_client.dart)**: Chiếc xe tải chở hàng (dùng thư viện `Dio`). 
   *   **Khái niệm Interceptor:** Hãy tưởng tượng `Interceptor` như một hành động *Tự động giơ thẻ VIP*. Mỗi khi bạn muốn xin dữ liệu từ Backend, bạn phải có vé `JWT Token`. Thay vì mỗi lần gọi API bạn phải tự móc ví ra lấy vé, `Interceptor` sẽ tự động dán cái vé đó lên kính xe tải của bạn mọi lúc mọi nơi. Backend nhìn thấy vé hợp lệ là cho qua luôn.
3. **[api_response.dart](file:///c:/.PRM393/.FE/lib/models/api_response.dart)** & **[api_response.g.dart](file:///c:/.PRM393/.FE/lib/models/api_response.g.dart)**: Quy chuẩn đóng gói. Trả về lúc nào cũng có 3 hộp: *Trạng thái (Status)*, *Lời nhắn (Message)* và *Thức ăn (Data)*.
4. **[kidio_models.dart](file:///c:/.PRM393/.FE/lib/models/kidio_models.dart)** & **[kidio_models.g.dart](file:///c:/.PRM393/.FE/lib/models/kidio_models.g.dart)**: Các khuôn đúc nguyên liệu (Bé, Bài học, Chủ đề).
5. **[cache_service.dart](file:///c:/.PRM393/.FE/lib/local/cache_service.dart)**: Tủ lạnh siêu tốc (dùng thư viện `Hive`). Cất những dữ liệu hay dùng để khỏi đi chợ nhiều lần, giúp app chạy mượt kể cả khi cá mập cắn cáp.

---

## 2. Luồng Xác thực & Đăng nhập (Authentication Flow)

**Ví dụ thực tế:** Khách đến cửa xin thẻ thành viên. Nếu hợp lệ, bảo vệ cấp cho khách một cái vòng tay VIP (JWT Token). Đeo vòng tay này, khách muốn đi đâu trong quán cũng được.

1. **[login_screen.dart](file:///c:/.PRM393/.FE/lib/screens/login_screen.dart)**: Quầy điền đơn đăng nhập. Khách bấm nút, quầy gọi anh phục vụ `authProvider.login()`.
2. **[register_screen.dart](file:///c:/.PRM393/.FE/lib/screens/register_screen.dart)**: Quầy đăng ký thành viên mới.
3. **[verify_email_screen.dart](file:///c:/.PRM393/.FE/lib/screens/verify_email_screen.dart)**: Phòng chờ xác thực Email. *Điểm đặc biệt:* Nếu khách nhấn "Tiếp tục" thành công, hệ thống bắt buộc khách tạo mã số két sắt (Mã PIN 4 số) để giữ đồ.
4. **[forgot_password_screen.dart](file:///c:/.PRM393/.FE/lib/screens/forgot_password_screen.dart)** & **[change_password_screen.dart](file:///c:/.PRM393/.FE/lib/screens/change_password_screen.dart)**: Nơi đổi và khôi phục mật khẩu.
5. **[auth_provider.dart](file:///c:/.PRM393/.FE/lib/providers/auth_provider.dart)**: Quản lý trạng thái Đăng nhập. Đây là người sẽ cầm loa hô to: "Khách này đã có vé VIP rồi nha mọi người!". Ngay lập tức `main.dart` nghe thấy và mở cửa cho khách vào app.
6. **[auth_repository.dart](file:///c:/.PRM393/.FE/lib/repositories/auth_repository.dart)**: Két sắt bảo mật. Dùng `FlutterSecureStorage` (công nghệ mã hóa chuẩn của hệ điều hành điện thoại) để cất giấu cái vòng tay VIP (Token) và Mã PIN. Kể cả hacker bẻ khóa máy cũng khó mà trộm được.
7. **[auth_api.dart](file:///c:/.PRM393/.FE/lib/services/auth_api.dart)**: File ghi địa chỉ đi tới trụ sở Backend để kiểm tra chứng minh thư của khách (Đường dẫn `/api/Auth/...`).

---

## 3. Luồng Quản lý Bảo mật Phụ huynh (Parent Security Flow)

**Ví dụ thực tế:** Trong khu vui chơi của bé có một "Phòng Kỹ Thuật" đầy máy móc nguy hiểm. Muốn mở cửa phòng này, người lớn phải bấm đúng 4 số trên ổ khóa.

1. **[parent_pin_dialogs.dart](file:///c:/.PRM393/.FE/lib/widgets/parent_pin_dialogs.dart)**: Ổ khóa mã số. Chứa giao diện vẽ ra 4 ô vuông để phụ huynh bấm số, kèm theo logic kiểm tra xem số bấm có khớp với số trong két sắt không.
2. **[child_selection_screen.dart](file:///c:/.PRM393/.FE/lib/screens/child_selection_screen.dart)**: Phòng sảnh chờ. Nơi hiển thị các bé (danh sách con). Trên góc có cánh cửa ghi chữ "Phụ Huynh", bấm vào đây thì cái "Ổ khóa mã số" ở trên sẽ hiện ra chặn lại.
3. **[parent_dashboard_screen.dart](file:///c:/.PRM393/.FE/lib/screens/parent_dashboard_screen.dart)**: Căn phòng sau cánh cửa. Nếu bấm PIN đúng, phụ huynh được vào đây để xem "Camera an ninh" (Nhật ký học tập của bé).
4. **[child_provider.dart](file:///c:/.PRM393/.FE/lib/providers/child_provider.dart)**: Trực ban sảnh chờ. Nhớ mặt xem "Đứa bé nào đang được chọn" để lát nữa phát đúng sách giáo khoa cho đứa bé đó học.
5. **[child_repository.dart](file:///c:/.PRM393/.FE/lib/repositories/child_repository.dart)** & **[child_api.dart](file:///c:/.PRM393/.FE/lib/services/child_api.dart)**: Hồ sơ lưu trữ thông tin tên, tuổi, avatar của từng bé.

---

## 4. Luồng Học tập dành cho Trẻ (Kids Learning Flow)

1. **[topics_list_screen.dart](file:///c:/.PRM393/.FE/lib/screens/topics_list_screen.dart)**: Kệ sách lớn. Hiện các chủ đề. Việc vẽ giao diện từng ô sách được giao phó cho người thợ chuyên nghiệp ở **[topics_list_widget.dart](file:///c:/.PRM393/.FE/lib/widgets/topics_list_widget.dart)** để tái sử dụng ở nhiều nơi.
2. **[topic_detail_screen.dart](file:///c:/.PRM393/.FE/lib/screens/topic_detail_screen.dart)**: Mở 1 chủ đề ra sẽ thấy danh sách các Chương (Lessons).
3. **[lesson_detail_screen.dart](file:///c:/.PRM393/.FE/lib/screens/lesson_detail_screen.dart)**: Chi tiết của một bài học dạng truyện (Story).
4. **[vocabulary_quiz_screen.dart](file:///c:/.PRM393/.FE/lib/screens/vocabulary_quiz_screen.dart)**: Sân chơi Thẻ bài (Flashcard). Vẽ hình ảnh bự, chữ tiếng Anh bự. Khi quẹt thẻ, ứng dụng tự động đọc tiếng Anh (nhờ Audio Service).
5. **[content_parser.dart](file:///c:/.PRM393/.FE/lib/utils/content_parser.dart)**: Máy phiên dịch. Dữ liệu bài học trên mạng tải về là một cụm chữ loằng ngoằng (JSON string). File này có nhiệm vụ dịch nó ra thành danh sách các thẻ bài thật sự để đưa cho `vocabulary_quiz_screen` vẽ.
6. **Khu vực Nhà kho lấy dữ liệu (Logic & API):** 
   Đều tuân thủ quy trình gọi đồ ăn: Phục vụ (Provider) -> Bếp (Repository) -> Chợ (API)
   - Topic: **[topic_provider.dart](file:///c:/.PRM393/.FE/lib/providers/topic_provider.dart)** -> **[topic_repository.dart](file:///c:/.PRM393/.FE/lib/repositories/topic_repository.dart)** -> **[topic_api.dart](file:///c:/.PRM393/.FE/lib/services/topic_api.dart)**
   - Lesson: **[lesson_repository.dart](file:///c:/.PRM393/.FE/lib/repositories/lesson_repository.dart)** -> **[lesson_api.dart](file:///c:/.PRM393/.FE/lib/services/lesson_api.dart)**
   - Vocabulary: **[vocabulary_repository.dart](file:///c:/.PRM393/.FE/lib/repositories/vocabulary_repository.dart)** -> **[vocabulary_api.dart](file:///c:/.PRM393/.FE/lib/services/vocabulary_api.dart)**

---

## 5. Luồng Đa phương tiện & Xử lý âm thanh (Media & Audio Flow)

**Ví dụ:** Một cái máy phát thanh viên tàng hình giấu sau bức tường. Khi bé chạm vào chữ, máy này sẽ phát ra tiếng người đọc.

1. **[audio_player_service.dart](file:///c:/.PRM393/.FE/lib/services/audio_player_service.dart)**: Bảng mạch điều khiển cái loa (Phát, Tạm dừng, Tắt). Bọc thư viện `audioplayers`.
2. **[tts_api.dart](file:///c:/.PRM393/.FE/lib/services/tts_api.dart)** & **[tts_repository.dart](file:///c:/.PRM393/.FE/lib/repositories/tts_repository.dart)**: Robot đọc tiếng (Text-to-Speech). Gửi chữ tiếng Anh xuống Backend, Backend trả về 1 file âm thanh `.mp3` giọng Mỹ chuẩn để loa phát lên.
3. **[pronunciation_api.dart](file:///c:/.PRM393/.FE/lib/services/pronunciation_api.dart)**, **[pronunciation_repository.dart](file:///c:/.PRM393/.FE/lib/repositories/pronunciation_repository.dart)**, **[pronunciation_provider.dart](file:///c:/.PRM393/.FE/lib/providers/pronunciation_provider.dart)**: Máy thu âm và chấm điểm. Bé bấm nút micro đọc vào máy. File này sẽ gói file âm thanh đó gửi lên Backend AI, nhận về số điểm (vd: 80/100đ) để khen ngợi bé.

---

## 6. Luồng Nhật ký & Thành tích (Progress & Achievements)

**Ví dụ:** Cô giáo cầm sổ liên lạc đi theo dõi bé. Khi bé học xong, cô ghi vào sổ "Hôm nay hoàn thành 100%".

1. **[achievements_screen.dart](file:///c:/.PRM393/.FE/lib/screens/achievements_screen.dart)**: Tủ trưng bày cúp.
2. **[progress_provider.dart](file:///c:/.PRM393/.FE/lib/providers/progress_provider.dart)**: Cô giáo. Khi thấy bé quẹt xong bộ Flashcard cuối cùng, cô giáo lập tức viết báo cáo gửi lên cấp trên (Backend) qua hàm update progress.
3. **[progress_repository.dart](file:///c:/.PRM393/.FE/lib/repositories/progress_repository.dart)** & **[progress_api.dart](file:///c:/.PRM393/.FE/lib/services/progress_api.dart)**: Đường bưu điện gửi báo cáo lên Backend.
4. **[achievement_repository.dart](file:///c:/.PRM393/.FE/lib/repositories/achievement_repository.dart)** & **[achievement_api.dart](file:///c:/.PRM393/.FE/lib/services/achievement_api.dart)**: Nơi nhận bằng khen (huy hiệu) từ Backend về.

---

## 7. Luồng Quản trị viên Toàn quyền (Admin CRUD Flow)

**Ví dụ:** Quyền sinh sát của người quản lý tổng. Bất cứ chỉnh sửa nào ở đây, cả hệ thống app của trẻ em sẽ thay đổi theo.

1. **[admin_dashboard_screen.dart](file:///c:/.PRM393/.FE/lib/screens/admin/admin_dashboard_screen.dart)**: Bảng thống kê doanh thu (số lượng bài học/chủ đề). Lấy số liệu qua **[dashboard_provider.dart](file:///c:/.PRM393/.FE/lib/providers/dashboard_provider.dart)**, **[dashboard_repository.dart](file:///c:/.PRM393/.FE/lib/repositories/dashboard_repository.dart)** và **[dashboard_api.dart](file:///c:/.PRM393/.FE/lib/services/dashboard_api.dart)**.
2. Quản lý Chủ đề: **[admin_topic_list_screen.dart](file:///c:/.PRM393/.FE/lib/screens/admin/admin_topic_list_screen.dart)** & **[admin_topic_form_screen.dart](file:///c:/.PRM393/.FE/lib/screens/admin/admin_topic_form_screen.dart)**
3. Quản lý Bài học: **[admin_lesson_list_screen.dart](file:///c:/.PRM393/.FE/lib/screens/admin/admin_lesson_list_screen.dart)** & **[admin_lesson_form_screen.dart](file:///c:/.PRM393/.FE/lib/screens/admin/admin_lesson_form_screen.dart)**
4. Quản lý Từ vựng: **[admin_vocabulary_list_screen.dart](file:///c:/.PRM393/.FE/lib/screens/admin/admin_vocabulary_list_screen.dart)** & **[admin_vocabulary_form_screen.dart](file:///c:/.PRM393/.FE/lib/screens/admin/admin_vocabulary_form_screen.dart)**

**Điểm nhấn cực mạnh ghi điểm (Smart UI/UX):**
*   *Tự động lấy số tiếp theo:* Trong các màn hình `_list_screen`, khi bấm "Thêm mới", code tự động duyệt tìm số thứ tự lớn nhất, +1 vào, rồi truyền qua form để điền sẵn.
*   *Màng lọc máy phiên dịch:* (Xem bên dưới).

---

## 8. Tiện ích dùng chung (Utilities)

1. **[snackbar_utils.dart](file:///c:/.PRM393/.FE/lib/utils/snackbar_utils.dart)**: Một cái **"Máy Dịch Thuật Đa Ngôn Ngữ"**. 
   - **Ví dụ:** Bình thường khi Admin nhập lỗi (Trùng tên bài học), Backend sẽ mắng một câu tiếng Tây rất cục súc: `"Exception: A topic with this name already exists"`. Nếu quăng nguyên câu này lên màn hình, app sẽ trông rất phèn và khó xài. 
   - **Giải pháp:** File này đóng vai trò như một thư ký, chặn câu chửi của Backend lại, phân tích chữ bên trong, và cười tươi nói bằng tiếng Việt với Admin: `"Dạ, tên chủ đề này đã tồn tại, anh/chị vui lòng chọn tên khác nhé!"` hiển thị dưới dạng một dải ruy-băng thông báo (SnackBar) màu đỏ siêu đẹp mà không hề làm đứng app.

---
*(Hết tài liệu)*
