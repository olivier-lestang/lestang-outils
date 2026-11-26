# Traduit dans la langue de conjugaison les gloses anglaises du
# Wiktionary restees en secours ( verbes sans article natif, cf.
# natifs_wikt.py ) :
#   1. lot manuel revu : fichiers outils/traduits_<lg>*.json
#      ( {verbe: [traductions des sens]} ), etiquette remplacee par
#      « angl. Wiktionary, trad. » ( traduction indiquee comme telle,
#      meme principe que pl/cs/ro ) ;
#   2. renvois automatiques : gloses de renvoi ( « alternative form
#      of X », « obsolete spelling of X »... ) traduites par motifs
#      revus, meme etiquette.
# Sont traites les sens issus du glossaire anglais ( id_source 1 )
# encore etiquetes « angl. Wiktionary » ou sans etiquette ( fr, es ).
# Les autres gloses restent anglaises jusqu'a leur lot.
# Usage :
#   python3 outils/traduire_wikt.py atelier.db [outils/] [--ecrire]
# Sans --ecrire : rapport. SPDX-License-Identifier : MIT
import glob
import json
import os
import re
import sqlite3
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
ETIQ = 'angl. Wiktionary, trad.'
JOUR = '2026-11-26'

# renvois : motif anglais -> gabarit par langue ( {} = vedette )
RENV = [
    (re.compile(r'^([Aa]lternative) (form|spelling) of ([\wäöüÄÖÜßà-ÿ-]+)', re.I),
     {'it': 'Forma alternativa di {}', 'pt': 'Forma alternativa de {}',
      'de': 'Alternative Form von {}', 'fr': 'Forme alternative de {}',
      'es': 'Forma alternativa de {}', 'ro': 'Formă alternativă a lui {}',
      'cs': 'Alternativní podoba slova {}'}),
    (re.compile(r'^([Oo]bsolete) (form|spelling) of ([\wäöüÄÖÜßà-ÿ-]+)', re.I),
     {'it': 'Grafia obsoleta di {}', 'pt': 'Grafia obsoleta de {}',
      'de': 'Veraltete Schreibweise von {}', 'fr': 'Graphie obsolète de {}',
      'es': 'Grafía obsoleta de {}', 'ro': 'Grafie învechită a lui {}',
      'cs': 'Zastaralý pravopis slova {}'}),
    (re.compile(r'^(Formerly standard|Former) (spelling|form) of ([\wäöüÄÖÜßà-ÿ-]+)', re.I),
     {'it': 'Grafia un tempo standard di {}', 'pt': 'Grafia outrora padronizada de {}',
      'de': 'Frühere Schreibweise von {}', 'fr': 'Graphie autrefois standard de {}',
      'es': 'Grafía antes estándar de {}', 'ro': 'Grafie odinioară standard a lui {}',
      'cs': 'Dříve standardní pravopis slova {}'}),
    (re.compile(r'^(Switzerland and Liechtenstein standard) (spelling|form) of ([\wäöüÄÖÜßà-ÿ-]+)', re.I),
     {'de': 'Schweizer und liechtensteinische Schreibweise von {}'}),
    (re.compile(r'^(European Portuguese standard) (spelling|form) of ([\wäöüÄÖÜßà-ÿ-]+)', re.I),
     {'pt': 'Forma da norma europeia de {}'}),
    (re.compile(r'^(Brazilian Portuguese standard) (spelling|form) of ([\wäöüÄÖÜßà-ÿ-]+)', re.I),
     {'pt': 'Forma da norma brasileira de {}'}),
    (re.compile(r'^(archaic or dialectal) (form|spelling) of ([\wäöüÄÖÜßà-ÿ-]+)', re.I),
     {'it': 'Forma arcaica o dialettale di {}', 'pt': 'Forma arcaica ou dialectal de {}',
      'de': 'Archaïsche oder mundartliche Form von {}',
      'fr': 'Forme archaïque ou dialectale de {}', 'es': 'Forma arcaica o dialectal de {}',
      'ro': 'Formă arhaică sau dialectală a lui {}',
      'cs': 'Archaická nebo nářeční podoba slova {}'}),
    (re.compile(r'^(archaic) (form|spelling) of ([\wäöüÄÖÜßà-ÿ-]+)', re.I),
     {'it': 'Forma arcaica di {}', 'pt': 'Forma arcaica de {}',
      'de': 'Archaïsche Form von {}', 'fr': 'Forme archaïque de {}',
      'es': 'Forma arcaica de {}', 'ro': 'Formă arhaică a lui {}',
      'cs': 'Archaická podoba slova {}'}),
    (re.compile(r'^(dated) (form|spelling) of ([\wäöüÄÖÜßà-ÿ-]+)', re.I),
     {'it': 'Forma datata di {}', 'pt': 'Forma datada de {}',
      'de': 'Veraltete Form von {}', 'fr': 'Forme datée de {}',
      'es': 'Forma anticuada de {}', 'ro': 'Formă învechită a lui {}',
      'cs': 'Zastaralá podoba slova {}'}),
    (re.compile(r'^(rare) (form|spelling) of ([\wäöüÄÖÜßà-ÿ-]+)', re.I),
     {'it': 'Forma rara di {}', 'pt': 'Forma rara de {}',
      'de': 'Seltene Form von {}', 'fr': 'Forme rare de {}',
      'es': 'Forma rara de {}', 'ro': 'Formă rară a lui {}',
      'cs': 'Vzácná podoba slova {}'}),
    (re.compile(r'^(nonstandard) (form|spelling) of ([\wäöüÄÖÜßà-ÿ-]+)', re.I),
     {'it': 'Grafia non standard di {}', 'pt': 'Grafia não convencional de {}',
      'de': 'Nicht standardisierte Schreibweise von {}',
      'fr': 'Graphie non standard de {}', 'es': 'Grafía no estándar de {}',
      'ro': 'Grafie nestandardizată a lui {}',
      'cs': 'Nestandardní podoba slova {}'}),
    (re.compile(r'^(eye dialect) (spelling|form) of ([\wäöüÄÖÜßà-ÿ-]+)', re.I),
     {'it': 'Grafia fonetica di {}', 'pt': 'Grafia fonética de {}',
      'de': 'Umgangssprachliche Schreibweise von {}',
      'fr': 'Graphie populaire de {}', 'es': 'Grafía popular de {}',
      'ro': 'Grafie populară a lui {}',
      'cs': 'Lidový pravopis slova {}'}),
    (re.compile(r'^(pronunciation) (spelling|form) of ([\wäöüÄÖÜßà-ÿ-]+)', re.I),
     {'it': 'Grafia secondo la pronuncia di {}', 'pt': 'Grafia de acordo com a pronúncia de {}',
      'de': 'Lautgetreue Schreibweise von {}', 'fr': 'Graphie phonétique de {}',
      'es': 'Grafía según la pronunciación de {}',
      'ro': 'Grafie fonetică a lui {}',
      'cs': 'Pravopis podle výslovnosti slova {}'}),
    (re.compile(r'^(proscribed) (spelling|form) of ([\wäöüÄÖÜßà-ÿ-]+)', re.I),
     {'it': 'Grafia sconsigliata di {}', 'pt': 'Grafia desaconselhada de {}',
      'de': 'Verbotene Schreibweise von {}', 'fr': 'Graphie déconseillée de {}',
      'es': 'Grafía desaconsejada de {}', 'ro': 'Grafie nerecomandată a lui {}',
      'cs': 'Nedoporučený pravopis slova {}'}),
    (re.compile(r'^(Old Italian) (form|spelling) of ([\wäöüÄÖÜßà-ÿ-]+)', re.I),
     {'it': "Forma dell'italiano antico di {}"}),
    (re.compile(r'^(syncopic) (form|spelling) of ([\wäöüÄÖÜßà-ÿ-]+)', re.I),
     {'it': 'Forma sincopica di {}'}),
    (re.compile(r'^(apheretic) (form|spelling) of ([\wäöüÄÖÜßà-ÿ-]+)', re.I),
     {'it': 'Forma aferetica di {}'}),
    (re.compile(r'^(regional) (form|spelling) of ([\wäöüÄÖÜßà-ÿ-]+)', re.I),
     {'it': 'Forma regionale di {}', 'pt': 'Forma regional de {}',
      'ro': 'Formă regională a lui {}', 'cs': 'Regionální podoba slova {}'}),
    (re.compile(r'^(Madeira) (form|spelling) of ([\wäöüÄÖÜßà-ÿ-]+)', re.I),
     {'pt': 'Forma da Madeira de {}'}),
    (re.compile(r'^([Ss]ynonym) of ([\wäöüÄÖÜßà-ÿ-]+)', ),
     {'it': 'Sinonimo di {}', 'pt': 'Sinônimo de {}', 'de': 'Synonym von {}',
      'fr': 'Synonyme de {}', 'es': 'Sinónimo de {}',
      'ro': 'Sinonim al lui {}', 'cs': 'Synonymum k {}'}),
    (re.compile(r'^([Rr]eflexive) of ([\wäöüÄÖÜßà-ÿ-]+)$'),
     {'it': 'Forma riflessiva di {}'}),
]

