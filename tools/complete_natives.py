# Remplace, pour pl/cs/ro, les definitions anglaises par les definitions
# natives : Wiktionary monolingue (fichiers outils/native_<lg>*.json,
# extraction des dumps plwiktionary/cswiktionary/rowiktionary, CC BY-SA 4.0)
# ou, a defaut, la traduction du glossaire anglais du Wiktionary
# (fichiers outils/translated_<lg>*.json, traduction indiquee comme telle dans
# l etiquette de chaque definition).
# Usage : python3 outils/complete_natives.py [raw.json]
# SPDX-License-Identifier : MIT
import glob, html, json, os, re, sys

ICI = os.path.dirname(os.path.abspath(__file__))


def propre(t):
    """Défait les restes de wiki : entités, references, modeles orphelins."""
    t = t.replace('\n', ' ')
    while True:
        u = html.unescape(t)
        if u == t:
            break
        t = u
    t = re.sub(r'<ref[^>]*>.*?</ref>', '', t)
    t = re.sub(r'<ref[^>]*/?>', '', t)
    while re.search(r'\{\{[^{}]*\}\}', t):
        t = re.sub(r'\{\{[^{}]*\}\}', '', t)
    t = t.replace('{{', ' ').replace('}}', ' ')
    t = re.sub(r'\s+', ' ', t)
    return t.strip(' \xa0;,.-')
CLES = [('pl', 'PL_DEFS_STR', 'pl. Wiktionary'),
        ('cs', 'CS_DEFS_STR', 'cs. Wiktionary'),
        ('ro', 'RO_DEFS_STR', 'ro. Wiktionary')]
ETIQ_TRADUIT = {'pl': 'angl. Wiktionary, trad.',
               'cs': 'angl. Wiktionary, trad.',
               'ro': 'angl. Wiktionary, trad.'}


def charger(modele, source_etiq):
    """{mot: etiquette_source} pour chaque fichier correspondant."""
    out = {}
    for p in sorted(glob.glob(os.path.join(ICI, modele))):
        if os.path.basename(p).startswith(('native_', 'translated_')):
            with open(p, encoding='utf-8') as f:
                for mot, v in json.load(f).items():
                    out[mot] = (source_etiq,
                                propre(v['g'] if isinstance(v, dict) else v))
    return out


def remplacer(txt, mot, etiquette, gloss):
    ancien_ix = txt.find(mot + '\x01')
    if ancien_ix < 0:
        return None
    fin = txt.find('\x02', ancien_ix)
    fin = len(txt) if fin < 0 else fin
    ancien = txt[ancien_ix:fin]
    if ancien.split('\x01')[0] != mot:
        return None  # mot apparait en prefixe d un autre
    return txt[:ancien_ix] + mot + '\x01' + etiquette + '\x04' + gloss + txt[fin:]


def normaliser(txt, lg, wikt_defs):
    """Repare les definitions sans etiquette \x04 : natives du Wiktionary
    monolingue (presentes dans outils/wikt_defs.json) -> etiquette native ;
    anciens glossaires anglais annotes << (glossaire anglais du
    Wiktionary) >> -> etiquette anglaise, annotation retiree."""
    nat = wikt_defs.get(lg, {})
    parties = txt.split('\x02')
    for i, p in enumerate(parties):
        if not p or '\x04' in p:
            continue
        kv = p.split('\x01', 1)
        if len(kv) != 2:
            continue
        mot, val = kv
        if mot in nat:
            parties[i] = mot + '\x01' + lg + '. Wiktionary\x04' + propre(nat[mot])
        else:
            val = propre(val)
            parties[i] = mot + '\x01angl. Wiktionary\x04' + val
    return '\x02'.join(parties)


def main():
    chemin = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ICI, 'raw.json')
    with open(chemin, encoding='utf-8') as f:
        b = json.load(f)
    with open(os.path.join(ICI, 'wikt_defs.json'), encoding='utf-8') as f:
        wikt_defs = json.load(f)
    for lg, cle, etiq in CLES:
        natifs = charger('native_%s*.json' % lg, etiq)
        traduits = charger('translated_%s*.json' % lg, ETIQ_TRADUIT[lg])
        natifs.update(traduits)
        txt = b[cle]
        txt = normaliser(txt, lg, wikt_defs)
        n = 0
        for mot in sorted(natifs):
            e, g = natifs[mot]
            nouveau = remplacer(txt, mot, e, g)
            if nouveau is not None:
                txt = nouveau
                n += 1
        b[cle] = txt
        print('%s : %d definitions natives (%d traduites)'
              % (lg, n, len(traduits)))
    with open(chemin, 'w', encoding='utf-8') as f:
        json.dump(b, f, ensure_ascii=False, separators=(',', ':'))


if __name__ == '__main__':
    main()
