# Regenera assets/data/exercises_dataset.json desde el dataset open-source
# https://github.com/hasaneyldrm/exercises-dataset (MIT; media (c) Gym visual)
#
# Uso (desde la raiz del proyecto):
#   curl -sL -o tool/exercises_raw.json https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/data/exercises.json
#   python tool/build_exercises_asset.py
#
# Conserva solo los campos que usa la app y las instrucciones en espanol
# (con fallback a ingles), reduciendo el asset de ~17 MB a ~0.9 MB.

import json
import os

RAW = os.path.join(os.path.dirname(__file__), 'exercises_raw.json')
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'exercises_dataset.json')

data = json.load(open(RAW, encoding='utf-8'))
slim = []
for r in data:
    steps = r.get('instruction_steps', {}).get('es') or r.get('instruction_steps', {}).get('en') or []
    slim.append({
        'id': r['id'],          # ID original del dataset ("0001")
        'n': r['name'],         # nombre (ingles)
        't': r['target'],       # musculo objetivo
        'b': r['body_part'],    # parte del cuerpo
        'e': r['equipment'],    # equipamiento
        's': r.get('secondary_muscles', []),
        'm': f"{r['id']}-{r['media_id']}",  # stem de media: videos/<m>.gif, images/<m>.jpg
        'i': steps,             # pasos de instruccion en espanol
    })

with open(OUT, 'w', encoding='utf-8') as f:
    f.write(json.dumps(slim, ensure_ascii=False, separators=(',', ':')))

print(f'{len(slim)} ejercicios -> {os.path.abspath(OUT)} ({os.path.getsize(OUT)/1e6:.2f} MB)')
