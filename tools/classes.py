# Calcule le classement grammatical des verbes dans l'atelier :
#   verbes.groupe       INTEGER NULL : fr 1/2/3, es/it/pt 1/2/3, ro I a IV (1-4)
#   verbes.particularite TEXT  NULL : en 'regulier'/'irregulier'/'double forme
#                                 (US/GB)', de 'faible'/'forte', pl/cs la
#                                 terminaison de l infinitif.
# Les regles sont derivees des modeles ( table modeles ) et des verbes
# eux-memes ; aucun tableau externe n est embarque.
#   fr  : modele en -er ( sauf aller ) -> 1er groupe ; -ir au participe
#         present -issant -> 2e ; le reste ( oir, aître, aller... ) -> 3e.
#   en  : le modele donne les suffixes de preterit et de participe passe ;
#         un verbe est regulier si ces suffixes sont ceux des regles
#         orthographiques standard ( +d, +ed, doubling, -ied, -cked ).
#   es/it/pt : classe par terminaison de l'infinitif ; auxiliaires
#         marques 'irregulier (auxiliaire)'.
#   ro : terminaison infinitive : -a -> I, -ea -> II, -e -> III, -i -> IV
#         ( classes canoniques du roumain ).
#   de : preterit du modele en -te -> faible, changement vocalique ->
#         forte ( les mixtes, morphologiquement faibles, ne sont pas
#         distinguables automatiquement et restent 'faible' ).
#   pl/cs : terminaison de l infinitif ( pas de numerotation standard ).
# Usage : python3 outils/classes.py [workshop.db]
# SPDX-License-Identifier : MIT
import os
import re
import sqlite3
import sys

ICI = os.path.dirname(os.path.abspath(__file__))

PL_TER = ['ować', 'iwać', 'ywać', 'ać', 'eć', 'ić', 'ąć', 'uć', 'yć',
          'ść', 'źć', 'óć', 'c']
CS_TER = ['ovat', 'at', 'it', 'ýt', 'ít', 'ét', 'out', 'ci', 't']


def nom_modele(ligne):
    """Le nom de modele : avant le ';', apres le ':' final."""
    return ligne.split(';')[0].split(':')[-1].strip()


def groupe_fr(ligne):
    suff = nom_modele(ligne)
    if suff == 'aller':
        return 3, None
    if suff.endswith('er'):
        return 1, None
    if suff.endswith('ir') and 'issant' in ligne:
        return 2, None
    return 3, None


def suffixes_attendus(v):
    """Suffixes reguliers possibles du preterit/participe passe anglais."""
    if v.endswith('e'):
        return {'d'}
    out = {'ed'}
    # -y apres consonne -> -ied
    if len(v) > 2 and v.endswith('y') and v[-2] not in 'aeiou':
        out.add('ied')
    # CVC : doublement de la consonne finale ( stop -> stopped )
    if len(v) >= 3 and v[-1] not in 'aeiouwxy' and v[-2] in 'aeiou' \
            and v[-3] not in 'aeiou':
        out.add(v[-1] + 'ed')
    # -ic -> -cked ( picnic -> picnicked )
    if v.endswith('ic'):
        out.add('cked')
    return out


AUX = {'en': {'be', 'have', 'do'}, 'fr': {'être', 'avoir', 'aller'},
       'es': {'ser', 'estar', 'haber', 'ir'}, 'it': {'essere', 'avere'},
       'pt': {'ser', 'estar', 'ter', 'ir'}, 'de': {'sein', 'haben', 'werden'}}


def suffixes_attendus_plein(v):
    """Formes preterit/participe passe regulieres attendues en PLEIN :
    doubles consonnes incluses ( stop -> stopped, cancel -> cancelled,
    picnic -> picnicked par c -> ck )."""
    if v.endswith('e'):
        return {v + 'd'}
    out = {v + 'ed'}
    if len(v) > 2 and v.endswith('y') and v[-2] not in 'aeiou':
        out.add(v[:-1] + 'ied')
    if len(v) >= 3 and v[-1] not in 'aeiouwxy' and v[-2] in 'aeiou' \
            and v[-3] not in 'aeiou':
        out.add(v + v[-1] + 'ed')
    if v.endswith('ic'):
        out.add(v + 'ked')
    return out


