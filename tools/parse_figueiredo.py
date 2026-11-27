#!/usr/bin/env python3
"""Extrait les définitions verbales du « Novo Diccionario da Lingua Portugueza »
de Cândido de Figueiredo (1913, domaine public), OCR Internet Archive
(item DicionrioDeL.P1913, fichier « Dicionário de L.P 1913_djvu.txt »).

Usage : python3 parse_figueiredo.py figueiredo.txt figueiredo_verbes.json
Sortie : {vedette: [sens1, sens2, ...]}
"""
import json
import re
import sys
import unicodedata

NATURE = (
    r'(?:v|r|s|adj|adv|m|f|prep|pron|interj|num|part)\.'  # « r. » = OCR de « v. »
    r'(?:\s*(?:t|i|n|m|f|pl|mctors?\b|fem|[a-z]+))*'
)
# vedette : lettres minuscules (après NFC), éventuellement avec trait d'union,
# homographe « ,1 », ou pronom « , (si) », et astérisque de registre
ARTICLE = re.compile(
    r'(?:^|[.;:!?»)]\s+|\n\s*)'
    r'([^\W\d_]+(?:-[^\W\d_]+)*)(?:,?\s?\d)?(?:,?\s*\([^)]{0,15}\))?'
    r'\s*\**\s+(' + NATURE + r')',
    re.IGNORECASE | re.UNICODE,
)
VERBAL = re.compile(r'^[vr]\b', re.IGNORECASE)
ETYMOLOGIE = re.compile(
    r'\s*\((?:Lat\.?|Do lat\.?|De lat\.?|D[eo]\b|De |Deriv|Forma|Gr\.?'
    r'Arab|Germ|Ingl|Fr\.?|Prov|Gal|Cast|hisp|orig|Provençal|do gr|do arab|'
    r'do cast|do fr|do ingl|do germ|do lat[^)]*)[^)]*\)\s*$'
)
SENS_SEP = re.compile(
    # OCR « V. i. n. » → « Vin. » ; séparateurs de sens et étoiles de registre
    r'(?:\s(?:V|v)\.\s(?:t|i)\.\s)|(?:\.\s(?:V|v)\.\s(?:t|i|n|p)\.\s)'
    r'|(?:\n?\s?(?:V|v)in\.\s)|(?:\*\*?\s)'
)


ETY_SENS = re.compile(
    r'\s*\((?:Lat\.?|Do lat\.?|De lat\.?|D[eo]\b|Do gr|Do arab|Do cast|Do fr|'
    r'Do ingl|Do germ|De |Deriv|Forma|Gr\.?|Arab|Germ|Ingl|Fr\.?|Prov|Gal|'
    r'Cast|orig)[^)]*\)?\s*$', re.IGNORECASE,
)


def _nettoie_sens(s: str) -> str:
    s = re.sub(r'\s+', ' ', s).strip(' ;.,')
    s = ETY_SENS.sub('', s)
    return s.strip(' ;.,')


def nettoie(txt: str) -> str:
    txt = unicodedata.normalize('NFC', txt)
    txt = txt.replace('¬ \n', '').replace('¬\n', '')
    # trait d'union de fin de ligne
    txt = re.sub(r'([^\W\d_])-\s*\n\s*([^\W\d_])', r'\1\2', txt, flags=re.UNICODE)
    txt = re.sub(r'[ \t]+', ' ', txt)
    txt = re.sub(r'\n{2,}', '\n', txt)
    return txt


def coupe_etym(article: str) -> str:
    """Retire l'étymologie finale entre parenthèses."""
    m = ETYMOLOGIE.search(article.rstrip())
    if m and '(' not in m.group(0).strip()[1:]:
        return article[: m.start()].rstrip()
    return article.rstrip()


def parse(txt: str):
    articles: dict[str, list] = {}
    marqueurs = list(ARTICLE.finditer(txt))
    for i, m in enumerate(marqueurs):
        if not VERBAL.match(m.group(2)):
            continue
        vedette = m.group(1)
        fin = marqueurs[i + 1].start() if i + 1 < len(marqueurs) else len(txt)
        corps = txt[m.end():fin]
        # coupe dès qu'une nouvelle vedette NON verbale apparaît en fin d'article
        corps = coupe_etym(corps)
        # sépare les sens
        sens = [_nettoie_sens(s) for s in SENS_SEP.split(corps)]
        sens = [s for s in sens if len(s) > 3]
        if not sens:
            continue
        articles.setdefault(vedette, [])
        articles[vedette].append(sens)
    # aplatir les articles multiples en une seule liste de sens
    return {v: [s for art in lst for s in art] for v, lst in articles.items()}, \
        {v: [s for art in lst for s in art for s in [s]] and len(lst) for v, lst in articles.items()}


def main():
    src, dst = sys.argv[1], sys.argv[2]
    txt = nettoie(open(src, encoding='utf-8').read())
    dico, _ = parse(txt)
    json.dump(dico, open(dst, 'w', encoding='utf-8'), ensure_ascii=False)
    print('vedettes verbales :', len(dico))
    for v in ('falar', 'custodiar', 'agir', 'abafar'):
        print(v, '->', dico.get(v, [])[:3])
    print('OK')


if __name__ == '__main__':
    main()
