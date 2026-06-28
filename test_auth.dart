import 'package:dio/dio.dart';
void main() async {
  final dio = Dio();
  try {
    final authResp = await dio.post('http://127.0.0.1:5109/api/Auth/login', data: {
      "email": "tuilabo2018@gmail.com",
      "password": "Password123!"
    });
    final token = authResp.data['data']['token'];
    final userResp = await dio.get('http://127.0.0.1:5109/api/Users/me', options: Options(headers: {'Authorization': 'Bearer $token'}));
    print('User: ${userResp.data}');
    
    // Assume childId from previous logs
    final childId = '28238952-3e39-44c5-942d-00e0050588e4';
    final sumResp = await dio.get('http://127.0.0.1:5109/api/Progress/child/$childId/summary', options: Options(headers: {'Authorization': 'Bearer $token'}));
    print('Summary: ${sumResp.data}');
  } catch (e) {
    if (e is DioException) {
      print('Dio error: ${e.response?.statusCode} - ${e.response?.data}');
    } else {
      print('Error: $e');
    }
  }
}
