class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;
  final String currentShift;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.currentShift,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] ?? json['accessToken'] ?? '',
      refreshToken: json['refresh_token'] ?? json['refreshToken'] ?? '',
      user: json['user'] ?? {},
      currentShift: json['current_shift'] ?? json['currentShift'] ?? '',
    );
  }
}

class DashboardResponse {
  final String date;
  final int totalRecords;
  final List<Map<String, dynamic>> byStage;
  final List<Map<String, dynamic>> byShift;

  DashboardResponse({
    required this.date,
    required this.totalRecords,
    required this.byStage,
    required this.byShift,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      date: json['date'] ?? '',
      totalRecords: json['total_records'] ?? json['totalRecords'] ?? 0,
      byStage: List<Map<String, dynamic>>.from(json['by_stage'] ?? json['byStage'] ?? []),
      byShift: List<Map<String, dynamic>>.from(json['by_shift'] ?? json['byShift'] ?? []),
    );
  }
}

class PaginatedResponse<T> {
  final List<T> data;
  final int page;
  final int limit;
  final int total;
  final int pages;

  PaginatedResponse({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });
}
