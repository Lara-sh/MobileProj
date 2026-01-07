import 'package:flutter/material.dart';
import '../styles/app_styles.dart';
import '../models/service.dart';
import '../models/customerwallet.dart';
import '../services/api_service.dart';
import '../services/shared_preferences_service.dart';
import 'service_details_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  final CustomerWallet? wallet;
  final String? customerEmail;

  const CustomerMainScreen({super.key, this.wallet, this.customerEmail});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  late Future<List<Service>> servicesFuture;
  CustomerWallet? _wallet;
  String? _customerEmail;

  @override
  void initState() {
    super.initState();
    servicesFuture = ApiService.getServices();
    _wallet = widget.wallet;
    _customerEmail = widget.customerEmail;
    
    // If wallet is null but we have email, try to load it
    if (_wallet == null && _customerEmail != null && _customerEmail!.isNotEmpty) {
      _loadWallet();
    } else if (_customerEmail == null || _customerEmail!.isEmpty) {
      // Try to get email from shared preferences
      _loadCustomerEmail();
    }
  }

  Future<void> _loadCustomerEmail() async {
    final email = await SharedPreferencesService.getCustomerEmail();
    setState(() {
      _customerEmail = email;
    });
    if (_customerEmail != null && _customerEmail!.isNotEmpty && _wallet == null) {
      _loadWallet();
    }
  }

  Future<void> _loadWallet() async {
    if (_customerEmail == null || _customerEmail!.isEmpty) return;
    
    try {
      final loadedWallet = await ApiService.getWallet(_customerEmail!);
      setState(() {
        _wallet = loadedWallet;
      });
    } catch (e) {
      // Wallet loading failed, keep _wallet as null
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.primaryColor,
      appBar: AppBar(
        title: const Text("Car Wash Services"),
        backgroundColor: AppStyles.primaryVeryDarkColor,
      ),
      body: FutureBuilder<List<Service>>(
        future: servicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppStyles.whiteColor));
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: AppStyles.errorTextStyle));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No services available", style: AppStyles.errorTextStyle));
          } else {
            final services = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(AppStyles.standardPadding10),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                String imageName = service.image.trim();

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: AppStyles.cardShape,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: AppStyles.cardTopBorderRadius,
                        child: Image.asset(
                          "assets/images/$imageName",
                          width: double.infinity,
                          height: AppStyles.imageHeight,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: AppStyles.imageHeight,
                              color: AppStyles.greyColor,
                              child: const Center(
                                  child: Icon(Icons.car_repair, size: AppStyles.iconSize, color: AppStyles.whiteColor)),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                service.name,
                                style: AppStyles.serviceNameStyle,
                              ),
                            ),
                            Text(
                              "\$${service.price.toStringAsFixed(2)}",
                              style: AppStyles.servicePriceStyle,
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            if (_wallet == null && _customerEmail != null && _customerEmail!.isNotEmpty) {
                              // Try to load wallet if not available
                              _loadWallet().then((_) {
                                if (_wallet != null && mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ServiceDetailsScreen(
                                        service: service,
                                        wallet: _wallet!,
                                        customerEmail: _customerEmail!,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Please wait while wallet is loading...")),
                                  );
                                }
                              });
                            } else if (_wallet != null && _customerEmail != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ServiceDetailsScreen(
                                    service: service,
                                    wallet: _wallet!,
                                    customerEmail: _customerEmail!,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Customer information not available")),
                              );
                            }
                          },
                          child: const Text("View Details"),
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
