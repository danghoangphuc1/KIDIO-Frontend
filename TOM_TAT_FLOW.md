# TÓM TẮT LUỒNG HOẠT ĐỘNG (FLOW) CỦA DỰ ÁN KIDIO

Dưới đây là kịch bản luồng hoạt động chi tiết của ứng dụng tính đến thời điểm hiện tại (Cột mốc 50%), được sắp xếp theo đúng trình tự trải nghiệm của người dùng để bạn có thể dễ dàng trình bày với Thầy.

---

### 1. Luồng Khởi động & Xác thực (Authentication Flow)

Dự án hiện hỗ trợ 2 phương thức đăng nhập chính:

**Cách 1: Đăng ký & Xác thực qua Email truyền thống**
1. Người dùng mở app, chọn **Đăng ký** tài khoản mới bằng Email và Mật khẩu.
2. Ứng dụng chuyển sang màn hình **Chờ xác thực Email (Verify Email Screen)**. Hệ thống backend sẽ tự động gửi một email chứa link xác nhận đến hộp thư của người dùng.
3. Người dùng mở mail (trên máy tính hoặc ngay trên điện thoại), nhấn vào nút **"OPEN THE KIDIO APP"**.
4. Trạng thái xác thực thành công. Trên app, người dùng nhấn nút **"Tiếp tục"**.
5. **[Bảo mật]** Ngay lập tức, hệ thống yêu cầu phụ huynh thiết lập **Mã PIN 4 số** (Nhập lần 1 và nhập lần 2 để xác nhận). Đây là chốt chặn bảo vệ để trẻ không tự ý truy cập vào khu vực cài đặt.

**Cách 2: Đăng nhập nhanh bằng Google (Google Login)**
1. Tại màn hình Đăng nhập, người dùng nhấn chọn **Đăng nhập bằng Google**.
2. Sau khi cho phép liên kết tài khoản thành công, người dùng được đưa thẳng vào ứng dụng.
3. **[Bảo mật]** Tương tự như trên, do là tài khoản mới tinh chưa có mã PIN, hệ thống sẽ tự động chặn lại và yêu cầu phụ huynh thiết lập **Mã PIN 4 số** trước khi cho phép bắt đầu sử dụng.

---

### 2. Luồng Thiết lập ban đầu & Chọn bé (Child Onboarding Flow)

Sau khi tạo Mã PIN thành công, tài khoản mới sẽ được đưa đến màn hình **Chọn bé (Child Selection Screen)**.
1. Do chưa có dữ liệu, phụ huynh buộc phải nhấn nút **Thêm bé**.
2. Phụ huynh điền thông tin cơ bản: *Tên của bé, Tuổi* và chọn một *Avatar ngộ nghĩnh* (đã được lưu cache trên thiết bị để load nhanh).
3. Sau khi Thêm bé thành công, avatar và tên bé sẽ hiện lên danh sách. 
4. Phụ huynh / Bé bấm chọn vào hình ảnh của bé đó để chính thức **bắt đầu phiên học**. Mọi tiến độ học tập từ lúc này trở đi sẽ được ghi nhận riêng cho bé vừa chọn (hỗ trợ 1 tài khoản có thể có nhiều bé).

---

### 3. Luồng Học tập chính dành cho Trẻ (Kids Learning Flow)

Đây là khu vực lõi của ứng dụng với thiết kế đầy màu sắc, trực quan cho trẻ:
1. **Màn hình Chủ đề (Topics List):** Hiển thị danh sách các chủ đề lớn (Động vật, Màu sắc, Trái cây...). Các chủ đề này được gọi trực tiếp từ Database.
2. **Màn hình Bài học (Lesson Selection):** Khi bé chọn 1 chủ đề, danh sách các bài học thuộc chủ đề đó sẽ hiện ra (Ví dụ: Học tên động vật nuôi, Học tên động vật hoang dã...).
3. **Màn hình Học Từ vựng (Flashcard/Vocabulary Screen):**
   - Khi bé vào một bài học, các từ vựng sẽ được hiển thị dưới dạng **Thẻ Flashcard**.
   - Mỗi thẻ có chứa: Hình ảnh minh họa lớn, Từ vựng Tiếng Anh, Phiên âm.
   - Khi bé nhấn vào nút cái Loa (hoặc khi vuốt sang thẻ mới), ứng dụng sẽ **tự động phát âm thanh** đọc từ vựng đó bằng giọng tiếng Anh bản ngữ (sử dụng thư viện AudioPlayers).
   - Dữ liệu hoàn thành bài học của bé sẽ được đồng bộ ngầm về Backend để ghi nhận.

---

### 4. Luồng Bảo mật & Quản lý dành cho Phụ huynh (Parent Zone Flow)

Khu vực này được thiết kế dành riêng cho người lớn, chặn sự can thiệp của trẻ:
1. Tại màn hình Chọn bé hoặc bất kỳ đâu có icon **Phụ huynh (Parent)**, nếu người dùng bấm vào, một **Hộp thoại yêu cầu nhập mã PIN** sẽ hiện ra.
2. Bé không biết mã PIN nên không thể vào. Phụ huynh nhập đúng mã PIN 4 số sẽ được đưa vào **Bảng điều khiển Phụ huynh (Parent Dashboard)**.
3. **Các tính năng tại đây:**
   - **Nhật ký học tập:** Phụ huynh có thể xem thống kê chính xác bé nào đã học bài nào, hoàn thành vào ngày nào. (Đã xử lý triệt để việc tách biệt dữ liệu nếu nhà có 2-3 bé học chung 1 tài khoản).
   - **Quản lý danh sách bé:** Chỉnh sửa thông tin, đổi avatar hoặc thêm bé thứ 2, thứ 3.
   - **Bảo mật:** Đổi mật khẩu tài khoản, Đổi mã PIN, Đăng xuất.

---

### 5. Luồng Quản trị viên (Admin Flow - Dành cho người vận hành App)

Luồng này dành để trình bày về phần nghiệp vụ Quản trị hệ thống (CRUD):
1. **Đăng nhập quyền Admin:** Khi dùng tài khoản cấp Admin đăng nhập, ứng dụng bỏ qua màn hình chọn bé và nhảy thẳng vào **Admin Dashboard**.
2. **Quản lý dữ liệu (Topics, Lessons, Vocabularies):** 
   - Admin có thể Xem, Thêm mới, Chỉnh sửa, và Xóa các Chủ đề, Bài học và Từ vựng.
   - Đối với Bài học, Admin có nút **Publish/Unpublish** để quyết định bài học đó đã sẵn sàng hiển thị trên app của trẻ hay chưa.
3. **Nghiệp vụ thông minh (Smart UI/UX):** 
   - Ứng dụng tự động tính toán và điền sẵn số **Thứ tự hiển thị (Order Index) kế tiếp** mỗi khi Admin muốn tạo mới mục nào đó, giúp nhập liệu cực nhanh.
   - Nếu Admin cố tình tạo nội dung bị trùng lặp (Trùng tên bài học/chủ đề hoặc Trùng số thứ tự hiển thị), thay vì văng lỗi kỹ thuật khó hiểu (DioException), hệ thống sẽ **bắt lỗi từ Backend và tự động dịch thành thông báo Tiếng Việt đẹp mắt** trên màn hình để hướng dẫn Admin sửa lại.

---
*(Hết tài liệu Tóm tắt luồng)*
