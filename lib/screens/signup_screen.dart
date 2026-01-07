import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../services/api_service.dart';
import '../services/shared_preferences_service.dart';
import 'CustomerNavigationScreen.dart';

class SignupScreen extends StatefulWidget {
  final String role;

  const SignupScreen({super.key, required this.role});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String email = '';
  String password = '';
  String phone = '';
  late String role;

  @override
  void initState() {
    super.initState();
    role = widget.role;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColorAlt,
      appBar: AppBar(
        title: const Text("Sign Up"),
        backgroundColor: AppStyles.accentColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppStyles.standardPadding16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: AppStyles.smallSpacing),

              /// NAME
              TextFormField(
                decoration: AppStyles.standardInputDecoration.copyWith(
                  labelText: "Name",
                ),
                onSaved: (val) => name = val!,
                validator: (val) =>
                    val!.isEmpty ? "Please enter your name" : null,
              ),

              const SizedBox(height: AppStyles.mediumSpacing),

              /// EMAIL
              TextFormField(
                decoration: AppStyles.standardInputDecoration.copyWith(
                  labelText: "Email",
                ),
                keyboardType: TextInputType.emailAddress,
                onSaved: (val) => email = val!,
                validator: (val) =>
                    val!.isEmpty ? "Please enter your email" : null,
              ),

              const SizedBox(height: AppStyles.mediumSpacing),

              /// PASSWORD
              TextFormField(
                decoration: AppStyles.standardInputDecoration.copyWith(
                  labelText: "Password",
                ),
                obscureText: true,
                onSaved: (val) => password = val!,
                validator: (val) =>
                    val!.isEmpty ? "Please enter your password" : null,
              ),

              const SizedBox(height: AppStyles.mediumSpacing),

              /// PHONE
              TextFormField(
                decoration: AppStyles.standardInputDecoration.copyWith(
                  labelText: "Phone",
                ),
                keyboardType: TextInputType.phone,
                onSaved: (val) => phone = val!,
              ),

              const SizedBox(height: AppStyles.largeSpacing),

              /// ROLE BOX
              Container(
                padding: const EdgeInsets.all(12),
                decoration: AppStyles.roleBoxDecoration,
                child: Text(
                  "Role: ${role.toUpperCase()}",
                  style: AppStyles.roleTextStyle,
                ),
              ),

              const SizedBox(height: AppStyles.xlargeSpacing),

              /// CREATE ACCOUNT BUTTON
              ElevatedButton(
                style: AppStyles.accentButtonStyle,
                child: const Text(
                  "Create Account",
                  style: AppStyles.buttonTextStyle16,
                ),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  _formKey.currentState!.save();

                  final res = await ApiService.signup(
                    name,
                    email,
                    password,
                    role,
                    phone,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['message'])),
                  );

                  if (!res['status']) return;

                  /// SAVE BASIC USER DATA
                  await SharedPreferencesService.saveCustomerEmail(email);
                  await SharedPreferencesService.saveUserRole(role);
                  await SharedPreferencesService.setLoggedIn(true);

                  /// GET CUSTOMER ID SAFELY
                  int? customerId;
                  if (res['customerId'] != null) {
                    customerId = res['customerId'] is int
                        ? res['customerId']
                        : int.tryParse(res['customerId'].toString());

                    if (customerId != null) {
                      await SharedPreferencesService.saveCustomerId(customerId);
                    }
                  }

                  /// CREATE WALLET AUTOMATICALLY (balance = 0)
                  /// card_number, card_holder, expiry_date, cvv => NULL
                  if (role.toLowerCase() == 'customer') {
                    try {
                      await ApiService.createWallet(
                        email,
                        userId: customerId,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text("Warning: Wallet creation failed"),
                        ),
                      );
                    }

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerNavigationScreen(
                          customerEmail: email,
                        ),
                      ),
                    );
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
