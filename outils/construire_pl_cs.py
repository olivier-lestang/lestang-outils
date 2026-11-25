# Construit les cles PL_*/CS_* de brut.json depuis les listes deja verifiees
# outils/pl_ok.json et outils/cs_ok.json (sorties du generateur-vérificateur
# kaiki/wiktextract, CC BY-SA 4.0 pour les donnees ; code MIT).
# Les formes de byc/iscbyt sont codees dans le moteur Dart (moteurs.dart).
# SPDX-License-Identifier: MIT
import json, os

ICI = os.path.dirname(os.path.abspath(__file__))


def str_verbes(ok, tcheque):
    toks = []
    for w in sorted(ok):
        t = ok[w]['t']
        c = ([w, t['s1'], t['p3'], t['W'], t['V'], t['imp2'], t['asp']]
             if not tcheque else
             [w, t['s1'], t['s3'], t['p3'], t['W'], t['V'], t['imp2'],
              t['asp']])
        toks.append(':'.join(c))
    return ','.join(toks)


def defs(ok):
    return '\u0002'.join(
        w + '\u0001angl. Wiktionary\u0004' + ok[w]['g']
        for w in sorted(ok) if ok[w].get('g'))


def toks_exceptions(ex, tcheque):
    # Token explicite : toutes les formes copiees verbatim du Wiktionary.
    # PL  w:E:ind(6 ';'):passe(13 ';'):imp(3 ';'):asp
    # CS  w:E:ind(6 ';'):W:V:imp(3 ';'):asp
    toks = []
    for w in sorted(ex):
        t = ex[w]
        if tcheque:
            # CS  w:E:ind(6 ';'):W:V:imp(3 ';'):asp
            c = [w, 'E', t['ind'], t['W'], t['V'], t['imp'], t['asp']]
        else:
            # PL  w:E:ind(6 ';'):passe(13 ';'):imp(3 ';'):asp
            c = [w, 'E', t['ind'], t['past'], t['imp'], t['asp']]
        toks.append(':'.join(c))
    return ','.join(toks)


def defs_exceptions(ex):
    return '\u0002'.join(
        w + '\u0001angl. Wiktionary\u0004' + ex[w]['g']
        for w in sorted(ex) if ex[w].get('g'))


def main():
    chemin = os.path.join(ICI, 'brut.json')
    with open(chemin, encoding='utf-8') as f:
        b = json.load(f)
    with open(os.path.join(ICI, 'pl_ok.json'), encoding='utf-8') as f:
        pl = json.load(f)
    with open(os.path.join(ICI, 'cs_ok.json'), encoding='utf-8') as f:
        cs = json.load(f)
    with open(os.path.join(ICI, 'pl_exc.json'), encoding='utf-8') as f:
        plex = json.load(f)
    with open(os.path.join(ICI, 'cs_exc.json'), encoding='utf-8') as f:
        csex = json.load(f)
    b['PL_TPL_STR'] = ''
    b['PL_VERBS_STR'] = (str_verbes(pl, False) + ',być::::::,iść::::::,'
                         + toks_exceptions(plex, False))
    b['PL_DEFS_STR'] = '\u0002'.join(
        x for x in (defs(pl), defs_exceptions(plex)) if x)
    b['PL_VSRC_STR'] = '\n'.join(sorted(pl)) + '\nbyć\niść\n' + '\n'.join(sorted(plex))
    b['CS_TPL_STR'] = ''
    b['CS_VERBS_STR'] = (str_verbes(cs, True) + ',být:::::::,'
                         + toks_exceptions(csex, True))
    b['CS_DEFS_STR'] = '\u0002'.join(
        x for x in (defs(cs), defs_exceptions(csex)) if x)
    b['CS_VSRC_STR'] = '\n'.join(sorted(cs)) + '\nbýt\n' + '\n'.join(sorted(csex))
    with open(chemin, 'w', encoding='utf-8') as f:
        json.dump(b, f, ensure_ascii=False, separators=(',', ':'))
    print('pl : %d verbes (%d exceptions), cs : %d verbes (%d exceptions)'
          % (len(pl) + len(plex), len(plex), len(cs) + len(csex), len(csex)))


if __name__ == '__main__':
    main()
