# DeepLoL 🤖😂

**AI-генератор мемных подписей** + Flutter-приложение в TikTok-формате.

## 🚀 Быстрый старт

### 1. Бэкенд (Cloudflare Worker)
\`\`\`bash
cd deeplol-backend
wrangler kv:namespace create "MEME_CACHE"
# вставить ID в wrangler.toml
wrangler secret put DEEPSEEK_API_KEY
wrangler publish
\`\`\`

### 2. Android
\`\`\`bash
cd android-app
flutter pub get
flutter run
\`\`\`

### 3. Скачать картинки (100+ мемов)
\`\`\`bash
cd android-app
python download_templates.py
\`\`\`

## 📱 Фичи
- TikTok-лента с мемами
- AI-подпись (DeepSeek)
- Скачать / Поделиться
- Рейтинг ржача 😂
- 🎰 Крутилка
- Диалоговые мемы (2 персонажа)
