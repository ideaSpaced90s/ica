import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:nearby_connections/nearby_connections.dart';

enum ConnectionMode { wifi, nearby }

class DiscoveredSession {
  final String id; // IP for wifi, endpointId for nearby
  final String name;
  final ConnectionMode mode;

  const DiscoveredSession({
    required this.id,
    required this.name,
    required this.mode,
  });
}

class StudentSessionState {
  final String uid;
  final String displayName;
  final bool online;
  final String boardFen;
  final bool raisedHand;
  final String? nearbyEndpointId; // null if connected via WiFi

  const StudentSessionState({
    required this.uid,
    required this.displayName,
    this.online = true,
    required this.boardFen,
    this.raisedHand = false,
    this.nearbyEndpointId,
  });

  StudentSessionState copyWith({
    String? uid,
    String? displayName,
    bool? online,
    String? boardFen,
    bool? raisedHand,
    String? nearbyEndpointId,
  }) {
    return StudentSessionState(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      online: online ?? this.online,
      boardFen: boardFen ?? this.boardFen,
      raisedHand: raisedHand ?? this.raisedHand,
      nearbyEndpointId: nearbyEndpointId ?? this.nearbyEndpointId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'display_name': displayName,
      'online': online,
      'board_fen': boardFen,
      'raised_hand': raisedHand,
    };
  }

  factory StudentSessionState.fromMap(Map<String, dynamic> map) {
    return StudentSessionState(
      uid: map['uid'] as String? ?? '',
      displayName: map['display_name'] as String? ?? 'Student',
      online: map['online'] as bool? ?? false,
      boardFen: map['board_fen'] as String? ?? 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      raisedHand: map['raised_hand'] as bool? ?? false,
    );
  }
}

class ClassroomState {
  final String classroomId;
  final bool isTeacher;
  final bool isJoined;
  final bool boardsLocked;
  final bool syncToTeacher;
  final String teacherBoardFen;
  final Map<String, StudentSessionState> students;
  final String? meetLink;

  // Local Networking additions
  final ConnectionMode connectionMode;
  final List<DiscoveredSession> discoveredSessions;
  final String? localIp;
  final bool isDiscovering;
  final bool isAdvertising;

  const ClassroomState({
    this.classroomId = '',
    this.isTeacher = false,
    this.isJoined = false,
    this.boardsLocked = false,
    this.syncToTeacher = false,
    this.teacherBoardFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
    this.students = const {},
    this.meetLink,
    this.connectionMode = ConnectionMode.wifi,
    this.discoveredSessions = const [],
    this.localIp,
    this.isDiscovering = false,
    this.isAdvertising = false,
  });

  ClassroomState copyWith({
    String? classroomId,
    bool? isTeacher,
    bool? isJoined,
    bool? boardsLocked,
    bool? syncToTeacher,
    String? teacherBoardFen,
    Map<String, StudentSessionState>? students,
    String? meetLink,
    ConnectionMode? connectionMode,
    List<DiscoveredSession>? discoveredSessions,
    String? localIp,
    bool? isDiscovering,
    bool? isAdvertising,
  }) {
    return ClassroomState(
      classroomId: classroomId ?? this.classroomId,
      isTeacher: isTeacher ?? this.isTeacher,
      isJoined: isJoined ?? this.isJoined,
      boardsLocked: boardsLocked ?? this.boardsLocked,
      syncToTeacher: syncToTeacher ?? this.syncToTeacher,
      teacherBoardFen: teacherBoardFen ?? this.teacherBoardFen,
      students: students ?? this.students,
      meetLink: meetLink ?? this.meetLink,
      connectionMode: connectionMode ?? this.connectionMode,
      discoveredSessions: discoveredSessions ?? this.discoveredSessions,
      localIp: localIp ?? this.localIp,
      isDiscovering: isDiscovering ?? this.isDiscovering,
      isAdvertising: isAdvertising ?? this.isAdvertising,
    );
  }
}

class ClassroomNotifier extends StateNotifier<ClassroomState> {
  ClassroomNotifier() : super(const ClassroomState()) {
    _initLocalIp();
  }

