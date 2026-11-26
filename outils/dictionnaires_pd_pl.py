# Comble les definitions polonaises avec le dictionnaire du domaine
# public ( deja numerise et OCRe par archive.org, fichiers djvu.txt
# d importe directement — pas d OCR local necessaire ) :
#   pl : Slownik jezyka polskiego dit « Slownik warszawski »
#        ( Jan Karlowicz, Adam Krynski, Wladyslaw Niedzwiedzki,
#        1900-1927, 8 vol., domaine public ), items archive.org
#        sownikjzykapolsk01..08karo.
# Pour chaque verbe de l atelier trouve comme vedette ( formes
# pronominales « ...sc sie » gardees telles quelles ), les sens
# « angl. Wiktionary » sont REMPLACES par les extraits du
# dictionnaire ( 1 a 3 sens ou un renvoi « p. X » ), etiquette et
# source = nom du dictionnaire. Les verbes avec definition native
# du Wiktionary polonais ne sont pas touches ; les verbes non
# couverts restent inchanges ( glossaire angl. Wiktionary,
# a traduire plus tard ).
# L OCR de ces scans comporte des coquilles : elles sont conservees
# telles quelles ; une passe de correction manuelle reste possible
# dans l atelier ( cf. coquilles_ocr.py ).
# Usage :
#   python3 outils/dictionnaires_pd_pl.py [atelier.db] [t01.txt t02.txt
#           t03.txt t04.txt t05.txt t06.txt t07.txt t08.txt] [--ecrire]
# Sans --ecrire : tour a blanc avec chiffres et extraits.
# SPDX-License-Identifier : MIT
import re
import sqlite3
import sys

SLOWNIK = 'Słownik warszawski 1900'
JOUR = '2026-11-26'

# vedette : ligne commencant par un infinitif en -c, suivi d une
# virgule ou d un code de flexion ( « się », « uje »... )
VED = re.compile(
    r'(?m)^([A-ZĄĆĘŁŃÓŚŹŻ][a-ząćęłńóśźż]{2,}ć)\s*,'
    r'|^([A-ZĄĆĘŁŃÓŚŹŻ][a-ząćęłńóśźż]{2,}ć)\s+(?:się|I,|uję|uje|ował)\b')
# codes de flexion a retirer en tete du corps
CODES = ('się', 'uje', 'uję', 'ował', 'owal', 'owa', 'uje', 'al', 'a',
         'ę', 'aję', 'i', 'I', 'II', 'III', 'IV', 'V', 'X', 'p.',
         'dk.', 'ndk.', 'ż.', 'z.', 'w.', 'od.')
# renvoi « p. Dopierać » ( patrz = voir )
RENV = re.compile(r'\bp\.\s*[A-ZĄĆĘŁŃÓŚŹŻ][a-ząćęłńóśźż]{2,}ć\b')


def rassemble(morceaux):
    t = ' '.join(morceaux)
    t = t.replace('¬ ', '').replace('¬', '')
    t = re.sub(r'(\w)-\s*\n\s*(\w)', r'\1\2', t)   # coupure ligne OCR
    t = re.sub(r'\s*\n\s*', ' ', t)
    t = re.sub(r'\s+', ' ', t).strip()
    t = re.sub(r'\s+([,.;:!?])', r'\1', t)
    return t


