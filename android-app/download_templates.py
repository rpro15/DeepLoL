#!/usr/bin/env python3
import json, os
from urllib.request import urlopen, Request

IMAGES_DIR = os.path.join(os.path.dirname(__file__), 'assets', 'templates', 'images')
JSON_PATH = os.path.join(os.path.dirname(__file__), 'assets', 'templates', 'meme_templates.json')

def main():
    os.makedirs(IMAGES_DIR, exist_ok=True)
    with open(JSON_PATH) as f:
        memes = json.load(f)
    print(f'Найдено {len(memes)} мемов. Скачиваю в {IMAGES_DIR}...')
    for i, m in enumerate(memes, 1):
        url = m['url']
        name = m['name'].replace('/', '_').replace(' ', '_')[:60]
        ext = url.split('.')[-1].split('?')[0]
        fp = os.path.join(IMAGES_DIR, f"{m['id']}_{name}.{ext}")
        if os.path.exists(fp):
            continue
        try:
            req = Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urlopen(req, timeout=30) as r, open(fp, 'wb') as out:
                out.write(r.read())
            print(f'  [{i}/{len(memes)}] {name}')
        except Exception as e:
            print(f'  [{i}/{len(memes)}] FAIL {name}: {e}')
    print(f'Готово! Файлы в {IMAGES_DIR}')

if __name__ == '__main__':
    main()
