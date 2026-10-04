import json, os
from PIL import Image

RES = 'TarotContent/Resources'
d = json.load(open(f'{RES}/cards.json'))
cards = d['cards'] if isinstance(d, dict) else d
names = [c.get('imageName') for c in cards]
files = set(os.listdir(RES))
missing_hk = [n for n in names if ('helloKitty_' + n + '.png') not in files]
missing_rw = [n for n in names if (n + '.png') not in files]
print('cards:', len(names), '| missing HK:', len(missing_hk), '| missing RW:', len(missing_rw))

bad = []
sizes = []
for n in names:
    p = f'{RES}/helloKitty_{n}.png'
    try:
        im = Image.open(p)
        im.verify()
        sz = os.path.getsize(p)
        sizes.append(sz)
        if sz < 3000:
            bad.append((n, 'tiny', sz))
    except Exception as e:
        bad.append((n, str(e)[:40], os.path.getsize(p) if os.path.exists(p) else -1))
print('HK corrupted/tiny:', len(bad), bad[:5])
if sizes:
    print('HK size min/max KB:', min(sizes)//1024, max(sizes)//1024)
im = Image.open(f'{RES}/helloKitty_card_00_the_fool.png')
print('sample mode/size:', im.mode, im.size)

# Marseille: how many exist?
mar = [f for f in files if f.startswith('marseille_')]
print('marseille files:', len(mar))
