import 'network_helper.dart';

NetworkHelper getNetworkHelper() => NetworkHelperWeb();

class NetworkHelperWeb implements NetworkHelper {
  @override
  Future<String?> getLocalIp() async => null;

  @override
  Future<dynamic> startServer(int port, void Function(dynamic socket) onConnectionUpgrade) async => null;

  @override
  Future<void> stopServer(dynamic server) async {}

  @override
  dynamic wrapSocket(dynamic socket) => null;
}
