import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/bouncy_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/order_details/screens/order_details_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/update/screen/update_screen.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/push_notification/models/notification_body.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/utill/color_resources.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/no_internet_screen_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/screens/inbox_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/maintenance/maintenance_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/notification/screens/notification_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/onboarding/screens/onboarding_screen.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  final NotificationBody? body;
  const SplashScreen({super.key, this.body});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  final GlobalKey<ScaffoldMessengerState> _globalKey = GlobalKey();
  late StreamSubscription<ConnectivityResult> _onConnectivityChanged;

  @override
  void initState() {
    super.initState();
    print('SplashScreen: initState called');
    
    _initializeApp();
  }

  void _initializeApp() {
    bool firstTime = true;
    _onConnectivityChanged = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (!firstTime) {
        bool isNotConnected = result != ConnectivityResult.wifi && result != ConnectivityResult.mobile;
        isNotConnected ? const SizedBox() : ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: isNotConnected ? Colors.red : Colors.green,
          duration: Duration(seconds: isNotConnected ? 6000 : 3),
          content: Text(
            isNotConnected ? getTranslated('no_connection', context)! : getTranslated('connected', context)!,
            textAlign: TextAlign.center,
          ),
        ));
        if (!isNotConnected) {
          _route();
        }
      }
      firstTime = false;
    });

    _route();
  }

  @override
  void dispose() {
    _onConnectivityChanged.cancel();
    super.dispose();
  }

  void _route() {
    print('SplashScreen: Starting route navigation');
    
    Provider.of<SplashController>(context, listen: false).initConfig(context).then((bool isSuccess) {
      print('SplashScreen: Config initialized - success: $isSuccess');
      
      if (isSuccess) {
        _checkAppVersionAndNavigate();
      } else {
        // If config fails, navigate directly to dashboard after delay
        print('SplashScreen: Config failed, navigating to dashboard');
        Timer(const Duration(seconds: 2), () {
          _navigateToDashboard();
        });
      }
    }).catchError((error) {
      print('SplashScreen: Config error: $error');
      // Even if there's an error, navigate after delay
      Timer(const Duration(seconds: 2), () {
        _navigateToDashboard();
      });
    });
  }

  void _checkAppVersionAndNavigate() {
    try {
      final splashController = Provider.of<SplashController>(context, listen: false);
      final authController = Provider.of<AuthController>(context, listen: false);
      
      splashController.initSharedPrefData();
      
      Timer(const Duration(seconds: 2), () {
        _navigateBasedOnConditions(splashController, authController);
      });
    } catch (e) {
      print('SplashScreen: Error in version check: $e');
      Timer(const Duration(seconds: 2), () {
        _navigateToDashboard();
      });
    }
  }

  void _navigateBasedOnConditions(SplashController splashController, AuthController authController) {
    try {
      // 1. Check maintenance mode
      if (splashController.configModel?.maintenanceMode == true) {
        print('SplashScreen: Maintenance mode - navigating to MaintenanceScreen');
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MaintenanceScreen()));
        return;
      }

      // 2. Check app version update
      String? minimumVersion = "0";
      UserAppVersionControl? appVersion = splashController.configModel?.userAppVersionControl;
      
      if (Platform.isAndroid) {
        minimumVersion = appVersion?.forAndroid?.version ?? '0';
      } else if (Platform.isIOS) {
        minimumVersion = appVersion?.forIos?.version ?? '0';
      }

      if (compareVersions(minimumVersion!, AppConstants.appVersion) == 1) {
        print('SplashScreen: Update required - navigating to UpdateScreen');
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const UpdateScreen()));
        return;
      }

      // 3. Handle navigation based on user state
      if (authController.isLoggedIn()) {
        print('SplashScreen: User is logged in');
        authController.updateToken(context);
        _handleLoggedInUser();
      } else if (splashController.showIntro()!) {
        print('SplashScreen: Showing onboarding');
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => OnBoardingScreen(
            indicatorColor: ColorResources.grey,
            selectedIndicatorColor: Theme.of(context).primaryColor,
          ),
        ));
      } else {
        print('SplashScreen: Guest user - navigating to dashboard');
        _handleGuestUser(authController);
      }
    } catch (e) {
      print('SplashScreen: Navigation error: $e');
      _navigateToDashboard();
    }
  }

  void _handleLoggedInUser() {
    if (widget.body != null) {
      if (widget.body!.type == 'order') {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => OrderDetailsScreen(orderId: widget.body!.orderId),
        ));
      } else if (widget.body!.type == 'notification') {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const NotificationScreen(),
        ));
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const InboxScreen(isBackButtonExist: true),
        ));
      }
    } else {
      _navigateToDashboard();
    }
  }

  void _handleGuestUser(AuthController authController) {
    if (authController.getGuestToken() != null && authController.getGuestToken() != '1') {
      _navigateToDashboard();
    } else {
      authController.getGuestIdUrl();
      _navigateToDashboard();
    }
  }

  void _navigateToDashboard() {
    print('SplashScreen: Navigating to Dashboard');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DashBoardScreen()),
    );
  }

  int compareVersions(String version1, String version2) {
    try {
      List<String> v1Components = version1.split('.');
      List<String> v2Components = version2.split('.');
      
      int maxLength = v1Components.length > v2Components.length ? v1Components.length : v2Components.length;
      
      for (int i = 0; i < maxLength; i++) {
        int v1Part = i < v1Components.length ? int.parse(v1Components[i]) : 0;
        int v2Part = i < v2Components.length ? int.parse(v2Components[i]) : 0;
        
        if (v1Part > v2Part) {
          return 1;
        } else if (v1Part < v2Part) {
          return -1;
        }
      }
      return 0;
    } catch (e) {
      print('SplashScreen: Version comparison error: $e');
      return 0; // Default to no update needed if comparison fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      key: _globalKey,
      body: Consumer<SplashController>(
        builder: (context, splashController, child) {
          return splashController.hasConnection
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BouncyWidget(
                        duration: const Duration(milliseconds: 2000),
                        lift: 50,
                        ratio: 0.5,
                        pause: 0.25,
                        child: SizedBox(
                          width: 150,
                          child: Image.asset(Images.icon, width: 150.0),
                        ),
                      ),
                      Text(
                        AppConstants.appName,
                        style: textRegular.copyWith(
                          fontSize: Dimensions.fontSizeOverLarge,
                          color: Colors.white,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                        child: Text(
                          AppConstants.slogan,
                          style: textRegular.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const NoInternetOrDataScreenWidget(isNoInternet: true, child: SplashScreen());
        },
      ),
    );
  }
}
