import '../../core/network/api_client.dart';
import '../../domain/past_papers/past_paper_entity.dart';

class PastPapersRepository {
  PastPapersRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<List<PastPaperEntity>> search(PastPaperFilterSelection selection) async {
    final response = await _apiClient.dio.get('/past-papers', queryParameters: {
      if (selection.country != null) 'country': selection.country,
      if (selection.system != null) 'system': selection.system,
      if (selection.level != null) 'level': selection.level,
      if (selection.subject != null) 'subject': selection.subject,
      if (selection.year != null) 'year': selection.year,
      if (selection.query != null && selection.query!.isNotEmpty) 'q': selection.query,
    });
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => PastPaperEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PastPaperFilters> getFilters() async {
    final response = await _apiClient.dio.get('/past-papers/filters');
    return PastPaperFilters.fromJson((response.data as Map<String, dynamic>)['data']);
  }

  Future<List<PastPaperEntity>> getBookmarked() async {
    final response = await _apiClient.dio.get('/past-papers/bookmarks');
    final data = (response.data as Map<String, dynamic>)['data'] as List;
    return data.map((e) => PastPaperEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> bookmark(String pastPaperId) async {
    await _apiClient.dio.post('/past-papers/$pastPaperId/bookmark');
  }

  Future<void> unbookmark(String pastPaperId) async {
    await _apiClient.dio.delete('/past-papers/$pastPaperId/bookmark');
  }
}