  static const int wifiPort = 4040;
  static const int udpPort = 4041;
  static const String serviceId = "kingslayer_classroom";

  // WiFi TCP/UDP Sockets
  ServerSocket? _tcpServer;
  Socket? _tcpClientSocket;
  RawDatagramSocket? _udpDiscoverySocket;
  Timer? _udpBroadcastTimer;
  final List<Socket> _connectedStudentSockets = [];

  String? _currentUserUid;
  String? _currentDisplayName;

  Future<void> _initLocalIp() async {
    try {
      final ip = await getLocalIpAddress();
      state = state.copyWith(localIp: ip);
    } catch (e) {
      debugPrint("Error fetching local IP: $e");
    }
  }

  void initializeUser({required String uid, required String displayName}) {
    _currentUserUid = uid;
    _currentDisplayName = displayName;
  }

  void setConnectionMode(ConnectionMode mode) {
    if (state.isJoined || state.isAdvertising || state.isDiscovering) {
      debugPrint("Cannot change connection mode while active.");
      return;
    }
    state = state.copyWith(connectionMode: mode);
  }

  // --- TEACHER ACTIONS (HOSTING) ---

  Future<void> createClassroom(String classroomId) async {
    state = state.copyWith(
      classroomId: classroomId,
      isTeacher: true,
      isJoined: true,
      isAdvertising: true,
    );

    if (state.connectionMode == ConnectionMode.wifi) {
      await _startWifiServer(classroomId);
    } else {
      await _startNearbyAdvertising(classroomId);
    }
  }

