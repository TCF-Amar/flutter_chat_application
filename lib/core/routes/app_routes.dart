class RouteModels {
  final String name;
  final String path;

  RouteModels({required this.name, required this.path});
}

class AppRoutes {
  static final AppRoutes instance = AppRoutes._();
  AppRoutes._();

  static final RouteModels splash = RouteModels(name: 'splash', path: '/');
  static final RouteModels signin = RouteModels(
    name: 'signin',
    path: '/signin',
  );
  static final RouteModels signup = RouteModels(
    name: 'signup',
    path: '/signup',
  );
  static final RouteModels home = RouteModels(name: 'home', path: '/home');
  static final RouteModels addContact = RouteModels(
    name: 'addContact',
    path: '/addContact',
  );
  static final RouteModels profileComplete = RouteModels(
    name: 'profileComplete',
    path: '/profileComplete',
  );
  static final RouteModels chat = RouteModels(name: 'chat', path: '/chat');
  static final RouteModels mediaPreview = RouteModels(
    name: 'mediaPreview',
    path: '/mediaPreview',
  );
  static final RouteModels networkMediaView = RouteModels(
    name: 'networkMediaView',
    path: '/networkMediaView',
  );
  static final RouteModels profile = RouteModels(
    name: 'profile',
    path: '/profile',
  );
}
