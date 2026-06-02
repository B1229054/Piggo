import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart' as line;
import 'package:http/http.dart' as http;

import 'quiz_screen.dart';
import 'home/home_navigation.dart';
import 'post/new_post_screen.dart';
import 'settings/settings_screen.dart';
import 'settings/account_settings_screen.dart';
import 'settings/language_settings_screen.dart';
import 'settings/qrcode_screen.dart';
import 'settings/privacy_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // LINE SDK must be initialized once before any LINE login call.
  //await line.LineSDK.instance.setup(_lineChannelId);

  runApp(const PiggoApp());
}

const String _apiBaseUrl = 'http://10.0.2.2:3000';
const String _googleServerClientId =
    '915340601206-hmpfe63dlgp1g7dmbv8fljep74fjt0eo.apps.googleusercontent.com';
const String _lineChannelId = '2008788101';

class PiggoApp extends StatelessWidget {
  const PiggoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Piggo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/quiz': (context) => const QuizScreen(),
        '/home': (context) => const HomeNavigation(),
        '/settings': (context) => const SettingsScreen(),
        '/account': (context) => const AccountSettingsScreen(),
        '/privacy': (context) => const PrivacySettingsScreen(),
        '/language': (context) => const LanguageSettingsScreen(),
        '/qrcode': (context) => const QRCodeScreen(),
        '/new_post': (context) => const NewPostScreen(),
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isHappyPig = true;
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _isLoading = true);

      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        serverClientId: _googleServerClientId,
      );

      final GoogleSignInAccount? googleUser =
          await googleSignIn.authenticate(
        scopeHint: const ['email', 'profile'],
      );

      if (googleUser == null) return;

      final result = await _syncUserToBackend(
        provider: 'google',
        userId: googleUser.id,
        email: googleUser.email,
        displayName: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
      );

      if (!mounted) return;
      _showLoginSuccess(result);
    } catch (error) {
      _showError('Google 登入失敗：$error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Future<void> _handleFacebookSignIn() async {
  //   try {
  //     setState(() => _isLoading = true);

  //     final fb.LoginResult loginResult = await fb.FacebookAuth.instance.login(
  //       permissions: const ['email', 'public_profile'],
  //     );

  //     if (loginResult.status != fb.LoginStatus.success ||
  //         loginResult.accessToken == null) {
  //       return;
  //     }

  //     final userData = await fb.FacebookAuth.instance.getUserData(
  //       fields: 'id,name,email,picture.width(200)',
  //     );

  //     final result = await _syncUserToBackend(
  //       provider: 'facebook',
  //       userId: userData['id']?.toString() ??
  //           loginResult.accessToken!.tokenString,
  //       email: userData['email']?.toString(),
  //       displayName: userData['name']?.toString(),
  //       photoUrl: userData['picture']?['data']?['url']?.toString(),
  //     );

  //     if (!mounted) return;
  //     _showLoginSuccess(result);
  //   } catch (error) {
  //     _showError('Facebook 登入失敗：$error');
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isLoading = false);
  //     }
  //   }
  // }

  Future<void> _handleLineSignIn() async {
    try {
      setState(() => _isLoading = true);

      final line.LoginResult loginResult = await line.LineSDK.instance.login(
        scopes: const ['profile', 'openid', 'email'],
      );

      final profile = loginResult.userProfile;
      final result = await _syncUserToBackend(
        provider: 'line',
        userId: profile?.userId ?? loginResult.accessToken.value,
        email: loginResult.accessToken.email,
        displayName: profile?.displayName,
        photoUrl: profile?.pictureUrl,
      );

      if (!mounted) return;
      _showLoginSuccess(result);
    } on PlatformException catch (error) {
      _showError('LINE 登入失敗：${error.message ?? error.toString()}');
    } catch (error) {
      _showError('LINE 登入失敗：$error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _syncUserToBackend({
    required String provider,
    required String userId,
    String? email,
    String? displayName,
    String? photoUrl,
  }) async {
    final url = Uri.parse('$_apiBaseUrl/api/auth/$provider');
    final response = await http.post(
      url,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'provider': provider,
        'provider_user_id': userId,
        'email': email,
        'displayName': displayName,
        'photoURL': photoUrl,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('後端回傳 ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{'raw': decoded};
  }

  void _showLoginSuccess(Map<String, dynamic> data) {
    final userId = data['user_id'] ?? data['id'] ?? 'unknown';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('登入成功，使用者 ID：$userId')),
    );

    Navigator.pushReplacementNamed(context, '/home');
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F9FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Login Piggo',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4E84A7),
                  ),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 40),
                if (_isLoading) const CircularProgressIndicator(),
                if (_isLoading) const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialButton(
                      label: 'LINE',
                      icon: FontAwesomeIcons.line,
                      iconColor: const Color(0xFF06C755),
                      onTap: _handleLineSignIn,
                    ),
                    // const SizedBox(width: 18),
                    // _buildSocialButton(
                    //   label: 'FB',
                    //   icon: FontAwesomeIcons.facebook,
                    //   iconColor: const Color(0xFF4267B2),
                    //   onTap: _handleFacebookSignIn,
                    // ),
                    const SizedBox(width: 18),
                    _buildSocialButton(
                      label: 'Google',
                      icon: FontAwesomeIcons.google,
                      iconColor: Colors.black,
                      isGoogle: true,
                      onTap: _handleGoogleSignIn,
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/quiz');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF8BA0B2),
                      ),
                    ),
                    child: const Text(
                      '先不登入，直接試用',
                      style: TextStyle(
                        color: Color(0xFF6CA6CC),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isHappyPig = !isHappyPig;
                    });
                  },
                  child: Container(
                    width: 200,
                    height: 200,
                    alignment: Alignment.center,
                    child: Image.asset(
                      isHappyPig
                          ? 'assets/piggy/pig_login0.png'
                          : 'assets/piggy/pig_login1.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                const Text(
                  '點圖會換表情',
                  style: TextStyle(
                    color: Color(0xFF8BA0B2),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required dynamic icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool isGoogle = false,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: FaIcon(
                icon,
                size: isGoogle ? 34 : 32,
                color: isGoogle ? const Color(0xFFEA4335) : iconColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4E84A7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
