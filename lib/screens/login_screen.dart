import 'package:flutter/material.dart';
// import 'auth_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;


  @override
  Widget build(BuildContext context) {
  final height = MediaQuery.of(context).size.height;
  final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Column(
        children: [
          const Center(child: Text('Welcome Back!')),
          const Center(child: Text('Please sign in to continue')),
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: height * 0.02),

          // PASSWORD FIELD
          const Text(
            'Password',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outlined),

              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: Colors.white,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,

                          child: ElevatedButton(
                                  onPressed: () async {
                                    if (emailController.text.isEmpty ||
                                        passwordController.text.isEmpty) {

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Please fill all fields'),
                                        ),
                                      );
                                      return;
                                    }
                                  },

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Color.fromRGBO(59, 160, 254, 1),

                                    padding: EdgeInsets.symmetric(
                                      vertical:  14,
                                    ),

                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),

                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize:  16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                        ),

        ],
      ),
    );
  }
}
