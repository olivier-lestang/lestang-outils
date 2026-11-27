# Remplace, pour l'italien et le portugais, les definitions par celles
# des dictionnaires du domaine public ( deja numerises et OCrés par
# archive.org, fichiers djvu.txt — pas d OCR local necessaire ) :
#   it : Petrocchi, Novo dizionario universale della lingua italiana
#        ( 1887, Policarpo Petrocchi 1852-1902, domaine public ),
#        2 volumes, items novodizionarioun01/02petruoft.
#   pt : Cândido de Figueiredo, Novo Diccionário da Língua Portuguesa
#        ( 1913, domaine public ), item DicionrioDeL.P1913.
# Pour chaque verbe trouve comme vedette ( formes pronominales
# ramenees a leur base pour l italien ), les sens existants sont
# REMPLACES par les extraits du dictionnaire ( 1 a 3 sens ), etiquette
# et source = nom du dictionnaire. Verbes non couverts : inchangés
# ( glossaire angl. Wiktionary / générateur, a traduire plus tard ).
# L'OCR de ces scans comporte des coquilles ( surtout Petrocchi ) :
# elles sont conservées telles quelles ; une passe de correction
# manuelle reste possible dans l'atelier.
# Usage :
#   python3 outils/dictionaries_pd.py [workshop.db] [petrocchi1.txt]
#           [petrocchi2.txt] [figueiredo.txt] [--ecrire]
# Sans --ecrire : tour a blanc avec chiffres et extraits.
# SPDX-License-Identifier : MIT
import re
import sqlite3
import sys

PETROCCHI = 'Petrocchi 1887'
FIGUEIREDO = 'Figueiredo 1913'
POS_VERB = re.compile(
    r'^(tr\.|intr\.|v\.|tr\. e intr\.|intr\. e tr\.|v\. a\.|v\. n\.|'
    r'v\. t\.|v\. i\.|v\. t\. e i\.|v\. i\. e t\.)')

# clitiques pronominaux italiennes : abbandonarsi -> abbandonare
CLIT_IT = ('rsi', 'rci', 'rvi', 'rmi', 'rti', 'rne', 'rsela', 'rselo',
           'rsene', 'rcela', 'rcelo', 'rcene', 'rela', 'relo', 'rene')
CLIT_ES = ('rse', 'rnos', 'rte', 'rme', 'rlo', 'rla', 'rles', 'rlos',
           'rlas', 'rle', 'rne')


def base_pronominale(verbe, clitiques):
    for cl in sorted(clitiques, key=len, reverse=True):
        if verbe.endswith(cl) and len(verbe) > len(cl) + 3:
            return verbe[:-len(cl)] + 'e'
    return verbe


def rassemble(morceaux):
    t = ' '.join(morceaux)
    t = t.replace('¬ ', '').replace('¬', '')
    t = re.sub(r'(\w)-\s*\n?\s*(\w)', r'\1\2', t)   # coupure ligne OCR
    t = re.sub(r'\s+', ' ', t).strip()
    t = re.sub(r'\s+([,.;:!?])', r'\1', t)
    return t


def sens_petrocchi(t, max_sens=3):
    """Une vedette = 'PAROLA, tr. Definition. ( exemples § ... )' :
    on garde la premiere phrase reelle, hors notes [ ... ] et hors
    sections d exemples '§'."""
    out = []
    for m in re.finditer(
            r'(?ms)^([A-ZÀ-Ù][A-ZÀ-Ù\'’]{2,})\s*,\s*'
            r'((?:tr\.|intr\.|v\.|tr\. e intr\.|intr\. e tr\.).*?)'
            r'(?=\n\s*\n)', t):
        vedette = m.group(1).lower()
        apres = m.group(2)
        # pos etendus : 'tr. e ass.', 'tr. e pron.', 'v.', 'rifl.'...
        apres = re.sub(r"^(?:[a-zà-ÿ]{1,5}\.(?:\s+e\s+)?\s*)+", '', apres)
        apres = re.sub(r'\[[^\]]*\]', ' ', apres)     # notes de conjug.
        apres = re.sub(r'(?:T\.|ret\.|volg\.|cont\.| stor\.)\s*', ' ',
                       apres)
        apres = re.sub(r'\([^)]{0,25}\)', ' ', apres)      # (T.), (Cr.)
        morceaux = re.split(r'§', apres)
        morceaux[0] = re.sub(r'^[.,;:\s]+', '', morceaux[0])
        phrases = rassemble([morceaux[0]]).split('. ')
        prem = phrases[0].strip(' ,;.')
        if len(prem) >= 12 and len(prem.split()) >= 3:
            out.append((vedette, prem.rstrip('.') + '.'))
        # les sections '§' sont exemples et locutions : ignorees ; les
        # autres sens viennent des entrees successives ( tr., intr. )
    # dedupe par vedette en gardant l ordre
    vus, finales = {}, []
    for vedette, sens in out:
        if vedette not in vus:
            vus[vedette] = 1
            finales.append((vedette, sens))
        elif vus[vedette] < max_sens:
            vus[vedette] += 1
            finales.append((vedette, sens))
    return finales


