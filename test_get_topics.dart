import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  try {
    final response = await dio.get('http://127.0.0.1:5109/api/Topics');
    print(response.data);
  } catch (e) {
    if (e is DioException) {
      print('Dio error: ${e.response?.statusCode} - ${e.response?.data}');
    } else {
      print('Error: $e');
    }
  }
}
