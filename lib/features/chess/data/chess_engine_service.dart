import 'dart:async';

/// A unified interface for a Chess Engine Service (e.g. Stockfish or Crafty).
abstract class ChessEngineService {
  Future<void> init();
  bool get isReady;
  bool get isError;
  Stream<String> get outputStream;
  Future<void> sendCommand(String command);
  Future<void> analyzePosition(String fen, {int depth = 15});
  Future<void> stopAnalysis();
  Future<void> setSkillLevel(int level, {int multiPV = 1});
  Future<void> setChess960Mode(bool isEnabled);
  void dispose();
}
