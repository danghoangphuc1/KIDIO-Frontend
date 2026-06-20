# BÁO CÁO DỰ ÁN 50% - MÔN HỌC
**Tên dự án:** KIDIO - Ứng dụng học tập giáo dục dành cho trẻ em

---

### 1. Giới thiệu (Introduction)
KIDIO là một ứng dụng di động giáo dục tương tác được thiết kế đặc biệt dành cho trẻ em. Ứng dụng giúp các bé làm quen và học tiếng Anh cùng các kiến thức cơ bản về thế giới xung quanh (màu sắc, hình khối, con vật, phương tiện...) thông qua các bài học sinh động và các bài trắc nghiệm (Quiz) thú vị. Dự án cung cấp hai không gian riêng biệt: Không gian học tập vui nhộn, đầy màu sắc cho bé và Bảng điều khiển (Dashboard) dành cho Phụ huynh/Quản trị viên để theo dõi tiến độ và quản lý nội dung.

### 2. Phạm vi dự án (Scope Project)
Dự án tập trung vào việc xây dựng nền tảng học tập trên thiết bị di động (Mobile App) và hệ thống Backend quản lý tập trung.
- **Đối tượng sử dụng:** Trẻ em (học tập, làm bài tập) và Phụ huynh/Quản trị viên (theo dõi tiến độ, quản lý nội dung bài học).
- **Phạm vi tính năng:** Cung cấp hệ thống bài học được phân loại theo chủ đề (Topics -> Lessons -> Vocabularies), hệ thống trắc nghiệm từ vựng tương tác, tính năng phát âm thông minh (Text-to-Speech), hệ thống hỗ trợ dịch ngôn ngữ và hệ thống khen thưởng bằng Huy hiệu (Thành tích) nhằm tạo động lực học tập cho trẻ.

### 3. Link Figma
[Tôi đã có - Bạn hãy chèn link Figma của nhóm vào đây]

### 4. Link GitHub
[Tôi đã có - Bạn hãy chèn link Github của nhóm vào đây]

### 5. Kỹ thuật (Technical)
- **Frontend:** Mobile App được phát triển bằng **Flutter** (ngôn ngữ Dart), hỗ trợ đa nền tảng (iOS & Android).
- **State Management:** Sử dụng **Provider** để quản lý trạng thái luồng dữ liệu của ứng dụng.
- **Backend:** Phát triển bằng **.NET Core (C#)** - Web API.
- **Cơ sở dữ liệu (Database):** **SQL Server**.
- **Tích hợp bên thứ 3 (Third-party APIs):** 
  - Tích hợp API **Google Translate** (Hỗ trợ tự động dịch nội dung bài học sang tiếng Việt).
  - Tích hợp API **Text-to-Speech (Google TTS / Youdao)** để hỗ trợ phát âm từ vựng tiếng Anh chuẩn xác trực tiếp trên ứng dụng.

### 6. Các tính năng và màn hình đã hoàn thành
**Không gian dành cho Trẻ em (Child Interface):**
- **Màn hình chọn tài khoản (Child Selection Screen):** Giao diện thân thiện cho phép chọn hồ sơ bé đang học.
- **Màn hình danh sách Chủ đề & Bài học:** Hiển thị các chủ đề học tập (Transport, Colors, Animals, Shapes...) một cách trực quan, hấp dẫn.
- **Màn hình chi tiết Bài học (Lesson Detail Screen):**
  - Hiển thị đoạn văn bản bài học kèm tính năng "Phát âm" đọc trôi chảy toàn bộ đoạn văn.
  - Tích hợp tính năng "Dịch" thông minh, hỗ trợ chuyển đổi song ngữ Anh - Việt.
- **Màn hình Trắc nghiệm Từ vựng (Vocabulary Quiz Screen):**
  - Làm trắc nghiệm chọn đáp án đúng với giao diện kết hợp hình ảnh minh họa và âm thanh phát âm.
  - Thuật toán vòng lặp học tập thông minh: Buộc trẻ phải làm lại các câu chọn sai cho đến khi chọn đúng 100% mới cho phép hoàn thành bài học.
- **Hệ thống Khen thưởng (Achievements):** Tự động trao tặng các Huy Hiệu Đạo Quán (Pokemon Gym Badges) ngay khi trẻ đạt được các mốc số lượng bài học hoàn thành.

**Không gian dành cho Admin/Phụ huynh (Admin/Parent Interface):**
- **Màn hình Admin Dashboard:** Cung cấp cái nhìn tổng quan về hệ thống.
- **Quản lý Chủ đề (Topic Management):** Màn hình thêm mới, chỉnh sửa, xóa và hiển thị danh sách các chủ đề.
- **Quản lý Bài học (Lesson Management):** Màn hình thêm mới, chỉnh sửa và quản lý nội dung văn bản của từng bài học.

### 7. Các tính năng và màn hình chưa hoàn thành (Dự kiến cho Phase tiếp theo)
- **Hệ thống báo cáo chi tiết:** Màn hình vẽ biểu đồ học tập thống kê theo tuần/tháng dành cho phụ huynh theo dõi hiệu suất của con.
- **Quản lý Profile & Settings:** Màn hình cấu hình tài khoản, đổi mật khẩu và quản lý gói học (thanh toán) cho phụ huynh.
- **Mở rộng định dạng bài tập:** Bổ sung thêm các loại mini-game tương tác mới (như Nối chữ, Kéo thả hình ảnh vào ô trống, Nghe âm thanh đoán chữ) để đa dạng hóa cách kiểm tra từ vựng.
- **Chế độ Offline (Offline mode):** Tối ưu hóa việc lưu trữ tạm (Caching) hình ảnh và âm thanh để trẻ có thể tiếp tục xem lại bài học khi thiết bị không có kết nối mạng.

### 8. Các bước tiếp theo (Next actions)
[Tôi đã có - Bạn hãy chèn các kế hoạch tiếp theo của nhóm vào đây]
