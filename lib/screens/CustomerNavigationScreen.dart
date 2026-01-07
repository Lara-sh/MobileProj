// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../models/customerwallet.dart';
import '../services/shared_preferences_service.dart';
import 'Customer_main_screen.dart';
import 'CurrentServicesScreen.dart';
import 'WalletSummaryScreen.dart';
import '../services/api_service.dart';
import 'welcome_screen.dart';

class CustomerNavigationScreen extends StatefulWidget {
  final String customerEmail;

  const CustomerNavigationScreen({
    super.key,
    required this.customerEmail,
  });

  @override
  State<CustomerNavigationScreen> createState() =>
      _CustomerNavigationScreenState();
}

class _CustomerNavigationScreenState extends State<CustomerNavigationScreen> {
  int _currentIndex = 0;
  CustomerWallet? wallet;
  bool isLoadingWallet = true;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    try {
      final loadedWallet = await ApiService.getWallet(widget.customerEmail);
      setState(() {
        wallet = loadedWallet;
        isLoadingWallet = false;
      });
    } catch (e) {
      setState(() {
        isLoadingWallet = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load wallet: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loader if wallet is not yet loaded
    if (isLoadingWallet) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show error message if wallet failed to load
    if (wallet == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppStyles.primaryVeryDarkColor,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await SharedPreferencesService.clearAll();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WelcomeScreen(),
                      ),
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text("Failed to load wallet"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoadingWallet = true;
                  });
                  _loadWallet();
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            // Reload wallet when switching to wallet tab
            if (index == 2 && wallet != null) {
              _loadWallet();
            }
          },
          backgroundColor: AppStyles.primaryVeryDarkColor,
          selectedItemColor: AppStyles.whiteColor,
          unselectedItemColor: AppStyles.white70,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Services',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'My Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet),
              label: 'Wallet',
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppStyles.primaryVeryDarkColor,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              // Show confirmation dialog
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                // Clear shared preferences
                await SharedPreferencesService.clearAll();
                
                // Navigate to welcome screen
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WelcomeScreen(),
                    ),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Services: pass customerEmail and wallet
          CustomerMainScreen(
            customerEmail: widget.customerEmail,
            wallet: wallet,
          ),

          // My Bookings
          CurrentServicesScreen(
            customerEmail: widget.customerEmail,
          ),

          // Wallet Summary (wallet is guaranteed to be non-null at this point)
          WalletSummaryScreen(
            wallet: wallet!,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          // Reload wallet when switching to wallet tab to ensure latest balance
          if (index == 2 && wallet != null) {
            _loadWallet();
          }
        },
        backgroundColor: AppStyles.primaryVeryDarkColor,
        selectedItemColor: AppStyles.whiteColor,
        unselectedItemColor: AppStyles.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'My Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
        ],
      ),
    );
  }
}