def classe_en_ligne(ligne):
    """Classification PAR LIGNE-MODELE : tous les verbes d une meme
    ligne ont la meme regularite. Le nom de la ligne ( avant ';' )
    est de la forme <representant>:<fin> ; le radical partage vaut
    representant[:-len(fin)] et les tokens de la ligne sont des
    suffixes apres ce radical, sauf quand <representant>:<representant>
    donne des formes pleines ( picnic:picnicked... )."""
    champs = ligne.split(';')
    if len(champs) < 4:
        return None, None
    nom = champs[0]
    tete = nom.split(':')[0]
    fin = nom.split(':')[1] if ':' in nom else ''
    if not tete:
        return None, 'irregulier'
    stem = tete[:len(tete) - len(fin)] if len(fin) < len(tete) else ''

    def pleins(tok):
        f = stem + tok
        return f if f.startswith(tete) else None

    att = suffixes_attendus_plein(tete)
    preterits = set()
    for t in champs[2].split(','):
        if not t:
            continue
        f = pleins(t)
        if f and f in att:
            preterits.add(t)
            continue
        suffix = t[len(fin):] if t.startswith(fin) else t
        if suffix in suffixes_attendus(tete) or suffix in \
                {a[len(tete):] or 'ed' for a in att}:
            preterits.add(t)
    pps = champs[3].split('/')[0] if '/' in champs[3] else champs[3]
    pp = pps[len(fin):] if pps.startswith(fin) else pps
    tout_reg = preterits and preterits == \
        {t for t in champs[2].split(',') if t}
    if tout_reg and (champs[3] in att or pp in suffixes_attendus(tete)
                      or champs[3] in att):
        return None, 'regulier'
    if '/' in champs[3] and preterits:
        return None, 'double forme (US/GB)'
    return None, 'irregulier'


CLITIQUES = ['selas', 'selos', 'sela', 'selo', 'senos', 'sene',
             'cene', 'celo', 'cela', 'se', 'ci', 'ce', 'vi', 'ti',
             'mi', 'si', 'ne', 'nos', 'las', 'les', 'los', 'la',
             'gliela', 'glielo', 'gli',
             'le', 'lo', 'me', 'te']


def _decomposable(s):
    if not s:
        return True
    return any(s.endswith(cl) and
               _decomposable(s[:-len(cl)])
               for cl in CLITIQUES)


def BASE_infinitif(verbe):
    """Retire les pronoms/adverbes enclitiques ( alegrarse -> alegrar,
    contarci -> contare, addursi -> addurre, avercela -> avere ) :
    la plus longue coupe dont le reste se decompose en clitiques."""
    v = verbe.translate(str.maketrans('áéíóú', 'aeiou'))
    for cut in range(len(v), 2, -1):
        base, queue = v[:cut], v[cut:]
        if base.endswith(('ar', 'er', 'ir')) and _decomposable(queue):
            return base + 'e'
        if base.endswith(('are', 'ere', 'ire', 'arre', 'orre',
                         'urre')) and _decomposable(queue):
            return base
    return v


def groupe_esp(verbe, lg_esp=None):
    """es/it/pt : conjugaison par terminaison de l'infinitif (
    accent-insensible ), les pronominaux ramenes a leur base et
    la famille de por/pôr en 2e conjugaison irreguliere."""
    v = BASE_infinitif(verbe)
    if v.endswith(('ar', 'are')):
        return 1, None
    if v.endswith(('er', 'ere')):
        return 2, None
    if v.endswith(('ir', 'ire')):
        return 3, None
    if v.endswith('por') or v.endswith('pôr'):
        return 2, 'irregulier (famille de pôr)'
    if lg_esp == 'it' and v.endswith(('urre', 'orre', 'arre', 'rre',
                                     'ursi', 'orsi', 'arsi')):
        return 2, 'irregulier (famille de durre, porre, trarre)'
    return None, None


