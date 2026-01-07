import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../models/customerwallet.dart';
import '../services/shared_preferences_service.dart';
import '../services/api_service.dart';
import 'walletscreen.dart';

class WalletSummaryScreen extends StatefulWidget {
  final CustomerWallet wallet;

  const WalletSummaryScreen({super.key, required this.wallet});

  @override
  State<WalletSummaryScreen> createState() => _WalletSummaryScreenState();
}

class _WalletSummaryScreenState extends State<WalletSummaryScreen> {
  String? _customerEmail;
  CustomerWallet? _currentWallet;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentWallet = widget.wallet;
    _loadCustomerEmail();
    _refreshWallet();
  }

  Future<void> _loadCustomerEmail() async {
    final email = await SharedPreferencesService.getCustomerEmail();
    setState(() {
      _customerEmail = email ?? '';
    });
  }

  Future<void> _refreshWallet() async {
    if (_customerEmail == null || _customerEmail!.isEmpty) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      final refreshedWallet = await ApiService.getWallet(_customerEmail!);
      setState(() {
        _currentWallet = refreshedWallet;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.primaryLightColor,
      appBar: AppBar(
        title: const Text("Wallet"),
        backgroundColor: AppStyles.primaryVeryDarkColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Balance',
            onPressed: _refreshWallet,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppStyles.standardPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppStyles.xlargeSpacing),
                  decoration: AppStyles.balanceBoxDecoration,
                  child: Column(
                    children: [
                      const Text(
                        "Current Balance",
                        style: TextStyle(
                          color: AppStyles.whiteColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppStyles.smallSpacing),
                      _isRefreshing
                          ? const CircularProgressIndicator(color: AppStyles.whiteColor)
                          : Text(
                              "\$${(_currentWallet ?? widget.wallet).balance.toStringAsFixed(2)}",
                              style: AppStyles.walletBalanceStyle,
                              textAlign: TextAlign.center,
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: AppStyles.xlargeSpacing40),
                ElevatedButton(
                  style: AppStyles.whiteRoundedButtonStyle,
                  onPressed: () async {
                    if (_customerEmail != null && _customerEmail!.isNotEmpty) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WalletScreen(customerEmail: _customerEmail!),
                        ),
                      );
                      // Refresh wallet after returning from WalletScreen
                      _refreshWallet();
                    }
                  },
                  child: const Text(
                    "Add Money to Wallet",
                    style: AppStyles.buttonTextStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




