import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/user.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/parking_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/booking_service.dart';
import 'services/config_service.dart';
//use map key "AIzaSyC3IfmFYxO7zTSzAy6XyM7gHzq6b_0b5Og" inside env in following way "MAP_KEY="AIzaSyC3IfmFYxO7zTSzAy6XyM7gHzq6b_0b5Og""

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigService.init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseUrl = ConfigService.getSavedUrl();

    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient(baseUrl)),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<ParkingProvider>(
          create: (context) => ParkingProvider(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<BookingProvider>(
          create: (context) => BookingProvider(
            BookingService(context.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<SubscriptionProvider>(
          create: (context) => SubscriptionProvider(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider<AdminProvider>(
          create: (context) => AdminProvider(context.read<ApiClient>()),
        ),
        Provider<UserModel?>.value(value: null),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, auth, theme, _) {
          return MaterialApp(
            title: 'Smart Park',
            theme: theme.lightTheme,
            darkTheme: theme.darkTheme,
            themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            home: auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
          );
        },
      ),
    );
  }
}
