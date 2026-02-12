class AuthService {
  Map<String, String>? _user;

  Future<Map<String, String>> login(String password, String email) async {
    await Future.delayed(const Duration(seconds: 2));

    if (email.isEmpty || password.isEmpty) {
      throw Exception("All Fields required");
    }

    _user = {
      "uid": "local_user_001",
      "email": email,
      "name": email.split('@')[0],
    };

    return _user!;
  }

  Future<void> logout() async{
    _user=null;
  }

  Map<String,String>? get currentUser => _user;
}