def sens_slownik(t, cibles, max_sens=3):
    """Extraits pour les vedettes cibles ( ensemble minuscules )."""
    out = []          # (vedette, [sens...]) ; ordre de premiere rencontre
    vus = {}
    marks = [(m.start(1) if m.group(1) else m.start(2),
              m.group(1) or m.group(2)) for m in VED.finditer(t)]
    for j, (p, w) in enumerate(marks):
        fin = marks[j + 1][0] if j + 1 < len(marks) else min(p + 3000,
                                                             len(t))
        vedette = w.lower()
        if vedette not in cibles:
            continue
        bloc = re.split(r'\n\s*\n', t[p:fin])[0]   # 1er paragraphe
        corps = re.sub(r'(?s)\[[^\]]*\]', ' ', bloc)   # [ ... ]
        ap = re.sub(r'^\S+?(?:,|\s)\s*', '', corps, count=1, flags=re.S)
        lignes = rassemble([ap]).split(' ')
        # retirer les codes de flexion en tete ( jusqu a 6 tokens )
        k = 0
        while k < len(lignes) and k < 6 and lignes[k].strip(',.') \
                in CODES:
            k += 1
        ap = ' '.join(lignes[k:])
        vedette = w.lower()
        nouv = []
        # renvoi court « p. X » : sens unique
        if len(ap) < 60:
            m = RENV.search(ap)
            if m and vedette not in vus:
                vus[vedette] = len(out)
                out.append((vedette, [m.group(0) + '.']))
                continue
        # couper aux numeros de sens « 2. », « II. »
        blocs = re.split(r'\s(?:2|II)\.\s', ap, maxsplit=2)
        for b in blocs[:max_sens]:
            s = re.split(r':\s', b)[0]                     # exemples
            s = re.split(r'(?<=[a-zżźćąśłęóńą])\.\s', s)[0]
            s = re.sub(r'\s*\bp\.\s*[A-ZĄĆĘŁŃÓŚŹŻ]'
                       r'[a-ząćęłńóśźż]{2,}ć\S*\s*$', '', s).strip(' ,;.-')
            # lisibilite : >= 80 % de lettres polonaises ( coquilles OCR
            # graves comme « \B,^ » ou « l'mi('iać> » rejetees )
            ok = re.sub(r'[^a-ząćęłńóśźżA-ZĄĆĘŁŃÓŚŹŻ,.;= ]', '', s)
            if len(s) >= 20 and len(s.split()) >= 3 \
                    and len(ok) >= 0.8 * len(s):
                nouv.append(s.rstrip('.') + '.')
        if not nouv:
            continue
        if vedette not in vus:
            vus[vedette] = len(out)
            out.append((vedette, nouv[:max_sens]))
        else:
            e = out[vus[vedette]]
            for s in nouv[:max_sens]:
                if len(e[1]) < max_sens:
                    e[1].append(s)
    return out


def main():
    ecrire = '--ecrire' in sys.argv
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    atelier = args[0] if args else 'atelier.db'
    tomes = args[1:] or ['t%02d.txt' % i for i in range(1, 9)]

    db = sqlite3.connect(atelier)
    cibles = {v for (v,) in db.execute(
        "SELECT v.verbe FROM verbes v WHERE v.langue='pl' AND "
        "v.verbe NOT IN (SELECT verbe FROM defs WHERE langue='pl' "
        "AND etiquette='pl. Wiktionary')")}
    extraits = {}
    for tome in tomes:
        for vedette, sens in sens_slownik(
                open(tome, encoding='utf-8', errors='replace').read(),
                cibles):
            if vedette not in extraits:
                extraits[vedette] = sens
            else:
                for s in sens:
                    if len(extraits[vedette]) < 3:
                        extraits[vedette].append(s)
    print('vedettes verbales Slownik warszawski : %d (cibles: %d)'
          % (len(extraits), len(cibles)))

    deja = {n for (n,) in db.execute('SELECT nom FROM sources')}
    caract = ('Jan Karłowicz, Adam Kryński, Władysław Niedźwiedzki, '
              'Słownik języka polskiego dit « Słownik warszawski » '
              '( 1900-1927, 8 vol. ), domaine public ; numerisation '
              'archive.org, OCR conserve tel quel')
    if SLOWNIK not in deja:
        db.execute('INSERT INTO sources(nom, caract) VALUES(?,?)',
                   (SLOWNIK, caract))
    id_s = {n: i for i, n in db.execute('SELECT id, nom FROM sources')}
    bilans, exemples = {}, []
    for (verbe,) in db.execute(
            "SELECT v.verbe FROM verbes v WHERE v.langue='pl' "
            "AND v.verbe NOT IN (SELECT verbe FROM defs WHERE "
            "langue='pl' AND etiquette='pl. Wiktionary') "
            'GROUP BY v.verbe'):
        senss = extraits.get(verbe)
        if not senss:
            continue
        if not ecrire:
            if len(exemples) < 8:
                exemples.append('pl %s : %s' % (verbe,
                                                ' | '.join(senss)[:110]))
            bilans[SLOWNIK] = bilans.get(SLOWNIK, 0) + 1
            continue
        db.execute("DELETE FROM defs WHERE langue='pl' AND verbe=? "
                   "AND etiquette='angl. Wiktionary'", (verbe,))
        pos = db.execute('SELECT COALESCE(MAX(pos),-1)+1 FROM defs '
                         "WHERE langue='pl'").fetchone()[0]
        for rg, sens in enumerate(senss):
            db.execute('INSERT INTO defs VALUES(?,?,?,?,?,?,?,?)',
                       ('pl', pos, rg, verbe, SLOWNIK, sens,
                        id_s[SLOWNIK], JOUR))
        bilans[SLOWNIK] = bilans.get(SLOWNIK, 0) + 1
    if ecrire:
        db.commit()
    db.close()
    for nom, n in sorted(bilans.items()):
        print('%-24s %5d verbes remplacés' % (nom, n))
    for e in exemples:
        print('   ', e)
    print('mode : %s' % ('ECRITURE' if ecrire else 'lecture seule'))


if __name__ == '__main__':
    main()
