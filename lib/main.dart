import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'features/bookings/presentation/screens/bookings_screen.dart';
import 'features/bookings/presentation/screens/add_booking_screen.dart';
import 'features/bookings/presentation/screens/booking_detail_screen.dart';
import 'features/refunds/presentation/screens/refunds_screen.dart';
import 'features/refunds/presentation/screens/add_refund_screen.dart';
import 'features/wallet/presentation/screens/wallet_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  runApp(const TravelErpApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/', builder: (c, s) => const DashboardScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/bookings',
            builder: (c, s) => const BookingsScreen(),
            routes: [
              GoRoute(path: 'add', builder: (c, s) => const AddBookingScreen()),
              GoRoute(
                path: ':id',
                builder: (c, s) => BookingDetailScreen(
                    bookingId: s.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'refund',
                    builder: (c, s) {
                      // سيتم تمرير الحجز من الشاشة السابقة
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/refunds', builder: (c, s) => const RefundsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/wallet', builder: (c, s) => const WalletScreen()),
        ]),
      ],
    ),
  ],
);

class TravelErpApp extends StatefulWidget {
  const TravelErpApp({super.key});
  @override
  State<TravelErpApp> createState() => _TravelErpAppState();
}

class _TravelErpAppState extends State<TravelErpApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() => setState(() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Travel Agency ERP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      routerConfig: _router,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

class MainShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const MainShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i,
            initialLocation: i == shell.currentIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.airplane_ticket_outlined),
            selectedIcon: Icon(Icons.airplane_ticket),
            label: 'الحجوزات',
          ),
          NavigationDestination(
            icon: Icon(Icons.replay_outlined),
            selectedIcon: Icon(Icons.replay),
            label: 'المرتجعات',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'المحفظة',
          ),
        ],
      ),
    );
  }
}