MOTS = (
    "SELECT DISTINCT pos, verbe FROM defs WHERE langue=? AND id_source=1 "
    "AND (etiquette='angl. Wiktionary' OR etiquette IS NULL)")
SENS = (
    'SELECT rang, texte, date_ajout FROM defs WHERE langue=? AND verbe=? '
    'AND id_source=1 AND (etiquette=\'angl. Wiktionary\' OR etiquette '
    'IS NULL) ORDER BY rang')
EFFACE = (
    'DELETE FROM defs WHERE langue=? AND pos=? AND verbe=? AND '
    'id_source=1 AND (etiquette=\'angl. Wiktionary\' OR etiquette '
    'IS NULL)')


def trad_renvoi(texte, lg):
    for pat, gab in RENV:
        m = pat.match(texte)
        if m:
            if lg in gab:
                return gab[lg].format(m.group(m.lastindex))
            return None       # motif connu mais pas pour cette langue
    return None


def main():
    ecrire = '--ecrire' in sys.argv
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    atelier = args[0] if args else os.path.join(ICI, 'atelier.db')
    dossier = args[1] if len(args) > 1 else ICI
    manuel = {}
    for p in sorted(glob.glob(os.path.join(dossier, 'traduits_*.json'))):
        lg = os.path.basename(p)[len('traduits_'):-len('.json')][:2]
        manuel.setdefault(lg, {})
        manuel[lg].update(json.load(open(p, encoding='utf-8')))

    db = sqlite3.connect(atelier)
    idt = {n: i for i, n in db.execute(
        'SELECT id, nom FROM sources')}.get(ETIQ)
    if idt is None:
        cur = db.execute(
            'INSERT INTO sources(nom, caract) VALUES(?,?)',
            (ETIQ, 'Glossaire anglais du Wiktionary traduit par le '
             'projet (traductions en cours, CC BY-SA 4.0)'))
        idt = cur.lastrowid

    rapport = {}
    tidy = []      # (lg, pos, verbe, rang, etiquette, texte, id)
    n_man = n_ren = 0
    for lg in ('fr', 'es', 'it', 'pt', 'de', 'pl', 'cs', 'ro'):
        for pos, v in db.execute(MOTS, (lg,)):
            rows = list(db.execute(SENS, (lg, v)))
            if not rows:
                continue
            date = rows[0][2] or JOUR
            nouv = None
            if v in manuel.get(lg, {}):
                nouv = [(rg, ETIQ, g)
                        for rg, g in zip((r[0] for r in rows),
                                         manuel[lg][v])]
                n_man += len(nouv)
            else:
                trads = [(r[0], ETIQ, trad_renvoi(r[1], lg)) for r in rows]
                trads = [t for t in trads if t[2]]
                if trads and len(trads) == len(rows):
                    nouv = trads          # tous les sens sont des renvois
                    n_ren += len(nouv)
            if not nouv:
                continue          # pas encore traduit : reste en anglais
            rapport.setdefault(lg, [0, 0])
            rapport[lg][0] += 1
            rapport[lg][1] += len(nouv)
            for rg, et, tx in nouv:
                tidy.append((lg, pos, v, rg, et, tx, date))
    print('verbes traduits (manuel+renvois) :', json.dumps(rapport),
          flush=True)
    if not ecrire:
        print('mode : lecture seule')
        db.close()
        return
    ok = 0
    for lg, pos, v, rg, et, tx, date in tidy:
        db.execute(EFFACE, (lg, pos, v))
        db.execute('INSERT INTO defs VALUES(?,?,?,?,?,?,?,?)',
                   (lg, pos, rg, v, et, tx, idt, date))
        ok += 1
    db.commit()
    print('sens traduits ecrits : %d' % ok)
    print('sens sans source :', db.execute(
        'SELECT COUNT(*) FROM defs WHERE id_source IS NULL').fetchone()[0])
    db.close()


if __name__ == '__main__':
    main()
