# Attribue une source a chaque sens de definitions ( defs.id_source ) :
# plus aucune definition sans source. Complete aussi date_ajout avec la
# date du lot qui a introduit chaque definition ( jalons du projet ),
# pas la date du jour.
#
# Regles d attribution (documentees dans sources.caract) :
#   fr : texte retrouve dans l article Littré du verbe -> Littré ;
#        glossaire anglais -> angl. Wiktionary ;
#        renvois ( alternative form of... ) -> fr. Wiktionary ;
#        sinon -> Académie 8e, PAR ELIMINATION ( les definitions fr
#        historiques viennent de l Académie ou du Littré ; un sens
#        concis absent du Littré est donc attribue a l Académie ).
#   en : Webster 1913 ( dict.json.bz2 de lunixbochs/webster ) UNIQUEMENT
#        si le texte du sens apparait mot a mot dans l article verbal
#        du mot ; sinon angl. Wiktionary.
#   es : verbatim Real Academia 1913-1914 ; le lot heritait aussi des
#        glosses anglais du Wiktionary ( 'to ...' ), desormais triees.
#   de, it, pt : glossaires anglais du Wiktionary ou redactions
#        condensees du glossaire du generateur du projet ( MIT ),
#        tris par le texte ( lexique anglais etendu ).
#   pl, cs, ro : deja rattaches a l import ( natifs + glossaires ).
#
# Dates ( lots historiques du projet ) :
#   2026-11-24 : lots initiaux fr/en/es/de/it/pt/pl/cs (+ comblements
#                wikt_defs ) ;
#   2026-11-25 : roumain entier ; definitions natives pl/cs/ro des dumps
#                Wikimedia ( fichiers native_*.json ).
#
# Dependencies externes ( a telecharger, non incluses dans le depot ):
#   littre_idx.json ( index du Littré XML, oeuvres/littre ) et
#   dict.json.bz2 ( Webster, lunixbochs/webster ).
# Usage :
#   python3 outils/sources_defs.py [workshop.db] [littre_idx.json] [dict.json.bz2]
# SPDX-License-Identifier : MIT
import bz2, json, os, re, sqlite3, sys, unicodedata

ICI = os.path.dirname(os.path.abspath(__file__))
D_INIT = '2026-11-24'
D_RO = '2026-11-25'

NOUVELLES_SOURCES = [
    ('Académie 8e (1932-1935)',
     "Dictionnaire de l'Académie française, 8e édition, 1932-1935, "
     "domaine public ; attribué par élimination : sens non retrouvé "
     "dans le Littré ( les définitions françaises historiques viennent "
     "de l'Académie ou du Littré )"),
    ('Littré (1872-1877)',
     'Émile Littré, Dictionnaire de la langue française ( 1872-1877 ), '
     'texte du domaine public, numérisation XML oeuvres/littre ; '
     'attribué par comparaison du texte du sens avec l article'),
    ('fr. Wiktionary',
     'Wiktionnaire fr.wiktionary ( CC BY-SA 4.0 ) ; renvois et '
     'formes alternatives ( alternative form of, archaic spelling... )'),
    ('Webster 1913',
     "Webster's Revised Unabridged Dictionary, 1913 ( GCIDE ), texte du "
     "domaine public ; numérisation lunixbochs/webster ( code MIT ) ; "
     "attribué si le texte du sens apparait mot a mot dans "
    "l'article verbal du mot"),
    ('Real Academia 1913-1914',
     'Diccionario de la lengua castellana ( Real Academia Española, '
     '14e édition, 1913-1914 ), texte du domaine public'),
    ('Glossaire du générateur du projet',
     'Glossaires anglais et allemands du générateur du projet web '
     '( SPDX-License-Identifier : MIT )'),
]

ANGLAIS = re.compile(
    r'^(to |To |alternative (form|spelling)|archaic( form| spelling)?|'
    r'dated|post-\d{4}|pre-reform|obsolete( spelling)?|'
    r'Formerly standard|superseded|synonym of|reflexive of|mainly|'
    r'idiomatic|informal|ditransitive|transitive |intransitive |'
    r'now |rare |chiefly |used |of a |to give|to make|verb |bite |'
    r'piss off|The process|regional form)', re.I)
# mots temoins anglais : distinguent les glosses anglaises des
# redactions en it/pt/de meme sans accents
EN_MOTS = re.compile(r'\b(the|someone|something|somebody|form of|'
                     r'spelling of)\b')
FR_WIKT = re.compile(
    r'\b(alternative form|archaic spelling|dated form|post-\d{4} spelling|'
    r'superseded|obsolete spelling|synonym of|inflected form)\b', re.I)


def norme(t):
    t = t.lower().replace('œ', 'oe').replace('æ', 'ae')
    t = ''.join(c for c in unicodedata.normalize('NFD', t)
                if unicodedata.category(c) != 'Mn')
    t = re.sub(r'[^a-z0-9 ]+', ' ', t)
    return re.sub(r'\s+', ' ', t).strip()


def est_anglais(tx):
    return bool(ANGLAIS.match(tx)) and not re.search(
        r'[àâçéèêëîïôùûüœ]', tx)


def est_anglais_glossaire(tx):
    """Glossaire anglais de famine..."""
    return bool(ANGLAIS.search(tx) or EN_MOTS.search(tx))


