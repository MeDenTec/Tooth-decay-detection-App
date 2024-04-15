import 'package:flutter/material.dart';
import 'package:object_detection/HomeScreen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Simulated authentication function
  Future<bool> _login(String username, String password) async {
    // You can replace this with your actual authentication logic
    // For example, checking against hardcoded credentials or fetching from assets
    if (username == 'admin' && password == 'password') {
      return true;
    } else {
      return false;
    }
  }

  void _authenticate(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    bool isAuthenticated = await _login(
      _usernameController.text,
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Authentication Failed'),
            content: Text('Invalid username or password.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Add your image here
                  Image.asset(
                    'assets/images/AKU_logo1.png', // Replace with your image path
                    width: 400, // Adjust width as needed
                    height: 200, // Adjust height as needed
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Teeth Disease Detection App",
                    style: TextStyle(
                      fontSize: 28,
                      color: Color.fromARGB(255, 12, 132, 207),
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _authenticate(context),
                    child: Text('Login'),
                  ),
                ],
              ),
            ),
    );
  }
}