def groupe_ro(verbe):
    v = verbe[2:] if verbe.startswith('a ') else verbe
    if v == 'fi' or v == 'vrea' or v == 'avea':
        return None, 'irregulier (auxiliaire / semi-auxiliaire)'
    if v.endswith('ea'):
        return 2, None
    if v.endswith('a'):
        return 1, None
    if v.endswith('e'):
        return 3, None
    if v.endswith(('i', 'î')):
        return 4, None
    return None, None


def classe_de(ligne):
    champs = ligne.split(';')
    if len(champs) < 3:
        return None, None
    for p in champs[2].split(','):
        if not p:
            continue
        if p not in ('te', 'test', 'tet', 'ten') and \
                not p.endswith(('te', 'test', 'tet', 'ten')):
            return None, 'forte'
    return None, 'faible'


def terminaison(verbe, termes):
    for t in termes:
        if verbe.endswith(t):
            return '-' + t
    return None


def main():
    atelier = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ICI, 'workshop.db')
    db = sqlite3.connect(atelier)
    # colonnes ajoutees si absentes ( import fait avec un ancien schema )
    deja = {r[1] for r in db.execute('PRAGMA table_info(verbes)')}
    if 'groupe' not in deja:
        db.execute('ALTER TABLE verbes ADD COLUMN groupe INTEGER')
    if 'particularite' not in deja:
        db.execute('ALTER TABLE verbes ADD COLUMN particularite TEXT')
    modeles = {}
    for lg, ligne, contenu in db.execute(
            'SELECT langue, ligne, contenu FROM modeles'):
        modeles.setdefault(lg, {})[ligne] = contenu
    classes_en_lignes = {ligne: classe_en_ligne(contenu)
                         for ligne, contenu in modeles['en'].items()}
    bilans = {}
    for lg in ('fr', 'en', 'es', 'de', 'it', 'pt', 'pl', 'cs', 'ro'):
        for ligne, verbe in db.execute(
                'SELECT ligne, verbe FROM verbes WHERE langue=?', (lg,)):
            tpl = modeles.get(lg, {}).get(ligne, '')
            if lg == 'fr':
                g, p = groupe_fr(tpl)
            elif lg == 'en':
                g, p = classes_en_lignes.get(ligne,
                                             classe_en_ligne(tpl))
                if verbe in AUX['en'] and p in ('regulier', 'irregulier'):
                    p = 'irregulier (auxiliaire)'
            elif lg in ('es', 'it', 'pt'):
                g, p = groupe_esp(verbe, lg_esp=lg)
                if verbe in AUX[lg]:
                    p = 'irregulier (auxiliaire)'
            elif lg == 'ro':
                g, p = groupe_ro(verbe)
            elif lg == 'de':
                g, p = classe_de(tpl)
                if verbe in AUX[lg] and p == 'forte':
                    p = 'irregulier (auxiliaire)'
            elif lg == 'pl':
                g, p = None, terminaison(verbe, PL_TER)
            else:  # cs
                g, p = None, terminaison(verbe, CS_TER)
            if verbe in AUX.get(lg, set()) and lg == 'en' \
                    and p == 'regulier':
                p = 'irregulier (auxiliaire)'
            if verbe in AUX.get(lg, set()) and lg == 'fr':
                p = 'irregulier (auxiliaire)'
            db.execute('UPDATE verbes SET groupe=?, particularite=? '
                       'WHERE langue=? AND ligne=? AND verbe=?',
                       (g, p, lg, ligne, verbe))
            bilans[(lg, g, p)] = bilans.get((lg, g, p), 0) + 1
    db.commit()
    for (lg, g, p), n in sorted(
            bilans.items(),
            key=lambda x: (x[0][0], str(x[0][1]), str(x[0][2]))):
        print('%-3s groupe=%-4s particularite=%-35s %6d' % (lg, g, p, n))
    db.close()


if __name__ == '__main__':
    main()
