class ApiEndpoints {
  ApiEndpoints._();

  // ===================== AUTH =====================
  static const String _auth = '/auth';

  static const String login = '$_auth/login';
  static const String register = '$_auth/register';
  static const String refreshToken = '$_auth/refresh-token';
  static const String profile = '$_auth/profile';

  // ===================== USERS =====================
  static const String _users = '/users';

  static const String users = _users;
  static String userById(String id) => '$_users/$id';
  static const String checkEmail = '$_users/is-available';

  // ===================== PRODUCTS =====================
  static const String _products = '/products';

  static const String products = _products;
  static String relatedProduct(String slug) => '$_products/slug/$slug/related';
  static String productBySlug(String slug) => '$_products/slug/$slug';

  static const String addProduct = _products;

  // ===================== CATEGORIES =====================
  static const String _categories = '/categories';

  static const String categories = _categories;
  static String categoryById(String id) => '$_categories/$id';
  static String productsByCategoryId(String id) => '$_categories/$id/products';
}
