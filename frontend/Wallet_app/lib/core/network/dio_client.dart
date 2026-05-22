class DioResponse<T> {
  const DioResponse({
    required this.data,
  });

  final T data;
}

class DioClient {
  DioClient([this._client, this._logger]);

  final Object? _client;
  final Object? _logger;

  Future<DioResponse<Map<String, dynamic>>> get(
      String path, {
        Map<String, dynamic>? queryParameters,
        Map<String, dynamic>? headers,
      }) async {
    throw UnimplementedError(
      'DioClient.get is not used right now in the local/mock flow.',
    );
  }

  Future<DioResponse<Map<String, dynamic>>> post(
      String path, {
        Object? data,
        Map<String, dynamic>? queryParameters,
        Map<String, dynamic>? headers,
      }) async {
    throw UnimplementedError(
      'DioClient.post is not used right now in the local/mock flow.',
    );
  }

  Future<DioResponse<Map<String, dynamic>>> put(
      String path, {
        Object? data,
        Map<String, dynamic>? queryParameters,
        Map<String, dynamic>? headers,
      }) async {
    throw UnimplementedError(
      'DioClient.put is not used right now in the local/mock flow.',
    );
  }

  Future<DioResponse<Map<String, dynamic>>> delete(
      String path, {
        Object? data,
        Map<String, dynamic>? queryParameters,
        Map<String, dynamic>? headers,
      }) async {
    throw UnimplementedError(
      'DioClient.delete is not used right now in the local/mock flow.',
    );
  }
}