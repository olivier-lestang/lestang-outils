#!/usr/bin/env python3
"""Extrait les articles du « Dizionario della lingua italiana » compilé par
les Académiciens de la Crusca (édition Costa-Cardinali, 1819, domaine public),
OCR Internet Archive (dizionariodellal01cost … 07cost).

Le Crusca ne marque pas la nature : un article commence par sa vedette en
capitales suivie d'un point, en début de ligne. On indexe donc toutes les
vedettes et on capture le texte jusqu'à la vedette suivente.

Usage : python3 parse_crusca.py crusca1.txt crusca2.txt ... crusca_verbes.json
Sortie : {vedette (minuscule): [article1, article2, ...]}
"""
import json
import re
import sys
import unicodedata

VEDETTE = re.compile(
    r"^([A-ZÀÈÉÌÒÙÁÉÍÓÚÂÊÎÔÛÃÕÇ&][A-ZÀÈÉÌÒÙÁÉÍÓÚÂÊÎÔÛÃÕÇ'’\-]{1,24})\s*\.",
    re.UNICODE | re.MULTILINE,
)


def nettoie(txt: str) -> str:
    txt = unicodedata.normalize('NFC', txt)
    txt = re.sub(r'¬[ \t]*\n', '', txt)
    txt = re.sub(r'([a-zà-ÿ])-\s*\n\s*([a-zà-ÿ])', r'\1\2', txt)
    txt = re.sub(r'[ \t]+', ' ', txt)
    txt = re.sub(r'\n{2,}', '\n', txt)
    return txt


def _nettoie_sens(s: str) -> str:
    s = re.sub(r'\s+', ' ', s.replace('\n', ' '))
    # retire les citations Lat./Bocc./Petr. à la fin d'un sens
    s = re.sub(r'\s(?:Lat\.|Bocc\.|Petr\.|Dant\.|Car\.|Varch\.)\s[^.]*\.\s*$',
               '', s)
    return s.strip(' ;.,')


def parse(txt: str):
    articles = {}
    marqueurs = [(m.start(), m.group(1)) for m in VEDETTE.finditer(txt)]
    for i, (pos, ved) in enumerate(marqueurs):
        fin = marqueurs[i + 1][0] if i + 1 < len(marqueurs) else len(txt)
        # ligne complète de la vedette : du premier point au suivant marqueur
        reste = txt[pos + len(ved) + 1:fin]
        sens = _nettoie_sens(reste)[:300]
        if len(sens) > 3:
            articles.setdefault(ved.lower(), []).append(sens)
    return articles


def main():
    dst = sys.argv[-1]
    res = {}
    for src in sys.argv[1:-1]:
        txt = nettoie(open(src, encoding='utf-8').read())
        for v, sens in parse(txt).items():
            res.setdefault(v, []).extend(sens)
    # aplatir et dédoublonner les sens
    out = {v: sorted(set(sens), key=sens.index)[:6] for v, sens in res.items()}
    json.dump(out, open(dst, 'w', encoding='utf-8'), ensure_ascii=False)
    print('vedettes :', len(out))
    for v in ('amare', 'essere', 'vedere', 'potere', 'sognare', 'badare'):
        print(v, '->', out.get(v, [])[:1])
    print('OK')


if __name__ == '__main__':
    main()
