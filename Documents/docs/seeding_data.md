# Hướng dẫn Seeding Data (Không can thiệp file BE)

Do việc sửa file `DataSeeder.cs` bên Backend dễ bị ghi đè khi pull code từ thành viên khác (như đã xảy ra), chúng ta sẽ sử dụng phương pháp **Manual Seeding qua SQL** hoặc **Import qua API** thay vì dùng code C#.

Dưới đây là các phương pháp thay thế:

## 1. Phương án A: Dùng Script SQL (Khuyến nghị)
Bạn có thể copy đoạn script này và chạy trực tiếp trong SQL Server Management Studio (SSMS) hoặc Azure Data Studio để tạo dữ liệu mẫu một cách nhanh chóng nhất.

```sql
-- Thêm Topics (Chủ đề)
INSERT INTO Topics (Id, Name, Description, OrderIndex, IsActive) VALUES
(NEWID(), 'Animals', 'Learn about animals', 1, 1),
(NEWID(), 'Food & Drinks', 'Learn about food', 2, 1),
(NEWID(), 'Family', 'Learn about family members', 3, 0),
(NEWID(), 'School', 'Learn about school items', 4, 1);

-- Lưu lại Id của Topic vừa tạo để thêm Lesson
DECLARE @animalTopicId UNIQUEIDENTIFIER = (SELECT TOP 1 Id FROM Topics WHERE Name = 'Animals');

-- Thêm Lessons (Bài học)
INSERT INTO Lessons (Id, TopicId, Title, LessonType, OrderIndex, IsPublished) VALUES
(NEWID(), @animalTopicId, 'Farm Animals', 'Vocabulary', 1, 1),
(NEWID(), @animalTopicId, 'Wild Animals', 'Vocabulary', 2, 1),
(NEWID(), @animalTopicId, 'Animal Sounds', 'Audio', 3, 0);

-- Lưu lại Id của Lesson vừa tạo để thêm Vocabulary
DECLARE @farmLessonId UNIQUEIDENTIFIER = (SELECT TOP 1 Id FROM Lessons WHERE Title = 'Farm Animals');

-- Thêm Vocabularies (Từ vựng)
INSERT INTO Vocabularies (Id, LessonId, Word, Meaning, PhoneticText, OrderIndex) VALUES
(NEWID(), @farmLessonId, 'Dog', 'Con chó', 'dɒɡ', 1),
(NEWID(), @farmLessonId, 'Cat', 'Con mèo', 'kæt', 2),
(NEWID(), @farmLessonId, 'Cow', 'Con bò', 'kaʊ', 3);
```

## 2. Phương án B: Dùng Postman Script / API
Nếu không muốn can thiệp Database, hãy tạo một Collection Postman và gọi lần lượt các API tạo mới (sử dụng tính năng Automation của Postman).

**API Create Topic:**
- POST `/api/topics`
- Body:
```json
{
  "name": "Animals",
  "description": "Learn about animals",
  "orderIndex": 1
}
```

**API Create Lesson:**
- POST `/api/lessons`
- Body:
```json
{
  "title": "Farm Animals",
  "topicId": "<Lấy từ API trên>",
  "lessonType": "Vocabulary",
  "orderIndex": 1
}
```

**Lợi ích:**
- Backend của bạn bè bạn không bị thay đổi.
- Khi cần reset, bạn chỉ cần chạy lại SQL Script hoặc Collection Postman.
- File doc này được lưu ở FE nên không bao giờ bị mất do Backend pull code.
