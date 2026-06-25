import 'dart:async';
import 'dart:io';
import 'package:web_socket_channel/io.dart';
import 'network_helper.dart';

NetworkHelper getNetworkHelper() => NetworkHelperIo();

class NetworkHelperIo implements NetworkHelper {
  @override
  Future<String?> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.address.startsWith('192.168.') || addr.address.startsWith('10.')) {
            return addr.address;
          }
        }
      }
      if (interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty) {
        return interfaces.first.addresses.first.address;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<dynamic> startServer(int port, void Function(dynamic socket) onConnectionUpgrade) async {
    final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    server.listen((HttpRequest request) async {
      if (request.uri.path == '/ws') {
        try {
          final socket = await WebSocketTransformer.upgrade(request);
          onConnectionUpgrade(socket);
        } catch (_) {}
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
      }
    });
    return server;
  }

  @override
  Future<void> stopServer(dynamic server) async {
    if (server is HttpServer) {
      await server.close(force: true);
    }
  }

  @override
  dynamic wrapSocket(dynamic socket) {
    if (socket is WebSocket) {
      return IOWebSocketChannel(socket);
    }
    return null;
  }
}
