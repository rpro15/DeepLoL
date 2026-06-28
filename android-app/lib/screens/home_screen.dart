import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'meme_feed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final List<Widget> _pages = const [
    MemeFeedScreen(),
    _PlaceholderPage(icon: Icons.collections_bookmark, title: 'Мои мемы', desc: 'Сохранённые мемы появятся здесь'),
    _PlaceholderPage(icon: Icons.emoji_events, title: '🏆 Топ ржача', desc: 'Скоро — рейтинг самых смешных'),
    _PlaceholderPage(icon: Icons.settings, title: 'Настройки', desc: 'Тема, API, очистка кэша'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textHint,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Лента'),
          BottomNavigationBarItem(icon: Icon(Icons.collections_bookmark), label: 'Мои'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Топ'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Настройки'),
        ],
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _PlaceholderPage({required this.icon, required this.title, required this.desc});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 80, color: Colors.white24),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 20)),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }
}