  Future<void> _startWifiServer(String classroomId) async {
    try {
      _tcpServer = await ServerSocket.bind(InternetAddress.anyIPv4, wifiPort);
      _tcpServer!.listen((Socket client) {
        _handleIncomingWifiConnection(client);
      });

      // Periodic UDP Broadcast to advertise this classroom session
      _udpDiscoverySocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _udpDiscoverySocket!.broadcastEnabled = true;

      _udpBroadcastTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        final payload = "ICA_CLASSROOM:$classroomId:${state.localIp}";
        final bytes = utf8.encode(payload);
        try {
          _udpDiscoverySocket!.send(bytes, InternetAddress('255.255.255.255'), udpPort);
        } catch (e) {
          debugPrint("UDP broadcast error: $e");
        }
      });
      debugPrint("WiFi Classroom Server started on port $wifiPort");
    } catch (e) {
      debugPrint("WiFi Server Start Error: $e");
      leaveClassroom();
    }
  }

  Future<void> _startNearbyAdvertising(String classroomId) async {
    try {
      final name = _currentDisplayName ?? 'Teacher';
      await Nearby().startAdvertising(
        name,
        Strategy.P2P_STAR,
        onConnectionInitiated: (endpointId, info) {
          debugPrint("Nearby connection initiated: $endpointId - ${info.endpointName}");
          Nearby().acceptConnection(endpointId, onPayLoadRecieved: (endpointId, payload) {
            if (payload.type == PayloadType.BYTES && payload.bytes != null) {
              final text = utf8.decode(payload.bytes!);
              _handleIncomingMessage(endpointId, text);
            }
          });
        },
        onConnectionResult: (endpointId, status) {
          if (status == Status.CONNECTED) {
            debugPrint("Nearby connected: $endpointId");
          } else {
            debugPrint("Nearby connection failed: $endpointId Status: $status");
            _removeNearbyStudent(endpointId);
          }
        },
        onDisconnected: (endpointId) {
          debugPrint("Nearby disconnected: $endpointId");
          _removeNearbyStudent(endpointId);
        },
        serviceId: serviceId,
      );
    } catch (e) {
      debugPrint("Nearby advertising error: $e");
      leaveClassroom();
    }
  }

  // --- STUDENT ACTIONS (DISCOVERING & JOINING) ---

  void startDiscovery() {
    if (state.isDiscovering) return;
    state = state.copyWith(isDiscovering: true, discoveredSessions: []);

    if (state.connectionMode == ConnectionMode.wifi) {
      _startWifiDiscovery();
    } else {
      _startNearbyDiscovery();
    }
  }

  void stopDiscovery() {
    if (!state.isDiscovering) return;
    state = state.copyWith(isDiscovering: false);

    _udpDiscoverySocket?.close();
    _udpDiscoverySocket = null;
    Nearby().stopDiscovery();
  }

  Future<void> _startWifiDiscovery() async {
    try {
      _udpDiscoverySocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, udpPort);
      _udpDiscoverySocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpDiscoverySocket!.receive();
          if (datagram != null) {
            final payload = utf8.decode(datagram.data);
            if (payload.startsWith("ICA_CLASSROOM:")) {
              final parts = payload.split(":");
              if (parts.length >= 3) {
                final classroomId = parts[1];
                final ip = parts[2];
                _addDiscoveredSession(DiscoveredSession(
                  id: ip,
                  name: classroomId,
                  mode: ConnectionMode.wifi,
                ));
              }
            }
          }
        }
      });
    } catch (e) {
      debugPrint("WiFi Discovery error: $e");
    }
  }

  Future<void> _startNearbyDiscovery() async {
    try {
      await Nearby().startDiscovery(
        _currentDisplayName ?? 'Student',
        Strategy.P2P_STAR,
        onEndpointFound: (endpointId, name, serviceId) {
          _addDiscoveredSession(DiscoveredSession(
            id: endpointId,
            name: name,
            mode: ConnectionMode.nearby,
          ));
        },
        onEndpointLost: (endpointId) {
          if (endpointId != null) {
            _removeDiscoveredSession(endpointId);
          }
        },
        serviceId: serviceId,
      );
    } catch (e) {
      debugPrint("Nearby Discovery error: $e");
    }
  }

  void _addDiscoveredSession(DiscoveredSession session) {
    final list = List<DiscoveredSession>.from(state.discoveredSessions);
    if (!list.any((element) => element.id == session.id)) {
      list.add(session);
      state = state.copyWith(discoveredSessions: list);
    }
  }

  void _removeDiscoveredSession(String id) {
    final list = List<DiscoveredSession>.from(state.discoveredSessions)
      ..removeWhere((element) => element.id == id);
    state = state.copyWith(discoveredSessions: list);
  }

  Future<void> joinClassroom(String targetId) async {
    stopDiscovery();
    state = state.copyWith(
      classroomId: state.connectionMode == ConnectionMode.wifi ? "WiFi Session" : "Nearby Session",
      isTeacher: false,
      isJoined: true,
    );

    if (state.connectionMode == ConnectionMode.wifi) {
      await _connectToWifiServer(targetId);
    } else {
      await _connectToNearbyServer(targetId);
    }
  }

  Future<void> _connectToWifiServer(String ip) async {
    try {
      _tcpClientSocket = await Socket.connect(ip, wifiPort);
      _tcpClientSocket!.listen((data) {
        final text = utf8.decode(data);
        _handleIncomingMessage("wifi_server", text);
      }, onDone: () {
        debugPrint("Disconnected from WiFi classroom.");
        leaveClassroom();
      });

      // Send initial registration packet
      _sendStudentUpdate();
    } catch (e) {
      debugPrint("WiFi Join Error: $e");
      leaveClassroom();
    }
  }

  Future<void> _connectToNearbyServer(String endpointId) async {
    try {
      final name = _currentDisplayName ?? 'Student';
      await Nearby().requestConnection(
        name,
        endpointId,
        onConnectionInitiated: (endpointId, info) {
          Nearby().acceptConnection(endpointId, onPayLoadRecieved: (endpointId, payload) {
            if (payload.type == PayloadType.BYTES && payload.bytes != null) {
              final text = utf8.decode(payload.bytes!);
              _handleIncomingMessage(endpointId, text);
            }
          });
        },
        onConnectionResult: (endpointId, status) {
          if (status == Status.CONNECTED) {
            debugPrint("Nearby connection to host successful!");
            _sendStudentUpdate(nearbyEndpointId: endpointId);
          } else {
            debugPrint("Nearby connection to host failed. Status: $status");
            leaveClassroom();
          }
        },
        onDisconnected: (endpointId) {
          debugPrint("Nearby disconnected from host.");
          leaveClassroom();
        },
      );
    } catch (e) {
      debugPrint("Nearby Join Error: $e");
      leaveClassroom();
    }
  }

  // --- INCOMING DATA HANDLING ---

  void _handleIncomingWifiConnection(Socket client) {
    _connectedStudentSockets.add(client);
    StringBuffer buffer = StringBuffer();

    client.listen((data) {
      final text = utf8.decode(data);
      // Sockets can aggregate data, split by newline delimiter if multiple packets merge
      buffer.write(text);
      String fullContent = buffer.toString();
      while (fullContent.contains("\n")) {
        final index = fullContent.indexOf("\n");
        final packet = fullContent.substring(0, index).trim();
        fullContent = fullContent.substring(index + 1);
        buffer.clear();
        buffer.write(fullContent);

        if (packet.isNotEmpty) {
          _handleIncomingMessage(client.remoteAddress.address, packet, socket: client);
        }
      }
    }, onDone: () {
      _connectedStudentSockets.remove(client);
      _removeWifiStudentBySocket(client);
    }, onError: (e) {
      _connectedStudentSockets.remove(client);
      _removeWifiStudentBySocket(client);
    });
  }

  void _handleIncomingMessage(String senderKey, String message, {Socket? socket}) {
    try {
      final data = json.decode(message) as Map<String, dynamic>;
      final type = data['type'] as String?;

      if (type == 'student_update') {
        final payload = data['payload'] as Map<String, dynamic>;
        final student = StudentSessionState.fromMap(payload);
        final updatedStudents = Map<String, StudentSessionState>.from(state.students);

        // Store socket/endpoint reference in teacher's list
        StudentSessionState currentStudent = student;
        if (state.connectionMode == ConnectionMode.wifi && socket != null) {
          // WiFi: Identify student by IP (senderKey) and store socket
          currentStudent = student.copyWith(uid: senderKey);
        } else {
          // Nearby: Identify student by UID, store endpoint ID
          currentStudent = student.copyWith(nearbyEndpointId: senderKey);
        }

        updatedStudents[currentStudent.uid] = currentStudent;
        state = state.copyWith(students: updatedStudents);

        // Teacher sends updated classroom state to all clients
        _broadcastClassroomState();
      } 
      else if (type == 'classroom_sync') {
        final payload = data['payload'] as Map<String, dynamic>;
        state = state.copyWith(
          boardsLocked: payload['boards_locked'] as bool? ?? false,
          syncToTeacher: payload['sync_to_teacher'] as bool? ?? false,
          teacherBoardFen: payload['teacher_board_fen'] as String? ?? state.teacherBoardFen,
          meetLink: payload['meet_link'] as String?,
        );
      } 
      else if (type == 'takeover_move') {
        final fen = data['fen'] as String;
        // Broadcast local listener will capture this change via studyLabProvider
        state = state.copyWith(teacherBoardFen: fen);
      }
      else if (type == 'pair_game') {
        final opponentUid = data['opponent_uid'] as String;
        final opponentName = data['opponent_name'] as String;
        final color = data['color'] as String;
        // Handled by Sparring Logic or routed to listeners
        debugPrint("Student Paired: Opponent=$opponentName Uid=$opponentUid Color=$color");
      }
      else if (type == 'sparring_move') {
        final moveData = data['move_data'] as Map<String, dynamic>;
        // If broker, route to target student, else execute
        if (state.isTeacher) {
          final toUid = data['to_uid'] as String;
          _routeSparringMoveToStudent(toUid, moveData);
        } else {
          // Student receives move from opponent
          debugPrint("Sparring Move Received: $moveData");
        }
      }
    } catch (e) {
      debugPrint("Message parsing error: $e. Content: $message");
    }
  }

  // --- CORE SYNC DISPATCH METHODS ---

  Future<void> updateTeacherBoardFen(String fen) async {
    if (!state.isTeacher) return;
    state = state.copyWith(teacherBoardFen: fen);
    _broadcastClassroomState();
  }

  Future<void> setBoardsLocked(bool locked) async {
    if (!state.isTeacher) return;
    state = state.copyWith(boardsLocked: locked);
    _broadcastClassroomState();
  }

  Future<void> setSyncToTeacher(bool sync) async {
    if (!state.isTeacher) return;
    state = state.copyWith(syncToTeacher: sync);
    _broadcastClassroomState();
  }

  Future<void> updateMeetLink(String? link) async {
    if (!state.isTeacher) return;
    state = state.copyWith(meetLink: link);
    _broadcastClassroomState();
  }

  // Teacher modifies a student's board FEN (Takeover Mode)
  Future<void> updateStudentBoardFenByTeacher(String studentUid, String fen) async {
    if (!state.isTeacher) return;
    final message = json.encode({
      'type': 'takeover_move',
      'fen': fen,
    });
    _sendDirectMessageToStudent(studentUid, message);
  }

  // Student makes move locally and reports to Teacher
  Future<void> updateStudentBoardFen(String fen) async {
    if (state.isTeacher) return;
    final student = state.students[_currentUserUid];
    if (student != null) {
      final updated = student.copyWith(boardFen: fen);
      state = state.copyWith(
        students: {
          ...state.students,
          _currentUserUid!: updated,
        },
      );
      _sendStudentUpdate(fen: fen);
    }
  }

  Future<void> toggleRaiseHand(bool raised) async {
    if (state.isTeacher) return;
    final student = state.students[_currentUserUid];
    if (student != null) {
      final updated = student.copyWith(raisedHand: raised);
      state = state.copyWith(
        students: {
          ...state.students,
          _currentUserUid!: updated,
        },
      );
      _sendStudentUpdate(raisedHand: raised);
    }
  }

  // --- SPARRING BROKER METHODS ---

  Future<void> pairStudentsForSparring(String studentAUid, String studentBUid) async {
    if (!state.isTeacher) return;
    
    final studentA = state.students[studentAUid];
    final studentB = state.students[studentBUid];
    if (studentA == null || studentB == null) return;

    final msgToA = json.encode({
      'type': 'pair_game',
      'opponent_uid': studentBUid,
      'opponent_name': studentB.displayName,
      'color': 'white',
    });

    final msgToB = json.encode({
      'type': 'pair_game',
      'opponent_uid': studentAUid,
      'opponent_name': studentA.displayName,
      'color': 'black',
    });

    _sendDirectMessageToStudent(studentAUid, msgToA);
    _sendDirectMessageToStudent(studentBUid, msgToB);
    debugPrint("Paired student A ($studentAUid) with student B ($studentBUid)");
  }

  Future<void> sendSparringMove(String targetStudentUid, Map<String, dynamic> moveData) async {
    // If student, send to teacher broker first
    final message = json.encode({
      'type': 'sparring_move',
      'to_uid': targetStudentUid,
      'move_data': moveData,
    });
    
    if (state.isTeacher) {
      _routeSparringMoveToStudent(targetStudentUid, moveData);
    } else {
      _sendRawData(message);
    }
  }

  void _routeSparringMoveToStudent(String toUid, Map<String, dynamic> moveData) {
    final routeMessage = json.encode({
      'type': 'sparring_move',
      'move_data': moveData,
    });
    _sendDirectMessageToStudent(toUid, routeMessage);
  }

  // --- LOW-LEVEL NETWORKING DISPATCHERS ---

  void _broadcastClassroomState() {
    final payload = {
      'boards_locked': state.boardsLocked,
      'sync_to_teacher': state.syncToTeacher,
      'teacher_board_fen': state.teacherBoardFen,
      'meet_link': state.meetLink,
    };
    final message = json.encode({
      'type': 'classroom_sync',
      'payload': payload,
    });
    _broadcastRawData(message);
  }

  void _sendStudentUpdate({String? fen, bool? raisedHand, String? nearbyEndpointId}) {
    final student = StudentSessionState(
      uid: _currentUserUid ?? 'guest_uid',
      displayName: _currentDisplayName ?? 'Student',
      boardFen: fen ?? 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      raisedHand: raisedHand ?? false,
      nearbyEndpointId: nearbyEndpointId,
    );
    final message = json.encode({
      'type': 'student_update',
      'payload': student.toMap(),
    });
    _sendRawData(message);
  }

  void _sendDirectMessageToStudent(String studentUid, String message) {
    if (state.connectionMode == ConnectionMode.wifi) {
      // WiFi uses the IP address as UID
      final socket = _connectedStudentSockets.firstWhere(
        (s) => s.remoteAddress.address == studentUid,
      );
      try {
        socket.write("$message\n");
      } catch (e) {
        debugPrint("Error writing direct socket message: $e");
      }
    } else {
      // Nearby uses endpointId
      final student = state.students[studentUid];
      if (student != null && student.nearbyEndpointId != null) {
        Nearby().sendBytesPayload(
          student.nearbyEndpointId!,
          Uint8List.fromList(utf8.encode(message)),
        );
      }
    }
  }

  void _broadcastRawData(String data) {
    if (state.connectionMode == ConnectionMode.wifi) {
      for (var socket in _connectedStudentSockets) {
        try {
          socket.write("$data\n");
        } catch (e) {
          debugPrint("Broadcast socket write error: $e");
        }
      }
    } else {
      // Nearby requires individual endpoints
      for (var student in state.students.values) {
        if (student.nearbyEndpointId != null) {
          Nearby().sendBytesPayload(
            student.nearbyEndpointId!,
            Uint8List.fromList(utf8.encode(data)),
          );
        }
      }
    }
  }

  void _sendRawData(String data) {
    if (state.connectionMode == ConnectionMode.wifi) {
      if (_tcpClientSocket != null) {
        try {
          _tcpClientSocket!.write("$data\n");
        } catch (e) {
          debugPrint("Client socket write error: $e");
        }
      }
    } else {
      // Student sends bytes to teacher endpoint
      final teacherEndpoint = state.discoveredSessions.firstOrNull?.id;
      if (teacherEndpoint != null) {
        Nearby().sendBytesPayload(
          teacherEndpoint,
          Uint8List.fromList(utf8.encode(data)),
        );
      }
    }
  }

  // --- CLEANUP & TEARDOWN ---

  void _removeWifiStudentBySocket(Socket socket) {
    final ip = socket.remoteAddress.address;
    final updated = Map<String, StudentSessionState>.from(state.students)..remove(ip);
    state = state.copyWith(students: updated);
    _broadcastClassroomState();
  }

  void _removeNearbyStudent(String endpointId) {
    final key = state.students.values
        .firstWhere((element) => element.nearbyEndpointId == endpointId,
            orElse: () => const StudentSessionState(uid: '', displayName: '', boardFen: ''))
        .uid;
    if (key.isNotEmpty) {
      final updated = Map<String, StudentSessionState>.from(state.students)..remove(key);
      state = state.copyWith(students: updated);
      _broadcastClassroomState();
    }
  }

  Future<void> leaveClassroom() async {
    stopDiscovery();
    _udpBroadcastTimer?.cancel();
    _udpBroadcastTimer = null;

    _tcpClientSocket?.close();
    _tcpClientSocket = null;

    for (var socket in _connectedStudentSockets) {
      socket.close();
    }
    _connectedStudentSockets.clear();

    _tcpServer?.close();
    _tcpServer = null;

    Nearby().stopAdvertising();
    Nearby().stopAllEndpoints();

    state = state.copyWith(
      isJoined: false,
      isTeacher: false,
      isAdvertising: false,
      students: const {},
      discoveredSessions: const [],
    );
  }

  @override
  void dispose() {
    leaveClassroom();
    super.dispose();
  }
}

final localClassroomProvider =
    StateNotifierProvider<ClassroomNotifier, ClassroomState>((ref) {
  return ClassroomNotifier();
});

final activeSpectatedStudentProvider = StateProvider<String?>((ref) => null);
final takeoverModeProvider = StateProvider<bool>((ref) => false);

// Static network IP resolution helper
Future<String> getLocalIpAddress() async {
  for (var interface in await NetworkInterface.list()) {
    for (var addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
        return addr.address;
      }
    }
  }
  return '127.0.0.1';
}
