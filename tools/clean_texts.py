# Nettoie les incoherences typographiques des DEFINITIONS dans
# l'atelier ( jamais la conjugaison ) :
#   defs.etiquette : ",." finaux et espaces doubles.
#   defs.texte     : virgules/points parasites du montage des sources,
#                   ',' ou '.' en tete de sens, espace avant la
#                   ponctuation, suites de points en "....", fins
#                   pendantes ( ',' ';' a remplacer par '.' ou a
#                   retirer selon le style de la langue ), espaces
#                   doubles.
# Regles derivees du corpus : fr/es/en terminent les sens par '.',
# les autres langues ( de/it/pt/pl/cs/ro, glosses ) ne mettent pas de
# point final. Les fins ':' sont des chapitres Wiktionary legitimes :
# non modifiees.
# FORBIDDEN chars \x01 \x02 \x03 dans le texte, \x04 permis une fois.
# Usage : python3 outils/clean_texts.py [workshop.db] [--ecrire]
# Sans --ecrire : tour a blanc, affiche les categories et un extrait.
# SPDX-License-Identifier : MIT
import os
import re
import sqlite3
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
FIN_POINTS = ('fr', 'es', 'en')  # langues a point final


def nettoie_etiquette(e):
    nouveau = re.sub(r'\s+', ' ', e).strip()
    nouveau = re.sub(r',\s*\.+$', '.', nouveau)      # 'Par extension,.' -> '.'
    nouveau = re.sub(r'\s*([,.;:!?])', r'\1', nouveau)  # espace avant ponctu.
    nouveau = re.sub(r'\.{2,}$', '.', nouveau)      # '..' finaux
    return nouveau


def nettoie_texte(t, lg):
    nouveau = re.sub(r'[ \t]+', ' ', t).strip()

    # montage parasite : ',' collante devant '.' ( 'phrase,.' )
    nouveau = re.sub(r'\s*,\s*\.', '.', nouveau)
    # suites de points : 4+ -> ellipse '...', exactement 2 -> '.'
    nouveau = re.sub(r'\.{4,}', '...', nouveau)
    nouveau = re.sub(r'(?<!\.)\.\.(?!\.)', '.', nouveau)
    # ellipse suivie d une lettre sans espace ( 'de....en' -> 'de... en' )
    nouveau = re.sub(r'(\.\.\.)(?=[A-Za-zÀ-ÿ])', r'\1 ', nouveau)
    # tete parasite : ',' '.' ';' ':' perdus du decoupage des sources
    nouveau = re.sub(r'^[,.;:\s]+', '', nouveau)
    # espace avant ponctuation ( 'Absolument .' / 'richesses ,' )
    nouveau = re.sub(r'\s+([,.;:!?])', r'\1', nouveau)
    # espace apres ouvrante / avant fermante
    nouveau = re.sub(r'([\(\[«])\s+', r'\1', nouveau)
    nouveau = re.sub(r'\s+([\)\]»])', r'\1', nouveau)

    # fins pendantes
    if lg in FIN_POINTS:
        nouveau = re.sub(r'[,;]$', '.', nouveau)
        if not nouveau.endswith(('.', '!', '?', '...', ')',
                                 ']', '»', ':', '"', "'")):
            nouveau += '.'
    else:
        # styles sans point final : on garde les vraies phrases si
        # l entree en contient une, sinon on laisse la gloss ouverte
        if re.match(r'^[A-ZÀ-Ý]', nouveau) and re.search(r'[.!?]$', nouveau):
            pass  # phrase complete : ne rien toucher
        else:
            nouveau = re.sub(r'[,;]$', '', nouveau)

    nouveau = nouveau.strip()
    if nouveau and not nouveau[0].isupper() and re.match(r'^[a-zà-ÿ]', nouveau) \
            and lg == 'fr' and nouveau[0] in 'abcdefghijklmnopqrstuvwxyz':
        # les sources historiques fr composent deja les minuscules
        # ( elles reprennent le mot Vedette ) : pas de changement
        pass
    return nouveau


def main():
    ecrire = '--ecrire' in sys.argv
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    atelier = args[0] if args else os.path.join(ICI, 'workshop.db')
    db = sqlite3.connect(atelier)
    bilans = {'etiquette': 0, 'texte': 0}
    exemples = {'etiquette': [], 'texte': []}
    rows = list(db.execute(
        'SELECT langue, pos, rang, verbe, etiquette, texte FROM defs'))
    for lg, pos, rang, verbe, et, tx in rows:
        ne = nettoie_etiquette(et) if et else et
        if ne != et:
            bilans['etiquette'] += 1
            exempl = '{} : {!r} -> {!r}'.format(verbe, et, ne)
            if len(exemples['etiquette']) < 8:
                exemples['etiquette'].append(exempl)
        nt = nettoie_texte(tx, lg) if tx else tx
        if nt != tx:
            bilans['texte'] += 1
            exempl = '{} : {!r} -> {!r}'.format(verbe, tx[:70], nt[:70])
            if len(exemples['texte']) < 12:
                exemples['texte'].append(exempl)
        if ecrire and (ne != et or nt != tx):
            db.execute('UPDATE defs SET etiquette=?, texte=? '
                       'WHERE langue=? AND pos=? AND rang=?',
                       (ne, nt, lg, pos, rang))
    if ecrire:
        db.commit()
    db.close()
    for cle in ('etiquette', 'texte'):
        print('%s : %d changements' % (cle, bilans[cle]))
        for e in exemples[cle]:
            print('   ', e)
    print('mode : %s' % ('ECRITURE' if ecrire else 'lecture seule'))


if __name__ == '__main__':
    main()
