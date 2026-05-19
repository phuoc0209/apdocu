import '../models/seller_review_model.dart';
import 'api_service.dart';

class SellerReviewService {
  final ApiService _apiService = ApiService();

  Future<void> addReview(SellerReview review) async {
    // TODO: Implement API endpoint
    // await _apiService.post('reviews/create.php', review.toMap());
  }

  Future<List<SellerReview>> getReviewsForSeller(String sellerId) async {
    // TODO: Implement API endpoint
    // final response = await _apiService.get('reviews/list.php?sellerId=$sellerId');
    // return (response as List).map((e) => SellerReview.fromMap(e)).toList();
    return [];
  }

  Future<Map<String, dynamic>> getSellerRatingSummary(String sellerId) async {
    // TODO: Implement API endpoint
    // final response = await _apiService.get('reviews/summary.php?sellerId=$sellerId');
    // return response;
    return {
      'average': 0.0,
      'count': 0,
    };
  }
}
