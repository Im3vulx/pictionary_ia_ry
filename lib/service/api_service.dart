import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://pictioniary.wevox.cloud/api';
  static String? _jwt;
  static String? _playerId;
  static String? _gameSessionId;

  // Headers avec authentification
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_jwt != null) 'Authorization': 'Bearer $_jwt',
  };

  // Getters pour accéder aux variables
  static String? get jwt => _jwt;
  static String? get playerId => _playerId;
  static String? get gameSessionId => _gameSessionId;

  /// 1. AUTHENTIFICATION

  /// Créer un joueur
  static Future<Map<String, dynamic>?> createPlayer(
    String name,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/players'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['id'] != null || data['_id'] != null) {
          final dynamic rawId = data['id'] ?? data['_id'];
          _playerId = rawId?.toString();
        }
        return data;
      }
      return null;
    } catch (e) {
      print('Erreur création joueur: $e');
      return null;
    }
  }

  /// Se connecter
  static Future<bool> login(String name, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _jwt = data['jwt'] ?? data['token'] ?? data['access_token'];
        return _jwt != null;
      }
      return false;
    } catch (e) {
      print('Erreur login: $e');
      return false;
    }
  }

  /// Récupérer les infos du joueur connecté
  static Future<Map<String, dynamic>?> getMe() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dynamic id =
            data['id'] ??
            data['_id'] ??
            (data['player'] != null
                ? (data['player']['id'] ?? data['player']['_id'])
                : null);
        if (id != null) {
          _playerId = id.toString();
        }
        return data;
      }
      return null;
    } catch (e) {
      print('Erreur getMe: $e');
      return null;
    }
  }

  /// 2. SESSIONS DE JEU

  /// Créer une session de jeu
  static Future<String?> createGameSession() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/game_sessions'),
        headers: _headers,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final dynamic rawId =
            data['id'] ?? data['_id'] ?? data['gameSessionId'];
        _gameSessionId = rawId?.toString();
        return _gameSessionId;
      }
      return null;
    } catch (e) {
      print('Erreur création session: $e');
      return null;
    }
  }

  /// Rejoindre une session
  static Future<bool> joinSession(String sessionId, String color) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/game_sessions/$sessionId/join'),
        headers: _headers,
        body: jsonEncode({'color': color}),
      );

      if (response.statusCode == 200) {
        _gameSessionId = sessionId;
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur rejoindre session: $e');
      return false;
    }
  }

  /// Démarrer la session
  static Future<bool> startSession(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/game_sessions/$sessionId/start'),
        headers: _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur démarrage session: $e');
      return false;
    }
  }

  /// Récupérer le statut de la session
  static Future<String?> getSessionStatus(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/game_sessions/$sessionId/status'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'];
      }
      return null;
    } catch (e) {
      print('Erreur statut session: $e');
      return null;
    }
  }

  /// 3. CHALLENGES

  /// Envoyer un challenge
  static Future<String?> sendChallenge(
    String sessionId, {
    required String firstWord,
    required String secondWord,
    required String thirdWord,
    required String fourthWord,
    required String fifthWord,
    required List<String> forbiddenWords,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/game_sessions/$sessionId/challenges'),
        headers: _headers,
        body: jsonEncode({
          'first_word': firstWord,
          'second_word': secondWord,
          'third_word': thirdWord,
          'fourth_word': fourthWord,
          'fifth_word': fifthWord,
          'forbidden_words': forbiddenWords,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'] ?? data['_id'] ?? data['challengeId'];
      }
      return null;
    } catch (e) {
      print('Erreur envoi challenge: $e');
      return null;
    }
  }

  /// Récupérer mes challenges à dessiner
  static Future<List<Map<String, dynamic>>?> getMyChallenges(
    String sessionId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/game_sessions/$sessionId/myChallenges'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['items'] != null) {
          return List<Map<String, dynamic>>.from(data['items']);
        }
      }
      return null;
    } catch (e) {
      print('Erreur récupération challenges: $e');
      return null;
    }
  }

  /// Récupérer mes challenges à deviner
  static Future<List<Map<String, dynamic>>?> getMyChallengesToGuess(
    String sessionId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/game_sessions/$sessionId/myChallengesToGuess'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data['items'] != null) {
          return List<Map<String, dynamic>>.from(data['items']);
        }
      }
      return null;
    } catch (e) {
      print('Erreur récupération challenges à deviner: $e');
      return null;
    }
  }

  /// Soumettre un dessin pour un challenge
  static Future<bool> drawForChallenge(
    String sessionId,
    String challengeId,
    String prompt,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/game_sessions/$sessionId/challenges/$challengeId/draw',
        ),
        headers: _headers,
        body: jsonEncode({'prompt': prompt}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur soumission dessin: $e');
      return false;
    }
  }

  /// Répondre à un challenge
  static Future<bool> answerChallenge(
    String sessionId,
    String challengeId,
    String answer,
    bool isResolved,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/game_sessions/$sessionId/challenges/$challengeId/answer',
        ),
        headers: _headers,
        body: jsonEncode({'answer': answer, 'is_resolved': isResolved}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur réponse challenge: $e');
      return false;
    }
  }

  /// Reset des variables (déconnexion)
  static void reset() {
    _jwt = null;
    _playerId = null;
    _gameSessionId = null;
  }
}
