#!/usr/bin/env python3
"""Extrait les définitions verbales du « Nòvo dizionàrio universale della
lingua italiana » de Policarpo Petrocchi (1887-1891, domaine public),
OCR Internet Archive (novodizionarioun01petruoft / 02petruoft).

Usage : python3 parse_petrocchi.py petr1.txt petr2.txt petrocchi_verbes.json
Sortie : {vedette (minuscule): [sens1, sens2, ...]}
"""
import json
import re
import sys
import unicodedata

# natures verbales et non verbales de Petrocchi (après la vedette et une virgule)
NATURE = (
    r'(?:tr|intr|rifl| vtx|impers|v\.a|v\.n|'
    r's\.m|s\.f|s\.m\.\s?e\s?f|s\.f\.\s?e\s?m|agg|avv|part|pron|prep|'
    r'cong|interj|num|s\.|sm|sf)\.'
)
ARTICLE = re.compile(
    r'(?:^|[.;:!?)»]\s+|\n[^\n]{0,4}?\s*)'
    r'([A-ZÀÈÉÌÒÙÁÉÍÓÚÂÊÎÔÛÃÕÆØ]['
    r"0-9A-ZÀÈÉÌÒÙÁÉÍÓÚÂÊÎÔÛÃÕÇ&'’\.\-]{1,24})"  # vedette en capitales
    r'\s*,?\s*(' + NATURE + r')',
    re.UNICODE,
)
VERBAL = re.compile(r'^(?:tr|rifl|impers|intr|v\.[an]|tr\b|intr\b)', re.IGNORECASE)
SENS_SEP = re.compile(r'§')
CYRILLIQUES = str.maketrans({
    'а': 'a', 'е': 'e', 'о': 'o', 'р': 'p', 'с': 'c', 'у': 'y',
    'х': 'x', 'А': 'A', 'В': 'B', 'Е': 'E', 'К': 'K', 'М': 'M',
    'Н': 'H', 'О': 'O', 'Р': 'P', 'С': 'C', 'Т': 'T', 'У': 'Y', 'Х': 'X',
})


def nettoie(txt: str) -> str:
    txt = unicodedata.normalize('NFC', txt).translate(CYRILLIQUES)
    txt = re.sub(r'¬[ \t]*\n', '', txt)          # coupeure
    txt = re.sub(r'([a-zà-ÿ])-\s*\n\s*([a-zà-ÿ])', r'\1\2', txt)
    txt = re.sub(r'[ \t]+', ' ', txt)
    txt = re.sub(r'\n{2,}', '\n', txt)
    return txt


def _nettoie_sens(s: str) -> str:
    s = re.sub(r'\s+', ' ', s.replace('\n', ' ')).strip(' ;.,')
    # retire la citation finale entre ( )
    s = re.sub(r'\s\((?:T|Lat|P|prov|Bocc|Dant|Rèd|Cresc|L\.M)\.?[^)]*\)\s*$',
               '', s)
    return s.strip(' ;.,')


def parse(txt: str):
    articles = {}
    marqueurs = list(ARTICLE.finditer(txt))
    for i, m in enumerate(marqueurs):
        if not VERBAL.match(m.group(2)):
            continue
        vedette = m.group(1).strip('.,')
        fin = marqueurs[i + 1].start() if i + 1 < len(marqueurs) else len(txt)
        corps = txt[m.end():fin]
        sens = [_nettoie_sens(s) for s in SENS_SEP.split(corps)]
        sens = [s for s in sens if len(s) > 3]
        if not sens:
            continue
        vedette = vedette.lower().strip()
        articles.setdefault(vedette, [])
        articles[vedette].append(sens)
    return {v: [s for art in lst for s in art] for v, lst in articles.items()}


def main():
    dst = sys.argv[-1]
    res = {}
    for src in sys.argv[1:-1]:
        txt = nettoie(open(src, encoding='utf-8').read())
        for v, sens in parse(txt).items():
            res.setdefault(v, []).extend(sens)
    json.dump(res, open(dst, 'w', encoding='utf-8'), ensure_ascii=False)
    print('vedettes verbales :', len(res))
    for v in ('amare', 'cantare', 'essere', 'credere', 'leggere'):
        print(v, '->', res.get(v, [])[:2])
    print('OK')


if __name__ == '__main__':
    main()
