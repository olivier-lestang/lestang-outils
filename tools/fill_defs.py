# -*- coding: utf-8 -*-
"""Comble les verbes sans définition avec les définitions du Wiktionary
monolingue (ou, à défaut, le glossaire anglais du Wiktionary anglophone),
et retire les verbes qu'aucun Wiktionary ne définit comme verbe.
Usage : python3 fill_defs.py raw.json wikt_defs.json retires.json raw.json
SPDX-License-Identifier: MIT."""
import base64, gzip, json, sys

DEFKEY = {'fr': 'CONJ_DEFS_B64', 'en': 'EN_DEFS_B64', 'es': 'ES_DEFS_B64',
          'pl': 'PL_DEFS_STR', 'cs': 'CS_DEFS_STR'}
VERBS = {'fr': 'CONJ_VERBS_STR', 'en': 'EN_VERBS_STR', 'es': 'ES_VERBS_STR',
         'pl': 'PL_VERBS_STR', 'cs': 'CS_VERBS_STR'}
B64 = {'fr', 'en', 'es'}

def lire_defs(brut, lg):
    k = DEFKEY[lg]
    t = brut[k]
    return (gzip.decompress(base64.b64decode(t)).decode()
            if lg in B64 else t)

def ecrire_defs(brut, lg, txt):
    k = DEFKEY[lg]
    brut[k] = (base64.b64encode(gzip.compress(txt.encode())).decode()
               if lg in B64 else txt)

def main():
    src, defs_f, ret_f, dst = sys.argv[1:5]
    brut = json.load(open(src, encoding='utf-8'))
    defs = json.load(open(defs_f, encoding='utf-8'))
    retires = json.load(open(ret_f, encoding='utf-8'))
    toc = 0
    tro = 0
    for lg in ['fr', 'en', 'es', 'pl', 'cs']:
        # 1. retrait des verbes non définis par le Wiktionary
        out = set(retires.get(lg, []))
        if out:
            nouv = []
            for ligne in brut[VERBS[lg]].split('\n'):
                gardes = []
                for tok in ligne.split(','):
                    nom = tok.split(':')[0]
                    if nom in out:
                        tro += 1
                    else:
                        gardes.append(tok)
                if gardes:
                    nouv.append(','.join(gardes))
            brut[VERBS[lg]] = '\n'.join(nouv)
            vsrc = brut.get('%s_VSRC_STR' % lg.upper(), '')
            if vsrc:
                brute = [v for v in vsrc.split('\n') if v and v not in out]
                brut['%s_VSRC_STR' % lg.upper()] = '\n'.join(brute)
        # 2. ajout ou remplacement des définitions (les entrées à
        # valeur vide, qui existent parfois, sont écrasées)
        txt = lire_defs(brut, lg)
        parties = [p for p in txt.split('\x02') if p]
        carte = {}
        ordre = []
        for p in parties:
            kv = p.split('\x01', 1)
            if len(kv) != 2:
                continue
            if kv[0] not in carte:
                ordre.append(kv[0])
            carte[kv[0]] = kv[1]
        for mot, df in sorted(defs.get(lg, {}).items()):
            if mot not in carte:
                ordre.append(mot)
            carte[mot] = df
            toc += 1
        txt = '\x02'.join(m + '\x01' + carte[m] for m in ordre)
        ecrire_defs(brut, lg, txt)
    print('définitions ajoutées :', toc, '; verbes retirés :', tro)
    json.dump(brut, open(dst, 'w', encoding='utf-8'), ensure_ascii=False)

if __name__ == '__main__':
    main()