def sens_figueiredo(t, max_sens=3):
    """'caminhar v. t. Percorrer caminho a pé; andar. V. i. Percorrer,
    andando.' : coupe sur les changements de regime V. t./V. i."""
    out = []
    for m in re.finditer(
            r'(?m)^([a-zàáâãäéêíóôõúüç]{2,})\s+'
            r'((?:v\.\s*[a-zitn.]*|part\.)\s+.+?)(?=\n\n)', t, re.S):
        vedette, apres = m.group(1), m.group(2)
        apres = re.sub(r'^v\.\s*([tinea.]*\s*)', '', apres.strip())
        morceaux = re.split(r'(?:^|\s)V\.\s*[it]\.\s+', apres)
        n = 0
        for morceau in morceaux:
            phrases = rassemble([morceau]).split('. ')
            prem = phrases[0].strip(' ,;.')
            if len(prem) >= 10 and n < max_sens and vedette not in \
                    [v for v, _ in out]:
                out.append((vedette, prem.rstrip('.') + '.'))
                n += 1
    return out


def main():
    ecrire = '--ecrire' in sys.argv
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    atelier = args[0] if len(args) > 0 else 'workshop.db'
    petro = [args[1], args[2]] if len(args) > 3 else ['petrocchi1.txt',
                                                      'petrocchi2.txt']
    fig = args[-1] if len(args) > 3 else 'figueiredo.txt'

    it_sens = []
    for f in petro:
        it_sens += sens_petrocchi(open(f, encoding='utf-8').read())
    pt_sens = sens_figueiredo(open(fig, encoding='utf-8').read())
    it, pt = {}, {}
    for vedette, sens in it_sens:
        it.setdefault(vedette, []).append(sens)
    for vedette, sens in pt_sens:
        pt.setdefault(vedette, []).append(sens)
    print('vedettes verbales Petrocchi : %d' % len(it))
    print('vedettes verbales Figueiredo : %d' % len(pt))

    db = sqlite3.connect(atelier)
    deja = {n for (n,) in db.execute('SELECT nom FROM sources')}
    for nom, caract in (
            (PETROCCHI, 'Policarpo Petrocchi, Novo dizionario universale '
                        'della lingua italiana ( 1887, 2 vol. ), domaine '
                        'public ; numerisation archive.org, OCR conserve '
                        'tel quel'),
            (FIGUEIREDO, 'Cândido de Figueiredo, Novo Diccionário da Língua'
                          ' Portuguesa ( 1913 ), domaine public ; '
                          'numerisation archive.org, OCR conserve tel quel')):
        if nom not in deja:
            db.execute('INSERT INTO sources(nom, caract) VALUES(?,?)',
                       (nom, caract))
    id_s = {n: i for i, n in db.execute('SELECT id, nom FROM sources')}
    bilans = {}
    exemples = []
    for lg, dictionnaire, clit in (('it', it, CLIT_IT), ('pt', pt, CLIT_ES)):
        nom = PETROCCHI if lg == 'it' else FIGUEIREDO
        remplacés = 0
        for (verbe,) in db.execute('SELECT verbe FROM verbes WHERE langue=? '
                                   'GROUP BY verbe', (lg,)):
            cible = base_pronominale(verbe, clit) if lg == 'it' else verbe
            senss = dictionnaire.get(cible) or dictionnaire.get(verbe)
            if not senss:
                continue
            if not ecrire:
                if len(exemples) < 6:
                    exemples.append('%s %s : %s' % (
                        lg, verbe, ' | '.join(senss)[:110]))
                bilans[nom] = bilans.get(nom, 0) + 1
                continue
            db.execute('DELETE FROM defs WHERE langue=? AND verbe=?',
                        (lg, verbe))
            # une seule entree ( pos ) par verbe : rang = position du sens
            pos = db.execute('SELECT COALESCE(MAX(pos),-1)+1 FROM defs '
                             'WHERE langue=?', (lg,)).fetchone()[0]
            for rg, sens in enumerate(senss):
                db.execute('INSERT INTO defs VALUES(?,?,?,?,?,?,?,?)',
                           (lg, pos, rg, verbe, nom, sens, id_s[nom],
                            '2026-11-25'))
            remplacés += 1
            bilans[nom] = bilans.get(nom, 0) + 1
    if ecrire:
        db.commit()
    db.close()
    for nom, n in sorted(bilans.items()):
        print('%-20s %5d verbes remplacés' % (nom, n))
    for e in exemples:
        print('   ', e)
    print('mode : %s' % ('ECRITURE' if ecrire else 'lecture seule'))


if __name__ == '__main__':
    main()
