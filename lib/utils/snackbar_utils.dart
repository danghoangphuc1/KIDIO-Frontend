import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';

class CustomSnackBar {
  static void show(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        elevation: 6,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showError(BuildContext context, dynamic e, {String prefix = 'Có lỗi xảy ra: '}) {
    String msg = _parseErrorMessage(e);
    show(context, '$prefix$msg', isError: true);
  }

  static String _parseErrorMessage(dynamic e) {
    String msg = e.toString();
    if (e is DioException) {
      if (e.error is ApiException) {
        msg = (e.error as ApiException).message;
      } else {
        msg = e.message ?? 'Lỗi kết nối máy chủ';
      }
    } else if (e is ApiException) {
      msg = e.message;
    }
    
    // Dịch các thông báo lỗi phổ biến từ backend
    final lowerMsg = msg.toLowerCase();
    
    // Topic
    if (lowerMsg.contains('a topic with this name already exists')) {
      return 'Tên chủ đề này đã tồn tại, vui lòng chọn tên khác!';
    }
    if (lowerMsg.contains('a topic with this orderindex already exists')) {
      return 'Thứ tự hiển thị (Order Index) này đã được sử dụng cho chủ đề khác!';
    }
    
    // Lesson
    if (lowerMsg.contains('a lesson with this name already exists')) {
      return 'Tên bài học này đã tồn tại, vui lòng chọn tên khác!';
    }
    if (lowerMsg.contains('a lesson with this orderindex already exists')) {
      return 'Thứ tự hiển thị (Order Index) này đã được sử dụng cho bài học khác!';
    }
    
    // Vocabulary
    if (lowerMsg.contains('a vocabulary with this name already exists') || lowerMsg.contains('a vocabulary with this englishword already exists')) {
      return 'Tên từ vựng này đã tồn tại, vui lòng chọn tên khác!';
    }
    if (lowerMsg.contains('a vocabulary with this orderindex already exists')) {
      return 'Thứ tự hiển thị (Order Index) này đã được sử dụng cho từ vựng khác!';
    }

    return msg;
  }
}
