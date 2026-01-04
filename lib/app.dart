// import 'package:flutter/material.dart';
// import 'features/notes/ui/notes_page.dart';

// class App extends StatelessWidget {
//   const App({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'AI Memo Chat',
//       theme: ThemeData(useMaterial3: true),
//       home: NotesPage(),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/ui/login_page.dart';
import 'features/notes/ui/notes_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Memo Chat',
      theme: ThemeData(useMaterial3: true),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session == null) return const LoginPage();
          return NotesPage();
        },
      ),
    );
  }
}
