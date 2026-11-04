abstract final class Routes {
  static const home = '/home';
  static const library = '/library';
  static const discover = '/discover';
  static const stats = '/stats';
  static const search = '/search';
  static const settings = '/settings';
  static const collections = '/collections';
  static const artists = '/artists';
  static const backups = '/backups';
  static const player = '/player';
  static const onboarding = '/onboarding';
  static String album(int id) => '/album/$id';
  static String collection(int id) => '/collections/$id';
  static String artist(int id) => '/artists/$id';
  static String playlist(int id) => '/playlists/$id';
}
