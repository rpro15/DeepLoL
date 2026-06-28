import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';
import '../constants/api.dart';
import '../models/meme_item.dart';
import '../services/meme_api_service.dart';

class MemeFeedScreen extends StatefulWidget {
  const MemeFeedScreen({super.key});

  @override
  State<MemeFeedScreen> createState() => _MemeFeedScreenState();
}

class _MemeFeedScreenState extends State<MemeFeedScreen> {
  final PageController _pageController = PageController();
  final List<MemeItem> _memes = [];
  bool _loading = true;

  static const List<String> _sampleImages = [
    'https://i.imgflip.com/30b1gx.jpg',
    'https://i.imgflip.com/1ur9b0.jpg',
    'https://i.imgflip.com/3lmzyx.jpg',
    'https://i.imgflip.com/2fm6x.jpg',
    'https://i.imgflip.com/1g8my4.jpg',
    'https://i.imgflip.com/1c1uej.jpg',
    'https://i.imgflip.com/24y43o.jpg',
    'https://i.imgflip.com/26am.jpg',
    'https://i.imgflip.com/1otk96.jpg',
    'https://i.imgflip.com/261o3j.jpg',
  ];

  static const List<String> _fallbackCaptions = [
    'Когда сказал, что не ел торт, а усы в креме',
    'Я в 3 часа ночи вспоминаю тот момент 2017 года',
    'Ожидание vs Реальность',
    'Никто: ... Я: а представьте если...',
    'Лицо когда услышал свою цену',
    'Уровень моего терпения:',
    'Соседи сверху в 2 часа ночи:',
    'Мой план на выходные:',
    'Когда пятница, но ты уже всё потратил',
    'Мозг в 8 утра: "давай поспим ещё"',
    'Я: "всё под контролем" · also я:',
    'Когда зарядка 1%, а ты в середине игры',
    'Лицо когда вспомнил, что не выключил утюг',
    'Когда сказали "расслабься", и ты расслабился',
    'Мои финансы:',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialMemes();
  }

  void _loadInitialMemes() {
    _memes.clear();
    for (int i = 0; i < _sampleImages.length; i++) {
      _memes.add(MemeItem(
        imageUrl: _sampleImages[i],
        caption: _randomCaption(),
        isDialogue: i == 0 || i == 2 || i == 4,
      ));
    }
    _generateAllCaptions();
  }

  Future<void> _generateAllCaptions() async {
    for (int i = 0; i < _memes.length; i++) {
      final meme = _memes[i];
      if (meme.isDialogue) {
        final caps = await MemeApiService().generateDialogueCaptions('мем №${i + 1}');
        meme.caption = caps.isNotEmpty ? caps[0] : _randomCaption();
        meme.captionBottom = caps.length > 1 ? caps[1] : _randomCaption();
      } else {
        final cap = await MemeApiService().generateCaption('мем №${i + 1}');
        meme.caption = cap.isNotEmpty ? cap : _randomCaption();
      }
      if (mounted) setState(() {});
    }
    setState(() => _loading = false);
  }

  String _randomCaption() =>
      _fallbackCaptions[Random().nextInt(_fallbackCaptions.length)];

  Future<void> _regenerateCaption(MemeItem meme) async {
    final cap = await MemeApiService().generateCaption(meme.imageUrl);
    setState(() => meme.caption = cap.isNotEmpty ? cap : _randomCaption());
  }