def webster_verbes(dict_path):
    """({mots verbaux}, {mot: texte normalise de l article})."""
    webster = json.loads(bz2.open(dict_path, 'rt', encoding='utf-8').read())
    verbes, arts = set(), {}
    for cle, article in webster.items():
        if '<div class="pos">' not in article:
            continue
        verbal = any(re.search(r'\bv\.', m.group(1)) for m in
                     re.finditer(r'<div class="pos">([^<]*)</div>',
                                 article))
        if not verbal:
            continue
        mot = cle.strip().lower()
        verbes.add(mot)
        tete = article.split('<div class="pos">')[0]
        arts[mot] = norme(re.sub(r'<[^>]+>', ' ', article))
        for m2 in re.findall(r'<h2 class="hw">([^<]*)</h2>', tete):
            verbes.add(m2.strip().lower())
    return verbes, arts


def main():
    atelier = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ICI, 'workshop.db')
    littre_p = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ICI, '..', 'littre_idx.json')
    webster_p = sys.argv[3] if len(sys.argv) > 3 else os.path.join(ICI, '..', 'dict.json.bz2')
    littre = json.load(open(littre_p, encoding='utf-8'))[0]
    webster, webster_arts = webster_verbes(webster_p)
    wikt_defs = json.load(open(os.path.join(ICI, 'wikt_defs.json'),
                               encoding='utf-8'))
    natifs = {lg: set(json.load(open(p, encoding='utf-8')))
              for lg, p in [(lg, os.path.join(ICI, 'native_%s.json' % lg))
                            for lg in ('pl', 'cs', 'ro')] if os.path.exists(p)}
    wikt_mots = {lg: set(wikt_defs.get(lg, {})) for lg in wikt_defs}

    db = sqlite3.connect(atelier)
    id_s = {n: i for i, n in
            db.execute('SELECT id, nom FROM sources')}
    for nom, caract in NOUVELLES_SOURCES:
        if nom not in id_s:
            cur = db.execute('INSERT INTO sources(nom, caract) VALUES(?,?)',
                             (nom, caract))
            id_s[nom] = cur.lastrowid

    # date par defaut selon le lot
    db.execute("UPDATE verbes SET date_ajout=? WHERE langue!='ro'", (D_INIT,))
    db.execute("UPDATE verbes SET date_ajout=? WHERE langue='ro'", (D_RO,))
    for lg in ('pl', 'cs', 'ro'):
        nats = natifs.get(lg, set())
        for mot in nats:
            db.execute('UPDATE verbes SET date_ajout=? WHERE langue=? '
                       'AND verbe=?', (D_RO, lg, mot))
    db.execute("UPDATE defs SET date_ajout=? WHERE langue!='ro'", (D_INIT,))
    db.execute("UPDATE defs SET date_ajout=? WHERE langue='ro'", (D_RO,))
    for lg in ('pl', 'cs', 'ro'):
        for mot in natifs.get(lg, set()):
            db.execute('UPDATE defs SET date_ajout=? WHERE langue=? AND '
                       'verbe=?', (D_RO, lg, mot))
    for lg in wikt_mots:
        for mot in wikt_mots[lg]:
            db.execute('UPDATE defs SET date_ajout=? WHERE langue=? AND '
                       'verbe=?', (D_INIT, lg, mot))

    # reattribution complete de es/it/pt/de ( lots herites melanges )
    db.execute("UPDATE defs SET id_source=NULL WHERE langue IN "
               "('es','it','pt','de')")
    # attribution des sources
    bilans = {}
    for langue, etiquette, texte, verbe, pos, rang in db.execute(
            'SELECT langue, etiquette, texte, verbe, pos, rang FROM defs '
            'WHERE id_source IS NULL'):
        if langue == 'fr':
            art = littre.get(verbe) or littre.get(verbe.split("'")[-1])
            if art and norme(texte) and norme(texte) in art:
                src = 'Littré (1872-1877)'
            elif est_anglais(texte):
                src = 'angl. Wiktionary'
            elif FR_WIKT.search(texte):
                src = 'fr. Wiktionary'
            else:
                src = 'Académie 8e (1932-1935)'
        elif langue == 'en':
            # Webster PAR DEFINITION : le texte du sens doit apparaitre
            # mot a mot dans l article verbal ( sinon le sens vient du
            # glossaire angl. Wiktionary, meme si le verbe a un article )
            art = webster_arts.get(verbe.lower(), '')
            src = 'Webster 1913' if art and norme(texte) in art \
                else 'angl. Wiktionary'
        elif langue == 'es':
            # lot herite melange : verbatim RAE ET glosses anglais du
            # Wiktionary ( 3 660 'to ...' ) ; RAE par elimination
            src = 'angl. Wiktionary' if ANGLAIS.search(texte) \
                or re.match(r'^(to |To )', texte) \
                else 'Real Academia 1913-1914'
        elif langue in ('it', 'pt', 'de'):
            # melange herite : glossaires anglais du Wiktionary ET
            # redactions condensees dans la langue issues du glossaire
            # du generateur du projet ; le test anglais etend au
            # lexique typique ( someone, the, pre-reform spelling... )
            src = 'angl. Wiktionary' if est_anglais_glossaire(texte) \
                else 'Glossaire du générateur du projet'
        db.execute('UPDATE defs SET id_source=? WHERE langue=? AND pos=? '
                   'AND rang=?', (id_s[src], langue, pos, rang))
        bilans[src] = bilans.get(src, 0) + 1
    db.commit()
    n = db.execute('SELECT COUNT(*) FROM defs WHERE id_source IS NULL'
                   ).fetchone()[0]
    total = db.execute('SELECT COUNT(*) FROM defs').fetchone()[0]
    for src, c in sorted(bilans.items(), key=lambda x: -x[1]):
        print('%-38s %6d' % (src, c))
    print('sense sans source : %d / %d' % (n, total))
    db.close()


if __name__ == '__main__':
    main()
