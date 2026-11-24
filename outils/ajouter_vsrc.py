# Ajoute les cles *_VSRC_STR dans brut.json : la liste, par langue, des verbes
# dont la conjugaison provient du Wiktionary (CC BY-SA 4.0). Les autres verbes
# proviennent du generateur maison du projet (MIT, donnees de depart du web).
#
#     node outils/extraire.js <web> outils/brut.json
#     node outils/extraire.js <web> outils/brut_orig.json   # extraction d'origine
#     python3 outils/ajouter_vsrc.py                          # injecte *_VSRC_STR
#     python3 outils/construire_bdd.py
#
# SPDX-License-Identifier: MIT
import json
import os

ICI = os.path.dirname(os.path.abspath(__file__))
CLES = [('fr', 'CONJ_VERBS_STR', 'fr'),
        ('en', 'EN_VERBS_STR', 'en'),
        ('es', 'ES_VERBS_STR', 'es'),
        ('de', 'DE_VERBS_STR', 'de'),
        ('it', 'IT_VERBS_STR', 'it'),
        ('pt', 'PT_VERBS_STR', 'pt')]


def noms(s):
    """Les noms de verbes d une chaine VERBS (lignes de tokens separes
    par des virgules ; chaque token : nom puis ':' radical...)."""
    out = []
    for l in s.split('\n'):
        for t in l.split(','):
            t = t.strip()
            if t:
                out.append(t.split(':')[0].strip())
    return out


def main():
    with open(os.path.join(ICI, 'brut.json'), encoding='utf-8') as f:
        brut = json.load(f)
    with open(os.path.join(ICI, 'brut_orig.json'), encoding='utf-8') as f:
        orig = json.load(f)
    for _, verbs, lg in CLES:
        anciens = set(noms(orig[verbs]))
        nouveaux = [v for v in noms(brut[verbs]) if v not in anciens]
        cle = '%s_VSRC_STR' % lg.upper()
        brut[cle] = '\n'.join(nouveaux)
        print('  %s : %d verbes du Wiktionary' % (lg, len(nouveaux)))
    with open(os.path.join(ICI, 'brut.json'), 'w', encoding='utf-8') as f:
        json.dump(brut, f, ensure_ascii=False, separators=(',', ':'))


if __name__ == '__main__':
    main()
