import '../../../core/network/api_client.dart';
import '../../models/api_response.dart';
import '../../models/user_model.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  Future<LoginResponse> login(String username, String loginCode) async {
    final response = await _apiClient.dio.post('/auth/login', data: {
      'username': username,
      'login_code': loginCode,
    });
    return LoginResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _apiClient.dio.post('/auth/refresh', data: {
      'refresh_token': refreshToken,
    });
    return response.data;
  }

  Future<UserModel> getMe() async {
    final response = await _apiClient.dio.get('/auth/me');
    // Backend returns flat user object (not wrapped in {user: ...})
    final data = response.data;
    return UserModel.fromJson(
        data is Map<String, dynamic> && data.containsKey('user')
            ? data['user']
            : data);
  }
}