  Future<void> _downloadMeme(MemeItem meme) async {
    try {
      final resp = await http.get(Uri.parse(meme.imageUrl));
      if (resp.statusCode == 200) {
        await ImageGallerySaver.saveImage(
          resp.bodyBytes, quality: 100,
          name: 'deeplol_${DateTime.now().millisecondsSinceEpoch}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Сохранено в галерею'), duration: Duration(seconds: 1)),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Ошибка сохранения')),
        );
      }
    }
  }

  void _shareMeme(MemeItem meme) {
    final text = meme.isDialogue
        ? '🔹 ${meme.caption}\n🔸 ${meme.captionBottom}'
        : meme.caption;
    SharePlus.instance.share(ShareParams(text: '$text\n\n😂 Создано в DeepLoL'));
  }

  void _rateMeme(MemeItem meme, int laughs) => setState(() => meme.laughs = laughs);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _memes.length + 1,
              itemBuilder: (_, index) {
                if (index >= _memes.length) return _buildCreateCard();
                return _buildMemePage(_memes[index]);
              },
            ),
    );
  }

  Widget _buildMemePage(MemeItem meme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          meme.imageUrl, fit: BoxFit.contain,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Center(child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
              color: AppColors.accent,
            ));
          },
          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 64)),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent, Colors.transparent, Colors.black87],
              stops: [0.0, 0.15, 0.6, 1.0],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8, left: 0, right: 0,
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Text('DeepLoL', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (meme.laughs > 0)
                Row(children: List.generate(meme.laughs, (_) => const Text('😂', style: TextStyle(fontSize: 18)))),
              IconButton(
                icon: const Icon(Icons.replay, color: AppColors.accentLight),
                onPressed: () => _regenerateCaption(meme),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 120, left: 16, right: 16,
          child: meme.isDialogue ? _buildDialogueCaption(meme) : _buildCaption(meme),
        ),
        Positioned(
          bottom: 16, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionBtn(Icons.auto_awesome, 'AI', () => _regenerateCaption(meme)),
              _actionBtn(Icons.emoji_emotions_outlined, 'Ржач', () => _showRatingDialog(meme)),
              _actionBtn(Icons.download, 'Скачать', () => _downloadMeme(meme)),
              _actionBtn(Icons.share, 'Поделиться', () => _shareMeme(meme)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCaption(MemeItem meme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
      child: Text(
        meme.caption.isNotEmpty ? meme.caption : 'Генерация...',
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500, height: 1.3),
      ),
    );
  }

  Widget _buildDialogueCaption(MemeItem meme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomRight: Radius.circular(12),
              ),
            ),
            child: Text(meme.caption.isNotEmpty ? meme.caption : '...', style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomLeft: Radius.circular(12),
              ),
            ),
            child: Text(meme.captionBottom.isNotEmpty ? meme.captionBottom : '...', style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ]),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: Icon(icon, color: Colors.white, size: 26), onPressed: onTap),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _buildCreateCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎰', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 24),
            const Text('Крути!', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Случайный мем с AI-подписью', style: TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton.icon(
                onPressed: _spinRandomMeme,
                icon: const Icon(Icons.casino, size: 28),
                label: const Text('🎰 КРУТИТЬ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _pickFromGallery(),
              icon: const Icon(Icons.photo_library, color: Colors.white54),
              label: const Text('Выбрать своё фото', style: TextStyle(color: Colors.white54)),
            ),
            const Text('\n🏆 Топ ржача за неделю 🏆', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _spinRandomMeme() {
    final random = Random();
    final img = _sampleImages[random.nextInt(_sampleImages.length)];
    final newMeme = MemeItem(imageUrl: img, caption: _randomCaption());
    setState(() => _memes.insert(0, newMeme));
    _pageController.animateToPage(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    _regenerateCaption(newMeme);
  }

  void _pickFromGallery() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🛠️ Выбор фото — image_picker скоро')),
    );
  }

  void _showRatingDialog(MemeItem meme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Оцени ржач!', style: TextStyle(color: Colors.white)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(onPressed: () { _rateMeme(meme, 1); Navigator.pop(ctx); },
                child: const Text('😂', style: TextStyle(fontSize: 32))),
            TextButton(onPressed: () { _rateMeme(meme, 2); Navigator.pop(ctx); },
                child: const Text('😂😂', style: TextStyle(fontSize: 32))),
            TextButton(onPressed: () { _rateMeme(meme, 3); Navigator.pop(ctx); },
                child: const Text('😂😂😂', style: TextStyle(fontSize: 32))),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
