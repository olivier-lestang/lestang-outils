# Construit les cles RO_* de brut.json depuis outils/ro_ok.json
# (selection verbatim du Wiktionary via kaikki.org, CC BY-SA 4.0 ; code MIT).
# Token RO : nom:présent(6):imparfait(6):parfait(6):plus-que-parfait(6):
# subjonctif(6):impératif(2):participe:gérondif, champs ';'.
# SPDX-License-Identifier : MIT
import json, os

ICI = os.path.dirname(os.path.abspath(__file__))

def main():
    chemin = os.path.join(ICI, 'brut2.json')
    with open(chemin, encoding='utf-8') as f:
        b = json.load(f)
    with open(os.path.join(ICI, 'ro_ok.json'), encoding='utf-8') as f:
        ro = json.load(f)
    toks = []
    for w in sorted(ro):
        t = ro[w]
        toks.append(':'.join([w, t['P'], t['I'], t['R'], t['PQ'], t['S'],
                              t['IMP'], t['PP'], t['GER']]))
    b['RO_TPL_STR'] = ''
    b['RO_VERBS_STR'] = ','.join(toks)
    b['RO_DEFS_STR'] = '\u0002'.join(
        w + '\u0001angl. Wiktionary\u0004' + ro[w]['g'] for w in sorted(ro))
    b['RO_VSRC_STR'] = '\n'.join(sorted(ro))
    with open(chemin, 'w', encoding='utf-8') as f:
        json.dump(b, f, ensure_ascii=False, separators=(',', ':'))
    print('ro : %d verbes' % len(ro))

if __name__ == '__main__':
    main()
