"""Editorial metrics for recorded QA texts (no provider). Usage:
python -X utf8 scripts/_editorial_metrics.py <results.json> [...]
Numbers support a human read; they are not a pass/fail verdict."""
import json
import re
import sys

ABSTRACT = ['güven', 'özgürlük', 'gerilim', 'denge', 'derinlik', 'sezgi',
            'yoğunluk', 'iç dünya', 'sorumluluk', 'cesaret', 'özdeğer']
STOP = set('ve ile bir bu da de daha çok gibi için ama ya ki en o sen seni sana '
           'senin bugün olarak kadar hem ne değil var yok her'.split())


def words(t):
    return re.findall(r'\w+', t.lower())


def content(t):
    return {w for w in words(t) if len(w) > 4 and w not in STOP}


def texts_of(data):
    if 'summary' in data:
        parts = {'summary': data['summary']['text']}
        for i, s in enumerate(data['sections']):
            parts[f"{i}:{s['kind']}"] = s['text']
        parts['reflection'] = data.get('reflectionPrompt') or ''
        parts['closing'] = data['closingMessage']
        return parts
    return {k: data[k] for k in ['portrait', 'overall', 'love', 'career', 'money',
                                 'mood', 'drive', 'opportunity', 'caution', 'reflection']}


for path in sys.argv[1:]:
    doc = json.load(open(path, encoding='utf-8'))
    print(f'# {path.split("/")[-1]}')
    for r in doc['results']:
        if not r.get('data'):
            print(f"  {r['id']}: no text ({r.get('error')})")
            continue
        parts = texts_of(r['data'])
        allt = ' '.join(parts.values())
        low = allt.lower()
        name = r['id'].split('.')[-1]
        abstract = {a: low.count(a) for a in ABSTRACT if low.count(a) > 2}
        hedges = len(re.findall(r'\w+(?:abil|ebil)\w*', low))
        line = (f"  {r['id']}: words={len(words(allt))} hedges={hedges} "
                f"name={len(re.findall(rf'(?<!\w){name}(?!\w)', allt))} "
                f"pastReadings={len(re.findall(r'okumalar', low))} "
                f"overused={abstract or '-'}")
        if 'overall' in parts:
            base = content(parts['overall'])
            bleed = {k: round(len(base & content(parts[k])) / max(1, len(content(parts[k]))), 2)
                     for k in ['mood', 'drive', 'opportunity']}
            line += f" overallBleed={bleed}"
        print(line)
