import 'network_helper_stub.dart'
    if (dart.library.io) 'network_helper_io.dart'
    if (dart.library.html) 'network_helper_web.dart';

abstract class NetworkHelper {
  static NetworkHelper? _instance;
  
  static NetworkHelper get instance {
    _instance ??= getNetworkHelper();
    return _instance!;
  }

  Future<String?> getLocalIp();
  Future<dynamic> startServer(int port, void Function(dynamic socket) onConnectionUpgrade);
  Future<void> stopServer(dynamic server);
  dynamic wrapSocket(dynamic socket);
}
