import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_mind/blocs/auth/auth_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String title = 'Market Mind Home';
        if (state is AuthAuthenticated) {
          title = state.user.email ?? 'Market Mind Home';
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              if (state is AuthAuthenticated)
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: () {
                    BlocProvider.of<AuthBloc>(context)
                        .add(AuthLogoutRequested());
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
            ],
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, size: 64, color: Colors.deepPurple),
                SizedBox(height: 24),
                Text(
                  'Welcome to Market Mind!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Your AI-powered investment assistant.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
