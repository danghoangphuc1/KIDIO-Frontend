import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  try {
    final response = await dio.get('http://127.0.0.1:5109/api/Progress/child/28238952-3e39-44c5-942d-00e0050588e4/summary');
    print(response.data);
  } catch (e) {
    if (e is DioException) {
      print('Dio error: ${e.response?.statusCode} - ${e.response?.data}');
    } else {
      print('Error: $e');
    }
  }
}
