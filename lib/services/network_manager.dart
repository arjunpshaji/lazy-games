import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'network_helper.dart';

enum NetworkRole { none, host, client }

class NetworkManager extends ChangeNotifier {
  NetworkRole _role = NetworkRole.none;
  String? _localIp;
  bool _isConnected = false;
  bool _isSearching = false;
  
  dynamic _server; // Holds the HttpServer on mobile
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  String? _hostIp;
  int? _hostPort;
  
  // Callback for when a message is received
  void Function(Map<String, dynamic>)? onMessageReceived;
  void Function()? onConnected;
  void Function()? onDisconnected;

  final List<void Function(Map<String, dynamic>)> _messageListeners = [];

  void addMessageListener(void Function(Map<String, dynamic>) listener) {
    _messageListeners.add(listener);
  }

  void removeMessageListener(void Function(Map<String, dynamic>) listener) {
    _messageListeners.remove(listener);
  }

  NetworkRole get role => _role;
  String? get localIp => _localIp;
  bool get isConnected => _isConnected;
  bool get isSearching => _isSearching;

  NetworkManager() {
    _fetchLocalIp();
  }

  Future<void> _fetchLocalIp() async {
    final ip = await NetworkHelper.instance.getLocalIp();
    if (ip != null) {
      _localIp = ip;
      notifyListeners();
    }
  }

  // HOST: Start WebSocket Server (Mobile Only)
  Future<void> hostGame(int port) async {
    if (kIsWeb) {
      debugPrint("Web cannot host a server due to browser security constraints.");
      return;
    }
    
    await stop();
    _role = NetworkRole.host;
    _isSearching = true;
    notifyListeners();

    try {
      _server = await NetworkHelper.instance.startServer(port, (socket) {
        if (_channel != null) {
          // Only allow one connection for 2-player game
          // socket is standard WebSocket in VM, we can close it
          try {
            socket.close();
          } catch (_) {}
          return;
        }

        final wrapped = NetworkHelper.instance.wrapSocket(socket);
        if (wrapped != null) {
          _channel = wrapped;
          _isSearching = false;
          _isConnected = true;
          _reconnectAttempts = 0;
          notifyListeners();
          onConnected?.call();
          _startPingTimer();
          _listenToChannel();
        }
      });
      debugPrint("WebSocket Server running on port $port");
    } catch (e) {
      debugPrint("Error starting server: $e");
      stop();
    }
  }

  // CLIENT: Connect to Host (Web & Mobile)
  Future<void> joinGame(String ipAddress, int port) async {
    await stop();
    _role = NetworkRole.client;
    _isSearching = true;
    _hostIp = ipAddress;
    _hostPort = port;
    notifyListeners();

    try {
      final wsUrl = Uri.parse('ws://$ipAddress:$port/ws');
      final channel = WebSocketChannel.connect(wsUrl);
      
      // Wait for WebSocket handshake to succeed
      await channel.ready;
      
      _channel = channel;
      _isConnected = true;
      _isSearching = false;
      _reconnectAttempts = 0;
      notifyListeners();
      onConnected?.call();
      _startPingTimer();
      _listenToChannel();
    } catch (e) {
      debugPrint("Error connecting to host: $e");
      stop();
      rethrow;
    }
  }

  void _listenToChannel() {
    _channel?.stream.listen(
      (message) {
        try {
          final decoded = jsonDecode(message) as Map<String, dynamic>;
          // Silently swallow keepalive pings — they are not game packets.
          if (decoded['type'] == 'ping') return;
          onMessageReceived?.call(decoded);
          for (final listener in List.of(_messageListeners)) {
            try {
              listener(decoded);
            } catch (e) {
              debugPrint("Error in network message listener: $e");
            }
          }
        } catch (e) {
          debugPrint("Error parsing incoming message: $e");
        }
      },
      onError: (error) {
        debugPrint("WebSocket stream error: $error");
        stop();
      },
      onDone: () {
        debugPrint("WebSocket stream closed");
        _stopPingTimer();
        // For clients, attempt automatic reconnection before giving up.
        if (_role == NetworkRole.client &&
            _hostIp != null &&
            _hostPort != null &&
            _reconnectAttempts < _maxReconnectAttempts) {
          _reconnectAttempts++;
          debugPrint('WebSocket reconnecting (attempt $_reconnectAttempts/$_maxReconnectAttempts)...');
          Future.delayed(const Duration(seconds: 2), () async {
            if (_role != NetworkRole.client) return; // already stopped
            try {
              final wsUrl = Uri.parse('ws://$_hostIp:$_hostPort/ws');
              final channel = WebSocketChannel.connect(wsUrl);
              await channel.ready;
              _channel = channel;
              _isConnected = true;
              notifyListeners();
              _startPingTimer();
              _listenToChannel();
            } catch (e) {
              debugPrint('Reconnect attempt $_reconnectAttempts failed: $e');
              // Recurse via onDone when the failed channel closes, or stop.
              if (_reconnectAttempts >= _maxReconnectAttempts) stop();
            }
          });
        } else {
          stop();
        }
      },
    );
  }

  // Send a 20-second keepalive ping to prevent router/firewall idle-timeout drops.
  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_channel != null && _isConnected) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
        } catch (e) {
          debugPrint('Ping failed: $e');
        }
      }
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  // Send a packet to the other device
  void sendMessage(String type, Map<String, dynamic> data) {
    if (_channel == null || !_isConnected) return;
    
    final packet = {
      'type': type,
      'sender': _role.name,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    try {
      _channel!.sink.add(jsonEncode(packet));
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  // Terminate connection
  Future<void> stop() async {
    _isConnected = false;
    _isSearching = false;
    _stopPingTimer();
    
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;

    if (_server != null) {
      try {
        await NetworkHelper.instance.stopServer(_server);
      } catch (_) {}
      _server = null;
    }

    final oldRole = _role;
    _role = NetworkRole.none;
    
    if (oldRole != NetworkRole.none) {
      onDisconnected?.call();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
