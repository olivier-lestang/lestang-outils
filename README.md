# Lestang Outils

Application multiplateformes (Windows, macOS, Linux, iOS, Android) issue du
projet web Vibetab : conjugaisons (9 langues), cartes géographiques (France,
Union européenne, Monde, avec jour/nuit et cadrages outre-mer), météo
multi-sources (open-meteo, Météo-France, wttr, met.no, IPMA, JMA, NWS, BOM,
HKO), compresseur de PDF (pdfium via `printing`, réencodage JPEG `image`),
recherche web paramétrable (47 moteurs), générateur de mot de passe,
raccourcis, réglages (langue, thème, ordre des cartes, sauvegarde).
Les données vivent dans une base SQLite embarquée (`assets/lestang_outils.db`).

## Construire et lancer

```bash
flutter pub get
flutter run -d windows    # ou -d macos / -d linux / -d ios / -d android
flutter build apk --release          # Android
flutter build windows --release      # Windows, etc.
```

Les tests (moteurs de conjugaison, 30 contrôles sur les données réelles) :

```bash
flutter test
```

Sur Android, les boîtes de dialogue « enregistrer sous » ne sont pas
existantes : le PDF compressé et l'export des préférences passent par la
feuille de partage du système (Enregistrer dans Téléchargements, Drive,
e-mail… via `share_plus`). Sur bureau, la boîte de dialogue native est
utilisée (`file_selector`).

## Regénérer la base

La base est reconstruite à partir des fichiers de données du projet web :

```bash
node outils/extraire.js <chemin-du-projet-web>/web/ outils/brut.json
python3 outils/nettoie_en.py        # lexique anglais : filtre + doubles formes
python3 outils/dedupe.py            # aucun doublon, toutes langues
# comblement des verbes sans définition depuis les Wiktionary
# monolingues ( la collecte a déjà été faite, voir le bullet
# « Comblement des définitions manquantes » ) :
python3 outils/combler_defs.py outils/brut.json outils/wikt_defs.json outils/retires_wikt.json outils/brut.json
python3 outils/construire_pl_cs.py
python3 outils/construire_ro.py
python3 outils/completer_natifs.py outils/brut.json
python3 outils/construire_bdd.py

# atelier SQL (optionnel) : tables normalisees editables dans un GUI
# SQLite ; l'atelier devient la source de verite des donnees de
# conjugaison, brut.json se regenere ensuite :
#   python3 outils/atelier.py import   # brut.json -> atelier.db
#   python3 outils/sources_defs.py    # rattache chaque sens a sa source
#                                     # ( Littré, Académie, Webster 1913,
#                                     # RAE 1913-1914, Wiktionary... )
#   python3 outils/classes.py         # groupe/particularite des verbes
#   python3 outils/nettoyer_textes.py # typo des defs ( ",." , fins pendantes )
#   python3 outils/dictionnaires_pd.py # defs it/pt : Petrocchi 1887
#                                     # et Figueiredo 1913 ( OCR archive.org )
#   python3 outils/sanders_extract.py  # defs de : Sanders 1876 ( OCR maison )
#   python3 outils/orthographe.py     # dic. PD : orthographe actuelle
#                                     # ( de 1901, it accents, pt AO90 )
#   python3 outils/coquilles_ocr.py   # dic. PD : coquilles OCR certaines
#                                     # ( fich->sich, superfice, ob jeto )
#   python3 outils/ajouter_wikt.py    # it/pt/de : glosses anglais du
#                                     # Wiktionary ranges AVANT les dic.
#                                     # PD ( restauration 1.2.2 + API )
#   python3 outils/dump_natif.py fr frwiktionary-latest-pages-articles.xml.bz2
#                                     # fr/es/it/pt/de : definition native
#                                     # du Wiktionary de la langue, extraite
#                                     # des dumps Wikimedia ( cache durable
#                                     # wikt_natif_fetch.json, CC BY-SA 4.0 )
#   python3 outils/natifs_wikt.py    # sens natifs EN TETE de chaque fiche ;
#                                     # angl. Wiktionary ne reste qu'en
#                                     # secours ( verbes sans article natif )
#   python3 outils/traduire_wikt.py  # traduit dans la langue les gloses
#                                     # anglaises de secours : lot manuel
#                                     # outils/traduits_de.json + renvois
#                                     # ( etiquette « angl. Wiktionary,
#                                     # trad. » ; lots suivants it/pt )
#   ... editions SQL dans atelier.db ...
#   python3 outils/atelier.py export   # atelier.db -> brut.json
#   python3 outils/atelier.py verifier  # controle de concordance fina
```

`extraire.js` charge les scripts de données de `index.html` et vide toutes
les constantes ; `construire_bdd.py` décode chaque format (routes, contours,
points, chaînes de conjugaison) et écrit `assets/lestang_outils.db` (~23 Mo).

Les filtres par dictionnaire du domaine public (Webster pour l'anglais,
Figueiredo pour le portugais, Petrocchi et Crusca pour l'italien) ont été
essayés, appliqués, puis **abandonnés comme filtres** : tous les verbes du
Wiktionary sont désormais conservés (voir « Détail du procédé »). Depuis la
version 1.3.0, Petrocchi et Figueiredo sont en revanche réutilisés comme
**source des définitions** it/pt (sans filtrer la base) via
`outils/dictionnaires_pd.py`. Les scripts
`outils/filtre_webster.py`, `parse_figueiredo.py`, `filtre_figueiredo.py`,
`parse_petrocchi.py`, `parse_crusca.py` et `filtre_italien.py` restent dans
le dépôt pour référence, avec les URLs des OCR des dictionnaires listées
plus bas.

Les langues polonaise (pl) et tchèque (cs) n'existent pas dans le moteur
web : leurs chaînes sont construites par `python3 outils/construire_pl_cs.py`
depuis les listes déjà vérifiées `outils/pl_ok.json` / `outils/cs_ok.json`
(extraction kaiki/Wiktionary vérifiée forme par forme). Le roumain (ro) est
construit de la même manière par `python3 outils/construire_ro.py` depuis
`outils/ro_ok_*.json` (table ro-conj complète du Wiktionary, formes copiées
verbatim).

La source de chaque verbe est stockée dans la base (ligne `vsrc` par langue :
la liste des verbes venus du Wiktionary, les autres venant du générateur
maison) et affichée sur chaque fiche de conjugaison. Pour la reconstruire
après une nouvelle extraction : extraire les données du moteur web **tel
qu'avant enrichissement** dans `outils/brut_orig.json`, puis lancer
`python3 outils/ajouter_vsrc.py` avant `construire_bdd.py`.

## Architecture

- `lib/conj/` : le portage Dart fidèle des moteurs de conjugaison
  (`socle.js`, `conjugaison-{fr,en,es,de,it,pt}.js` du web, plus les moteurs
  polonais `Pl`, tchèque `Cs` et roumain `Ro` écrits pour l'app) ; la base ne stocke que
  les chaînes brutes, toutes les formes sont calculées sur l'appareil. `ecran_conjugaison.dart` est l'écran (recherche, planche de
  temps, définitions).
- `lib/bdd.dart` : ouverture de la SQLite embarquée (copiée depuis les
  assets au premier lancement), lectures de conjugaison et de géographie.
- `lib/cartes/cartes_geo.dart` : cartes géographiques, rendu `CustomPaint`
  (zoom et déplacement), deux palettes clair/sombre fidèles au web.
- `lib/ecrans/` : météo (Open-Meteo, sans clé), mot de passe (100 % local,
  tirage cryptographique), raccourcis, réglages, licences.
- `lib/l10n.dart` : interface en six langues (fr, en, es, pt, it, de).

## Contenu de la base

- Conjugaison : en 19 070, it 12 429, pl 9 064, ro 6 970, fr 8 535,
  es 8 957, pt 6 084, de 4 220, cs 4 143 ; aucun doublon ; tous les verbes du
  Wiktionary sont conservés ; chaque verbe a une définition (379
  verbes restés sans définition ont été comblés depuis les Wiktionary
  monolingues et 60 mots que le Wiktionary ne définit pas comme
  verbes ont été retirés). Définitions : français
  : Académie 8e éd. + Littré ; anglais : Webster 1913 où il définit,
  sinon glossaire anglais du Wiktionary ; espagnol : Real Academia
  1913 ; de : Sanders, Wörterbuch der deutschen Sprache ( 1876, 205
  verbes, domaine public, OCR maison Tesseract modele frk 400 dpi,
  texte conservé tel quel ) sinon glossaires anglais du Wiktionary
  (CC BY-SA) ; it : Petrocchi
  1887 ( 2 397 verbes ) et pt : Figueiredo 1913 ( 3 423 verbes ), domaine
  public, OCR archive.org conservé tel quel, sinon glossaire anglais du
  Wiktionary ;
  depuis la version 1.5, chaque fiche affiche en premier la
  définition native du Wiktionary de la langue ( fr/es/it/pt/de :
  8 389 / 5 374 / 5 775 / 3 703 / 3 788 verbes, dumps Wikimedia,
  CC BY-SA 4.0 ), puis le dictionnaire du domaine public
  ( académies et Littré, RAE, Petrocchi, Figueiredo, Sanders ) ; le
  glossaire anglais du Wiktionary ne reste qu'en secours, pour les
  verbes sans article natif ( it 6 653, pt 2 376, de 431 ; sa
  traduction, étiquette « angl. Wiktionary, trad. », reste à faire ) ;
  pl/cs/ro : définitions natives du Wiktionary de la langue
  ( 4 378 / 1 931 / 5 437 verbes, dumps pl/cs/ro.wiktionary, CC BY-SA ),
  sinon glossaire anglais du Wiktionary ; les définitions traduites de
  l'anglais sont étiquetées « angl. Wiktionary, trad. ». Aucune
  numérisation de dictionnaire du domaine public ( fin 19e, début 20e ) n'a
  pas encore été intégrée pour it/pt ( la traduction des gloses anglaises
  a été préférée ) ; le Słownik warszawski, dont l'OCR archive.org est
  exploitable, est intégré depuis la version 1.5.7, le dump officiel de
  dexonline ( pour le roumain ) était
  tronqué au moment de la collecte et son site interdit le scraping ;
  le comblement « dictionnaire ancien » reste à faire si une
  numérisation libre devient disponible.
- Le lexique anglais est épuré : pas de verbe composé à trait d union
  ( air-condition, birdy-sit ) ni de terme très spécialisé
  (`outils/nettoie_en.py`) ; les verbes définis par le Webster's
  Revised Unabridged Dictionary ( 1913, texte du domaine public ;
  numérisation lunixbochs/webster, code MIT ) reçoivent sa définition
  (`outils/filtre_webster.py`).
- France : 160 départements, 2 461 autoroutes, 2 884 nationales,
  50 984 départementales, 54 fleuves, LGV, 178 villes des transports,
  103 tronçons parisiens.
- Union : 322 contours membres, ZEE, 17 routes européennes, LGV,
  capitales et villes.
- Monde : 285 frontières, grandes villes.

## Licences

Code de l'application et moteurs de conjugaison (portages Dart des moteurs
du projet web pour fr/en/es/de/it/pt, moteurs `Pl`/`Cs` écrits pour l'app) :
MIT (`LICENSE`).

### Conjugaison : procédé et licences, langue par langue

| Langue | Verbes | dont Wiktionary | Procédé | Définitions |
| --- | ---: | ---: | --- | --- |
| fr | 8 535 | 1 574 | Moteur maison ; verbes enrichis depuis le Wiktionnaire (kaikki), chaque forme vérifiée, source stockée par verbe | fr. Wiktionnaire en tête (8 389 verbes, dump Wikimedia, CC BY-SA) ; Académie 8e éd. + Littré, domaine public |
| en | 19 070 | 17 427 | Moteur maison ; enrichissement Wiktionary vérifié forme par forme (doubles formes -ed/-t conservées) | Webster 1913 où il définit (domaine public, numérisation lunixbochs/webster, MIT), sinon glossaires anglais du Wiktionary, CC BY-SA 4.0 |
| es | 8 957 | 3 746 | Moteur maison ; enrichissement Wiktionary vérifié forme par forme | es. Wiktionary en tête (5 374 verbes, dump Wikimedia, CC BY-SA) ; Real Academia 1913, domaine public |
| de | 4 220 | 3 940 | Moteur maison ; enrichissement Wiktionary vérifié forme par forme | Sanders 1876 pour 205 verbes (domaine public, OCR maison Tesseract frk 400 dpi sur les PDF images archive.org ; releve revu à la main, defauts OCR conservés) ; de. Wiktionary en tête (3 788 verbes, dump Wikimedia, CC BY-SA) ; angl. Wiktionary en secours (431 verbes sans article natif) |
| it | 12 429 | 11 950 | Moteur maison ; enrichissement Wiktionary vérifié forme par forme, tous les verbes du Wiktionary conservés | it. Wiktionary en tête (5 775 verbes, dump Wikimedia, CC BY-SA) ; Petrocchi 1887 pour 2 397 verbes (domaine public, OCR archive.org) ; angl. Wiktionary en secours (6 653 verbes sans article natif) |
| pt | 6 084 | 5 600 | Moteur maison ; enrichissement Wiktionary vérifié forme par forme, tous les verbes du Wiktionary conservés | pt. Wiktionary en tête (3 703 verbes, dump Wikimedia, CC BY-SA) ; Figueiredo 1913 pour 3 423 verbes (domaine public, OCR archive.org) ; angl. Wiktionary en secours (2 376 verbes sans article natif) |
| pl | 9 064 | 9 064 | Moteur `Pl` ; extraction du Wiktionary polonais via kaikki, verbe accepté seulement si toutes les formes prédites correspondent ; 125 verbes fréquents réintégrés verbatim | Définitions natives du pl.wiktionary pour 4 378 verbes (dumps Wikimedia, CC BY-SA 4.0), sinon glossaires anglais du Wiktionary (kaikki.org), CC BY-SA 4.0 |
| cs | 4 143 | 4 143 | Moteur `Cs` ; même procédé ; 21 verbes fréquents réintégrés verbatim | Définitions natives du cs.wiktionary pour 1 931 verbes (dumps Wikimedia, CC BY-SA 4.0), sinon glossaires anglais du Wiktionary (kaikki.org), CC BY-SA 4.0 |
| ro | 6 970 | 6 970 | Moteur `Ro` ; extraction du Wiktionary via tous les wiktionary (kaikki), table de conjugaison ro-conj complète requise, toutes les formes copiées verbatim ; futur, conditionnel et parfait composé assemblés sur l'appareil depuis les auxiliaires réguliers (a vrea, a avea) | Définitions natives du ro.wiktionary pour 5 437 verbes (dumps Wikimedia, CC BY-SA 4.0), sinon glossaires anglais du Wiktionary (kaikki.org), CC BY-SA 4.0 |

Détail du procédé :

- **fr/en/es/de/it/pt** : les formes sont calculées sur l'appareil par le
  moteur maison à partir de chaînes compactes (radical + terminaisons du
  projet web Vibetab). La base a été enrichie de verbes extraits du
  Wiktionary via l'extraction kaikki.org/wiktextract : chaque forme
  extraite a été comparée à celle prédite par le moteur ; les formes ou
  verbes non conformes sont rejetés. La source de chaque verbe
  (« générateur » ou « Wiktionary ») est stockée dans la base (`vsrc`)
  et affichée sur sa fiche.
- **pl/cs** : moteurs écrits pour l'app. Extraction des Wiktionary
  polonais et tchèque via kaikki.org (wiktextract) ; un verbe n'entre
  dans la base que si 100 % des formes prédites par les règles
  (présent, passé, conditionnel, impératif) coïncident avec le Wiktionary.
  Les verbes rejetés ont été croisés avec les listes de fréquence
  OpenSubtitles (hermitdave/FrequencyWords, rang ≤ 5000) : les 146 plus
  courants (125 pl, 21 cs, dont zobaczyć, wziąć, pójść, muset…) sont
  réintégrés en « exceptions » avec indicatif, passé et impératif
  copiés verbatim du Wiktionary, le conditionnel dérivé du participe
  (conforme aux formes du Wiktionary) et, pour les rares passés
  incomplets (wziąć), les 1re/2e personnes dérivées des 3es par les
  suffixes réguliers.
- **ro** : moteur écrit pour l'app. Extraction du Wiktionary via
  l'extraction anglaise kaikki.org (wiktextract) ; un verbe n'entre
  dans la base que si sa table de conjugaison ro-conj est complète
  (présent, imparfait, parfait simple, plus-que-parfait, subjonctif,
  impératif 2e personne, participe passé, gérondif) ; toutes les formes
  sont copiées verbatim (l'impératif négatif et les formes marquées
  régionales, colloquiales ou archaïques sont écartées). Le futur
  (voi/vei/va/vom/veți/vor), le conditionnel (aș/ai/ar/am/ați/ar) et
  le parfait composé (am/ai/a/am/ați/au) sont assemblés sur l'appareil
  avec les auxiliaires réguliers (a vrea, a avea), l'infinitif porte
  la préposition « a » (a lucra) et l'infinitif passé « a fi » +
  participe. Chaque verbe retenu doit avoir un glossaire anglais ;
  les mots sans conjugaison complète ou sans définition sont écartés
  (règle « sans définition ⇒ retiré »).
- **Essais de filtrage par dictionnaire du domaine public (abandonnés)** :
  pour que chaque verbe ait une définition ancienne et libre de droits,
  plusieurs filtres ont été successivement appliqués puis retirés :
  - *EN (abandonné)* : limite au Webster 1913 des verbes qu'il définit
    ( `outils/filtre_webster.py` ) - la limitation a été abandonnée, le
    Webster ne fournit plus que des définitions là où il définit ;
  - *PT (abandonné)* : remplacement des glossaires par le Novo Diccionario
    da Lingua Portugueza ( Cândido de Figueiredo, 1913 ) via
    `outils/parse_figueiredo.py` et `outils/filtre_figueiredo.py`, retrait
    des 1 292 verbes absents ( controlar, vetar, detectar, financiar… ) ;
  - *IT (abandonné)* : remplacement des glossaires par le Nòvo dizionàrio
    universale ( Pietro Petrocchi, 1887 ) puis, à défaut, le Dizionario
    della Crusca ( éd. Costa-Cardinali, 1819 ) via
    `outils/parse_petrocchi.py`, `outils/parse_crusca.py` et
    `outils/filtre_italien.py`, retrait des 5 611 verbes absents
    ( filmare, idrogenare, cristianizzare… ). L'OCR de l'édition
    tomaseobellini.it et celui, isolé et incomplet, de 1912 avaient été
    écartés.
  Décision finale : conserver **tous** les verbes du Wiktionary ; les
  définitions de restent les glossaires anglais (CC BY-SA 4.0) ; les
  définitions it/pt sont depuis remplacées par Petrocchi 1887 et
  Figueiredo 1913 via `outils/dictionnaires_pd.py` (version 1.3.0) ;
  en allemand, l'OCR Fraktur d'archive.org étant inutilisable, un OCR
  maison ( Tesseract modele frk, tessdata_best, 400 dpi, 1 908 pages,
  sorties modulables TXT / CSV pages / CSV mots / hOCR / TSV ) a été
  produit sur les PDF images, et `outils/sanders_extract.py` (version
  1.4.0) remplace les définitions de 205 verbes par celles du Sanders
  1876 ( releve revu à la main : les têtes d'entrées perdues par l'OCR
  laissent des verbes fréquents non couverts ; la liste noire des
  gloses écartées est dans le script ) ;
  orthographe modernisée ( version 1.4.1 ) : l'app étant destinée à
  de jeunes utilisateurs, `outils/orthographe.py` passe les
  définitions des trois dictionnaires PD à l'orthographe actuelle
  ( allemand : réforme de 1901 ; italien : accents de syllabe
  interne, mejjo->meglio ; portugais : norme européenne,
  graphies pre-AO90 + accents abolis en 1945/1971 ), 2 244 sens
  sur 6 937, sans toucher aux autres lots ; corrections vérifiées
  hors ligne contre LanguageTool ( de : aucune erreur ; it/pt : seuls
  des mots rares mais valides ) ; `outils/coquilles_ocr.py`
  ( version 1.4.2 ) corrige en outre les coquilles OCR certaines
  ( fich->sich, dur<->durch, superfice->superficie, ob jeto->objeto,
  prospector rétabli ), revues une par une en contexte ;
- **Double affichage Wiktionary + domaine public ( version 1.4.3 )** :
  pour it/pt/de, les verbes couverts par Petrocchi/Figueiredo/Sanders
  retrouvent leurs glosses anglais du Wiktionary en tête ( 8 914 sens :
  5 743 verbes restaurés depuis la brute 1.2.2, 1 238 verbes centraux
  relevés via l'API MediaWiki du Wiktionary anglais par
  `outils/ajouter_wikt.py` ; 13 verbes niche sans glose Wikt restent
  en PD seul ), la définition native du dictionnaire du domaine public
  venant ensuite ; aucune définition n'est supprimée ;
  les six scripts de filtrage restent dans `outils/` pour référence.
- **Affichage « Wiktionary de la langue d'abord » ( version 1.5.0 )** :
  pour fr/es/it/pt/de, chaque verbe ayant un article VERBE dans le
  Wiktionary de sa langue ( dump Wikimedia, section Verbe uniquement )
  reçoit en TETE de fiche ses sens natifs, étiquetés
  « fr. Wiktionnaire » / « es. » / « it. » / « pt. » / « de. Wiktionary »
  ( `outils/dump_natif.py` + `outils/natifs_wikt.py` ; 64 035 sens :
  fr 18 898, es 11 603, it 9 769, pt 9 063, de 14 702 ). Ces verbes
  perdent leur glose anglaise ; elle ne subsiste que pour les verbes
  sans article natif ( it 6 653, pt 2 376, de 431 verbes ), rangée
  avant le dictionnaire du domaine public en attendant leur traduction
  ( etiquette prevue « angl. Wiktionary, trad. » ) ; les dictionnaires
  du domaine public suivent ensuite.
- **Lot 1 de traduction des gloses anglaises de secours
  ( version 1.5.1 )** : `outils/traduire_wikt.py` applique le lot
  manuel `outils/traduits_de.json` et traduit aussi les renvois
  (« alternative form of X », « obsolete spelling of X »...) par
  motifs revus ; etiquette et source « angl. Wiktionary, trad. ».
  1 517 sens traduits : allemand COMPLET ( 431 verbes : 316 gloses
  traduites a la main, 115 renvois ), it 827 et pt 259 renvois ;
  restent en anglais it 5 826 et pt 2 117 verbes a vraie glose
  ( lots suivants ).
- **Lot 2 de traduction, italien ( version 1.5.2 )** : nouveau motif
  « reflexive of X » traduit automatiquement en « Forma riflessiva
  di X » ( 895 verbes ) + lot manuel revu `outils/traduits_it.json`
  ( 750 gloses courtes traduites une a une ). 1 645 sens italiens
  traduits ce lot ; restent en italien 4 181 verbes a vraie glose
  anglaise et 2 117 en portugais ( lots suivants ). Etiquette et
  source « angl. Wiktionary, trad. » ; total inchange : 176 650 sens,
  0 sans source.
- **Lot 3 de traduction, italien ( version 1.5.3 )** : lot manuel revu
  `outils/traduits_it.json` : 950 gloses courtes traduites une a une
  et 14 « reflexive of X : glose » rendues en « Forma riflessiva
  di X : ... ». 964 sens italiens traduits ce lot ; restent en
  italien 3 217 verbes a vraie glose anglaise et 2 117 en
  portugais ( lots suivants ). Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 650 sens,
  0 sans source.
- **Lot 4 de traduction, italien + portugais ( version 1.5.4 )** :
  premier lot bilingue : 200 gloses italiennes et 200 portugaises,
  les plus courtes, traduites une a une ( `outils/traduits_it.json`
  et nouveau `outils/traduits_pt.json` ). 400 sens traduits ce
  lot ; restent en italien 3 017 verbes a vraie glose anglaise et
  1 917 en portugais ( lots suivants ). Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 650 sens,
  0 sans source.
- **Lot 5 de traduction, italien + portugais ( version 1.5.5 )** :
  suite du lot bilingue : 200 gloses italiennes et 200 portugaises
  suivantes, traduites une a une ( `outils/traduits_it.json` et
  `outils/traduits_pt.json` ). 400 sens traduits ce lot ; restent
  en italien 2 817 verbes a vraie glose anglaise et 1 717 en
  portugais ( lots suivants ). Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 650 sens,
  0 sans source.
- **Lot 6 de traduction, italien + portugais ( version 1.5.6 )** :
  suite : 200 gloses italiennes et 200 portugaises suivantes,
  traduites une a une ( `outils/traduits_it.json` et
  `outils/traduits_pt.json` ). 400 sens traduits ce lot ; restent
  en italien 2 617 verbes a vraie glose anglaise et 1 517 en
  portugais ( lots suivants ). Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 650 sens,
  0 sans source.
- **Comblement des définitions polonaises, Słownik warszawski
  ( version 1.5.7 )** : l'OCR archive.org du Słownik języka polskiego
  dit « warszawski » ( Karłowicz, Kryński, Niedźwiedzki, 1900-1927,
  8 vol., domaine public ) est en fait exploitable, contrairement au
  diagnostic initial. De nouvelles définitions natives du domaine
  public remplacent la glose anglaise de 2 245 verbes polonais
  ( 2 536 sens, au plus 3 par verbe, renvois « p. X » compris ;
  `outils/dictionnaires_pd_pl.py`, etiquette et source
  « Słownik warszawski 1900 », OCR conservé tel quel, coquilles
  comprises ). Restent 2 441 verbes polonais a glose anglaise
  ( « angl. Wiktionary » ), 2 617 italiens et 1 517 portugais a
  traduire ( lots suivants ). Total : 176 941 sens ( +291, un sens
  anglais remplace par un a trois sens du dictionnaire ), 0 sans
  source.
- **Lot 7 de traduction, italien + portugais ( version 1.5.8 )** :
  suite : 200 gloses italiennes et 200 portugaises suivantes,
  traduites une a une ( `outils/traduits_it.json` et
  `outils/traduits_pt.json` ). 400 sens traduits ce lot ; restent
  en italien 2 417 verbes a vraie glose anglaise et 1 317 en
  portugais ( lots suivants ). Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 8 de traduction, italien + portugais ( version 1.5.9 )** :
  suite : 200 gloses italiennes et 200 portugaises suivantes,
  traduites une a une ( `outils/traduits_it.json` et
  `outils/traduits_pt.json` ). 400 sens traduits ce lot ; restent
  en italien 2 217 verbes a vraie glose anglaise et 1 117 en
  portugais ( lots suivants ). Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 9 de traduction, italien + portugais ( version 1.5.10 )** :
  suite : 200 gloses italiennes et 200 portugaises suivantes,
  traduites une a une ( `outils/traduits_it.json` et
  `outils/traduits_pt.json` ). 400 sens traduits ce lot ; restent
  en italien 2 017 verbes a vraie glose anglaise et 917 en
  portugais ( lots suivants ). Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 10 de traduction, italien + portugais ( version 1.5.11 )** :
  suite : 200 gloses italiennes et 200 portugaises suivantes,
  traduites une a une ( `outils/traduits_it.json` et
  `outils/traduits_pt.json` ). 400 sens traduits ce lot ; restent
  en italien 1 817 verbes a vraie glose anglaise et 717 en
  portugais ( lots suivants ). Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 11 de traduction, italien + portugais ( version 1.5.12 )** :
  suite : 200 gloses italiennes et 200 portugaises suivantes,
  traduites une a une ( `outils/traduits_it.json` et
  `outils/traduits_pt.json` ). 400 sens traduits ce lot ; restent
  en italien 1 617 verbes a vraie glose anglaise et 517 en
  portugais ( lots suivants ). Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 12 de traduction, italien + portugais ( version 1.5.13 )** :
  suite : 200 gloses italiennes et 200 portugaises suivantes,
  traduites une a une ( `outils/traduits_it.json` et
  `outils/traduits_pt.json` ). 400 sens traduits ce lot ; restent
  en italien 1 417 verbes a vraie glose anglaise et 317 en
  portugais ( lots suivants ). Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 13 de traduction, italien + portugais ( version 1.5.14 )** :
  suite : 200 gloses italiennes et 200 portugaises suivantes,
  traduites une a une ( `outils/traduits_it.json` et
  `outils/traduits_pt.json` ). 400 sens traduits ce lot ; restent
  en italien 1 217 verbes a vraie glose anglaise et 117 en
  portugais ( lots suivants ). Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 14 de traduction, italien + portugais ( version 1.5.15 )** :
  suite : 200 gloses italiennes et les 27 portugaises restantes a
  glose unique courte, traduites une a une ( `outils/traduits_it.json`
  et `outils/traduits_pt.json` ). 227 sens traduits ce lot ; restent
  en italien 1 017 verbes a vraie glose anglaise et 90 en portugais
  ( multi-sens ou gloses longues, a traiter autrement ).
  Etiquette et source « angl. Wiktionary, trad. » ; total inchange :
  176 941 sens, 0 sans source.
- **Lot 15 de traduction, italien + portugais ( version 1.5.16 )** :
  suite : 200 gloses italiennes et les 90 portugais restants,
  traduits sens par sens pour les multi-sens ( 184 sens pt,
  gloses uniques ou multiples, traductions per-sens ;
  `outils/traduits_it.json` et `outils/traduits_pt.json` ).
  384 sens traduits ce lot ; le portugais est EPUISE :
  0 verbe a glose anglaise restant ; restent en italien 817
  verbes a vraie glose anglaise. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 16 de traduction, italien ( version 1.5.17 )** :
  suite : 200 gloses italiennes suivantes, uniques et
  d'au plus 95 caracteres ( `outils/traduits_it.json` ).
  200 sens traduits ce lot ; le portugais reste EPUISE ;
  restent en italien 613 verbes ( 641 sens ) a vraie
  glose anglaise, puis 2 441 verbes polonais.
  Etiquette et source « angl. Wiktionary, trad. » ;
  total inchange : 176 941 sens, 0 sans source.
- **Lot 17 de traduction, italien ( version 1.5.18 )** :
  suite : 200 gloses italiennes suivantes, uniques et
  d'au plus 95 caracteres ( `outils/traduits_it.json` ).
  200 sens traduits ce lot ; le portugais reste EPUISE ;
  restent en italien 413 verbes ( 441 sens ) a vraie
  glose anglaise, puis 2 441 verbes polonais.
  Etiquette et source « angl. Wiktionary, trad. » ;
  total inchange : 176 941 sens, 0 sans source.
- **Lot 18 de traduction, italien ( version 1.5.19 )** :
  suite : 200 gloses italiennes suivantes, uniques et
  d'au plus 95 caracteres ( `outils/traduits_it.json` ).
  200 sens traduits ce lot ; le portugais reste EPUISE ;
  restent en italien 213 verbes ( 241 sens ) a vraie glose
  anglaise : les gloses uniques courtes s'epuisent,
  restent les multi-sens et gloses longues ; puis 2 441
  verbes polonais. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 19 de traduction, italien : EPUISEMENT ( version 1.5.20 )** :
  solde italien : 213 verbes restants ( 241 sens ), traduits
  sens par sens pour les multi-sens ( 14 verbes multi-sens,
  gloses uniques ou multiples ; `outils/traduits_it.json` ).
  241 sens traduits ce lot ; L'ITALIEN EST EPUISE : 0 verbe a
  glose anglaise restant ; le portugais restait deja EPUISE ;
  restent 2 441 verbes polonais a glose anglaise.
  Etiquette et source « angl. Wiktionary, trad. » ;
  total inchange : 176 941 sens, 0 sans source.
- **Lot 1 de traduction, polonais ( version 1.5.21 )** :
  suite de l'italien et du portugais ( tous deux EPUISES ) :
  200 gloses polonaises, uniques et d'au plus
  95 caracteres, traduites en polonais ( nouveau
  `outils/traduits_pl.json` ; le lot manuel couvre desormais
  le polonais dans `outils/traduire_wikt.py` ). En rattrapage,
  4 gloses italiennes ressiduelles d'une autre source ont
  ete traduites le meme lot ( traduits_it.json ).
  204 sens traduits ce lot ; restent 2 241 verbes polonais a
  glose anglaise. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 2 de traduction, polonais ( version 1.5.22 )** :
  suite : 200 gloses polonaises suivantes, uniques et
  d'au plus 95 caracteres ( `outils/traduits_pl.json` ).
  200 sens traduits ce lot ; restent 2 041 verbes
  polonais a glose anglaise. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 3 de traduction, polonais ( version 1.5.23 )** :
  suite : 200 gloses polonaises suivantes, uniques et
  d'au plus 95 caracteres ( `outils/traduits_pl.json` ).
  200 sens traduits ce lot ; restent 1 841 verbes
  polonais a glose anglaise. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 4 de traduction, polonais ( version 1.5.24 )** :
  suite : 200 gloses polonaises suivantes, uniques et
  d'au plus 95 caracteres ( `outils/traduits_pl.json` ).
  200 sens traduits ce lot ; restent 1 641 verbes
  polonais a glose anglaise. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 5 de traduction, polonais ( version 1.5.25 )** :
  suite : 200 gloses polonaises suivantes, uniques et
  d'au plus 95 caracteres ( `outils/traduits_pl.json` ).
  200 sens traduits ce lot ; restent 1 441 verbes
  polonais a glose anglaise. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 6 de traduction, polonais ( version 1.5.26 )** :
  suite : 200 gloses polonaises suivantes, uniques et
  d'au plus 95 caracteres ( `outils/traduits_pl.json` ).
  200 sens traduits ce lot ; restent 1 241 verbes
  polonais a glose anglaise. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 7 de traduction, polonais ( version 1.5.27 )** :
  suite : 200 gloses polonaises suivantes, uniques et
  d'au plus 95 caracteres ( `outils/traduits_pl.json` ).
  200 sens traduits ce lot ; restent 1 041 verbes
  polonais a glose anglaise. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 8 de traduction, polonais ( version 1.5.28 )** :
  suite : 200 gloses polonaises suivantes, uniques et
  d'au plus 95 caracteres ( `outils/traduits_pl.json` ).
  200 sens traduits ce lot ; restent 841 verbes
  polonais a glose anglaise. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 9 de traduction, polonais ( version 1.5.29 )** :
  suite : 200 gloses polonaises suivantes, uniques et
  d'au plus 95 caracteres ( `outils/traduits_pl.json` ).
  200 sens traduits ce lot ; restent 641 verbes
  polonais a glose anglaise. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 10 de traduction, polonais ( version 1.5.30 )** :
  suite : 200 gloses polonaises suivantes, uniques et
  d'au plus 95 caracteres ( `outils/traduits_pl.json` ).
  200 sens traduits ce lot ; restent 441 verbes
  polonais a glose anglaise. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 11 de traduction, polonais ( version 1.5.31 )** :
  suite : 300 gloses polonaises suivantes, uniques et
  d'au plus 95 caracteres pour la plupart ( `outils/traduits_pl.json` ).
  300 sens traduits ce lot ; restent 141 verbes
  polonais a glose anglaise. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 12 de traduction, polonais ( version 1.5.32 )** :
  suite et fin : 141 dernieres gloses polonaises suivantes ( plus de
  95 caracteres ; `outils/traduits_pl.json` ). 141 sens traduits ce
  lot ; polonais EPUISE. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 13 de traduction, français + extension du traducteur ( version 1.5.33 )** :
  le traducteur `outils/traduire_wikt.py` couvre desormais aussi le
  tcheque et le roumain, et traite les gloses anglaises restees sans
  etiquette ( fr, es ). 300 gloses françaises traduites à la main
  ( `outils/traduits_fr.json`, nouveau ) plus 1 187 renvois
  automatiques ( fr 81, es 438, cs 29, ro 639 ). 1 487 sens traduits
  ce lot ; restent 1 052 gloses françaises, 3 222 espagnoles,
  2 183 tcheques, 894 roumaines. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 14 de traduction, français ( version 1.5.34 )** :
  suite : 300 gloses françaises suivantes ( `outils/traduits_fr.json`,
  600 entrees cumulees ). 300 sens traduits ce lot ; restent 752
  gloses françaises, 3 222 espagnoles, 2 183 tcheques,
  894 roumaines. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 15 de traduction, français ( version 1.5.35 )** :
  suite : 300 gloses françaises suivantes ( `outils/traduits_fr.json`,
  900 entrees cumulees ). 300 sens traduits ce lot ; restent 452
  gloses françaises, 3 222 espagnoles, 2 183 tcheques,
  894 roumaines. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 16 de traduction, français ( version 1.5.36 )** :
  suite et fin : 452 gloses françaises restantes ( `outils/traduits_fr.json`,
  1 352 entrees cumulees ). 452 sens traduits ce lot ; français EPUISE ;
  restent 3 222 gloses espagnoles, 2 183 tcheques,
  894 roumaines. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 17 de traduction, espagnol ( version 1.5.37 )** :
  premiere tranche espagnole : 300 gloses espagnoles
  ( `outils/traduits_es.json`, 300 entrees ). 300 sens traduits
  ce lot ; restent 2 922 gloses espagnoles, 2 183 tcheques,
  894 roumaines. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 18 de traduction, espagnol ( version 1.5.38 )** :
  suite : 300 gloses espagnoles suivantes ( `outils/traduits_es.json`,
  600 entrees cumulees ). 300 sens traduits ce lot ; restent 2 622
  gloses espagnoles, 2 183 tcheques, 894 roumaines. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 19 de traduction, espagnol ( version 1.5.39 )** :
  suite : 300 gloses espagnoles suivantes ( `outils/traduits_es.json`,
  900 entrees cumulees ). 300 sens traduits ce lot ; restent 2 322
  gloses espagnoles, 2 183 tcheques, 894 roumaines. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 20 de traduction, espagnol ( version 1.5.40 )** :
  suite : 300 gloses espagnoles suivantes ( `outils/traduits_es.json`,
  1 200 entrees cumulees ). 300 sens traduits ce lot ; restent 2 022
  gloses espagnoles, 2 183 tcheques, 894 roumaines. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 21 de traduction, espagnol ( version 1.5.41 )** :
  suite : 300 gloses espagnoles suivantes ( `outils/traduits_es.json`,
  1 500 entrees cumulees ). 300 sens traduits ce lot ; restent 1 722
  gloses espagnoles, 2 183 tcheques, 894 roumaines. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 22 de traduction, espagnol ( version 1.5.42 )** :
  suite : 300 gloses espagnoles suivantes ( `outils/traduits_es.json`,
  1 800 entrees cumulees ). 300 sens traduits ce lot ; restent 1 422
  gloses espagnoles, 2 183 tcheques, 894 roumaines. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 23 de traduction, espagnol ( version 1.5.43 )** :
  suite : 500 gloses espagnoles suivantes ( `outils/traduits_es.json`,
  2 300 entrees cumulees ). 500 sens traduits ce lot ; restent 922
  gloses espagnoles, 2 183 tcheques, 894 roumaines. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 24 de traduction, espagnol ( version 1.5.44 )** :
  suite : 500 gloses espagnoles suivantes ( `outils/traduits_es.json`,
  2 800 entrees cumulees ). 500 sens traduits ce lot ; restent 422
  gloses espagnoles, 2 183 tcheques, 894 roumaines. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 25 de traduction, espagnol ( version 1.5.45 )** :
  suite : 422 gloses espagnoles suivantes ( `outils/traduits_es.json`,
  3 222 entrees cumulees ). 422 sens traduits ce lot ; espagnol EPUISE.
  Restent 2 183 gloses tcheques, 894 roumaines. Etiquette et source
  « angl. Wiktionary, trad. » ; total inchange : 176 941 sens,
  0 sans source.
- **Lot 26 de traduction, tcheque ( version 1.5.46 )** :
  suite : 500 gloses tcheques suivantes ( `outils/traduits_cs.json`,
  500 entrees cumulees ). 500 sens traduits ce lot ; restent
  1 683 gloses tcheques, 894 roumaines. Espagnol EPUISE. Etiquette
  et source « angl. Wiktionary, trad. » ; total inchange :
  176 941 sens, 0 sans source.
- **Lot 27 de traduction, tcheque ( version 1.5.47 )** :
  suite : 500 gloses tcheques suivantes ( `outils/traduits_cs.json`,
  1 000 entrees cumulees ). 500 sens traduits ce lot ; restent
  1 183 gloses tcheques, 894 roumaines. Etiquette
  et source « angl. Wiktionary, trad. » ; total inchange :
  176 941 sens, 0 sans source.
- **Lot 28 de traduction, tcheque ( version 1.5.48 )** :
  suite : 500 gloses tcheques suivantes ( `outils/traduits_cs.json`,
  1 500 entrees cumulees ). 500 sens traduits ce lot ; restent
  683 gloses tcheques, 894 roumaines. Etiquette
  et source « angl. Wiktionary, trad. » ; total inchange :
  176 941 sens, 0 sans source.
- **Lot 29 de traduction, tcheque ( version 1.5.49 )** :
  suite : 500 gloses tcheques suivantes ( `outils/traduits_cs.json`,
  2 000 entrees cumulees ). 500 sens traduits ce lot ; restent
  183 gloses tcheques, 894 roumaines. Etiquette
  et source « angl. Wiktionary, trad. » ; total inchange :
  176 941 sens, 0 sans source.
- **Lot 30 de traduction, tcheque ( version 1.5.50 )** :
  clôture : 183 gloses tcheques suivantes ( `outils/traduits_cs.json`,
  2 183 entrees cumulees ). 183 sens traduits ce lot ;
  TCHEQUE EPUISE. Restent 894 gloses roumaines ( derniere langue ).
  Etiquette et source « angl. Wiktionary, trad. » ; total inchange :
  176 941 sens, 0 sans source.
- **Lot 31 de traduction, roumain ( version 1.5.51 )** :
  ouverture du roumain : 500 gloses roumaines suivantes
  ( `outils/traduits_ro.json`, 500 entrees cumulees ). 500 sens traduits
  ce lot ; restent 394 gloses roumaines ( derniere langue ).
  Etiquette et source « angl. Wiktionary, trad. » ; total inchange :
  176 941 sens, 0 sans source.
- **Lot 32 de traduction, roumain ( version 1.5.52 )** :
  clôture : 394 gloses roumaines suivantes ( `outils/traduits_ro.json`,
  894 entrees cumulees ). 394 sens traduits ce lot ;
  ROUMAIN EPUISE. TOUTES LES LANGUES SONT EPUISEES.
  Etiquette et source « angl. Wiktionary, trad. » ; total inchange :
  176 941 sens, 0 sans source.
- **Lot 33 de nettoyage, OCR residuel et templates ( version 1.5.53 )** :
  68 gloses retouchees ( residus OCR : Sanders 1876, Petrocchi 1887,
  Slownik warszawski 1900, ligatures du glossaire angl. Wiktionary ) et
  593 gloses italiennes normalisees ( templates wiki casses
  « {Term|...}} » convertis en etiquettes textuelles ;
  cf. outils/nettoie_ocr2.py ). Plus aucun residu detecte ;
  total inchange : 176 941 sens, 0 sans source.
- **Lot 60 de la precision des frontieres de la carte du monde ( base 1.5.65 )** : la couche frontieres du monde quitte la generalisation 1:110M du site pour Natural Earth 1:10M simplifiee a 0,008 degre : 3 992 anneaux fermes et 218 243 sommets ( vingt fois les 10 562 d avant ), segment median de 0,054 degre contre 0,71, ecarts de simplification sous 0,008 degre ( moins d un kilometre ), les trous gardent leur orientation pour le remplissage. La base embarquee ne voyage pas en binaire par la liaison : outils/frontieres_10m.py regenere la couche dans assets/lestang_outils.db depuis outils/monde-frontieres-10m.b64 ( python3 outils/frontieres_10m.py ), passe la meta et databaseVersion a 1.5.65 puis compacte la base ; executer le script une fois puis livrer la base regeneree.
- **Lot 59 des libelles hors glossaire, du chinois traditionnel, de la meteo et du fond bleu ( code seul, base 1.5.64 inchangee )** : tout libelle embarque passe par le glossaire : groupes et boites des reglages des cartes, styles et centrages du monde, frontieres contestees et leurs vues, villes marquees, infobulles des barres des cartes, barre d etat, codes meteo et noms des sources, traduits en anglais et en chinois, le francais reste le repli. Le chinois se decline en simplifie ( zh-Hans ) et traditionnel ( zh-Hant ), la langue systeme suit l ecriture de la plateforme. La meteo lit en celsius ( le service NWS servait du fahrenheit, qui faussait l affichage ), montre la lune quand la ville est dans la nuit et choisit son unite : le reglage degres Celsius ou Fahrenheit persiste a cote de la recherche. Le fond de la fenetre porte un degrade bleu clair du site, bleu-50 a bleu-200 en theme clair, bleu nuit en theme sombre, dans la fenetre comme en plein ecran.
- **Lot 58 du correctif de la barre d etat et de la traduction chinoise ( code seul, base 1.5.64 inchangee )** : le front-end Windows de Flutter n expose pas ProcessInfo de dart:developer : la memoire residente de la barre d etat est lue directement aupres du systeme, GetProcessMemoryInfo de psapi sur Windows via dart:ffi, /proc/self/statm sur Linux et Android, 0 sinon ( la barre affiche alors les workers seuls ). L interface est traduite en chinois : septieme langue du reglage Langue ( 中文 ), glossaire zh complet, repli francais pour les libelles embarques hors glossaire.
- **Lot 57 du theme bleu, de la barre d horloge du monde et de la barre d etat ( code seul, base 1.5.64 inchangee )** : la famille de couleurs de l application passe du violet par defaut de Material 3 au bleu clair du site web ( PATCH213 de styles.css ) : le scheme deriver de la graine #3b82f6 habille chips, curseurs, commutateurs et boutons des deux themes, la barre de titre des deux fenetres porte le degrade du web ( #2563eb, #3b82f6 puis #60a5fa en diagonale, texte blanc ). Le rectangle derriere le globe du monde est grise : en Equal Earth le degrade ocean ne peint plus que l interieur de l ovale ( les quatre coins restaient ocean ), le gris suit le theme clair ou sombre. La barre du haut du monde suit l ordre du web : curseur des demi-heures, heure, fleche du jour precedent, date seule sans icone, fleche du jour suivant, retour au present, reglages ; le calendrier borne a l annee disparait, les fleches traversent le passage de l annee. Une barre d etat s ajoute au pied des deux fenetres : la memoire residente du processus ( currentRss ) et le nombre de workers ( l isolat principal plus les isolats de fond que l application lancera ) rafraichis toutes les deux secondes. Code Dart uniquement, base embarquee inchangee.
- **Lot 56 ter de corrections visuelles de la carte du monde ( code seul, base 1.5.64 inchangee )** : les pieces coupees a la couture ( ringClip ), la grille et les fuseaux arrivent dans la fenetre du centrage ( center - 180 a center + 180 ) mais etaient re-enroules une seconde fois par la fonction de recentrage : les deux meridiens de bord se repliaient l un sur l autre, des bandes entieres inversaient leurs couleurs, des lignes horizontales traversaient la carte en mode plat et les fuseaux horaires s empilaient sur une diagonale. Le plan ne recadre plus que les longitudes brutes ( villes, infobulle ), les pieces de la fenetre sont projetees telles quelles. L equateur, les tropiques et les cercles polaires ne se tracaient pas : leurs deux extremites brutes ( -180 et 180 ) sont le meme meridien une fois recadre, le parallele est maintenant echantillonne d un bord a l autre de la fenetre. Les frontieres des fuseaux perdaient leur latitude a l analyse de la chaine ( seul le premier nombre etait garde ), les vraies limites Natural Earth s affichent. Le trait des frontieres peut etre eteint seul : les continents restent peints, seul le contour suit le commutateur. Le point du soleil et les pointilles contestes subsistent quel que soit le centrage. Code Dart uniquement, base embarquee inchangee.
- **Lot 56 des options du web pour la carte du monde ( code seul, base 1.5.64 inchangee )** : les options de la carte du monde du site web arrivent dans l application, reprises de js/monde/carte-monde.js. Le point subsolaire du soleil s affiche ( disque jaune a liseré sombre ), l equateur en trait plein et les tropiques et cercles polaires en pointilles suivent le style choisi, les fuseaux horaires de Natural Earth se tracent en tiretes avec la meme coupe a la couture que les frontieres ( ringClip ), la projection Equal Earth ou equirectangulaire plate se choisit par un commutateur, huit frontieres contestees s ouvrent dans leur propre boite ( Crimee, Cachemire et Aksai Chin, Taiwan, Sahara occidental, Kosovo, Chypre, Golan, Essequibo ) : chaque vue choisie efface le trait solide de la zone et le remplace par des pointilles, le centrage corrige Oceanie a 150 E ( PATCH125 du web ). La liste des villes marquees etait celle d Europe par erreur : elle est remplacee par WM_CITYLIST du web, 500 villes du monde. Les horloges des villes marquees s affichent sous le curseur des demi-heures : zones IANA reelles ( package timezone, heure d ete comprise ), repli sur la longitude marque d un tilde, tri ouest en est puis nord en sud, mise a jour toutes les trente secondes tant que l utilisateur n a pas choisi son instant. Code Dart uniquement, donnees et base embarquee inchangees.
- **Lot 55 de l anglicisation du code et de la couture antiméridien du web ( code seul, base 1.5.64 inchangee )** : les repertoires, fichiers, classes, fonctions et commentaires passent a l anglais dans toute l application ( lib/bdd.dart devient lib/database.dart, lib/registre.dart lib/card_registry.dart, lib/sauvegarde.dart lib/backup.dart, lib/cartes/ devient lib/maps/, lib/ecrans/ devient lib/screens/, lib/conj/moteurs.dart et socle.dart deviennent engines.dart et core.dart ), les libelles affiches et les cles du glossaire restent en francais. La couture antiméridien du site web arrive dans la carte du monde : wmRingClip et wmStrokeClipped de js/monde/carte-monde.js sont portes en Dart ( ringClip et strokeClipped ), le triangle aux couleurs inversees du nord-est de la Coree du Nord au nord-est de la Russie disparait et les centrages ne creent plus d inversion de couleurs, les anneaux sont deplies en longitudes continues autour du meridien choisi puis rognes par Sutherland-Hodgman en longitude seule, avec les copies a plus ou moins 360 degres qui chevauchent la couture. Code Dart uniquement, donnees et base embarquee inchangee.
- **Lot 54 du centrage, des villes marquees, du calendrier et du liseré du globe ( code seul, base 1.5.64 inchangee )** : le liseré du tour du monde devenait invisible sur le fond ocean ( trop proche du degrade ) : il passe a 2,5 px et prend une couleur tranchee par style ( parchemin sur ocean, clair sur nuit, sombre sur encre et croquis ). Le centrage du web revient dans la modale du monde : meridien de Greenwich, Ameriques ou Oceanie au milieu, la projection Equal Earth recadre la terre entiere, le polygone de nuit est refait dans le repere recentre et valide par simulation sur tous les centrages ( ecart maximum 1,8 degres d elevation solaire, quelques heures par an autour des equinoxes ; au passage la branche equinoxiale ancienne encerclait le jour, elle est remplacee par une declinaison bornee a un degre ). Les villes marquees s choisissent desormais une a une dans une boite a part, toutes affichees par defaut, la liste des cachees persiste. Un calendrier borne a l annee en cours s ajoute a cote du curseur des demi-heures, la date s affiche avec l heure. Code Dart uniquement, donnees et base embarquee inchangees.
- **Lot 53 des reglages par modale de chaque carte ( code seul, base 1.5.64 inchangee )** : les modales de reglages du web reviennent dans l application, une par carte, ouvertes par le bouton reglages en tete de carte ( france-modale.js, ueConf de carte-union.js et carte-monde-reglages.js du dossier Drive nouvel-onglet-sources ) : une case par groupe de couches et de points, tout persiste aussitot dans les preferences. France : departements et regions, autoroutes, nationales, departementales, LGV et leurs gares, fleuves, eaux territoriales, villes, transports en Ile-de-France. Union : etats membres, autres pays, eaux territoriales, fleuves, routes europeennes, routes voisines, LGV et gares, capitales, villes, panonceaux des routes. Monde : zone de nuit ( ensoleillement ), frontieres et terres, villes, et le choix du style parmi les quatre WM_STYLES du web ( ocean, nuit, encre, croquis ), le fond, les terres, les frontieres et le voile de nuit suivent le style choisi. Code Dart uniquement, donnees et base embarquee inchangees.
- **Lot 52 du correctif de la zone de nuit et du contour du globe ( code seul, base 1.5.64 inchangee )** : la limite jour / nuit etait inversee, le jour teintait le nord : le premier sommet de la terminatrice, a la longitude -180, sautait au bord est de la carte et le trace la traversait d un bout a l autre ; la longitude -180 reste desormais au bord ouest, et pres des equinoxes la terminatrice quasi verticale est subdivisee par dichotomie pour suivre la courbe. Le fond degrade ocean ne peint plus que le rectangle de la carte et un trait gris bleute arrondi trace le tour du globe, qui se distingue desormais du fond d ecran. Verifie par simulation astronomique : toute erreur residuelle reste a moins d un demi-degre de l horizon solaire. Code Dart uniquement, donnees et base embarquee inchangees.
- **Lot 51 des couleurs de la carte du monde ( code seul, base 1.5.64 inchangee )** : la carte reprend le style ocean du dernier HTML du web ( WM_STYLES.ocean de js/monde/carte-monde.js, source : dossier Drive nouvel-onglet-sources ) : fond en degrade vertical du bleu profond 0xff0b2f63 au bleu azur 0xff155399, terres couleur parchemin 0xffe9e4d3, frontieres gris bleute rgba( 90, 110, 135, 0.55 ), voile de nuit bleu nuit rgba( 3, 8, 22, 0.45 ) sur la seule nuit, villes en rouge 0xffe03131 ; le style ocean ne depend pas du theme clair ou sombre, comme sur le web. Code Dart uniquement, donnees et base embarquee inchangees.
- **Lot 50 de la carte du monde ( code seul, base 1.5.64 inchangee )** : la limite jour / nuit etait fausse pres des bords et des poles : la fermeture du polygone de nuit reliait la courbe terminatrice au pole par deux cordes droites, alors que la projection Equal Earth courbe les meridiens ; des regions entieres se retrouvaient du mauvais cote, et le voile teintait le jour autant que la nuit ; la fermeture suit maintenant les bords de la carte echantillonnes le long des arcs ( meridiens 180 et -180, ligne du pole en nuit ), la nuit seule est voilee, le jour reste clair ; le code du monde ( reglages, zone de nuit, infobulle, couches ) vit desormais dans carte_monde.dart, les styles communs dans styles_cartes.dart, distincts du fichier de l Union europeenne et des DROM-COM. Code Dart uniquement, donnees et base embarquee inchangees.
- **Lot 49 des cartes au zoom ( code seul, base 1.5.64 inchangee )** : les barres horizontales restantes de la carte du monde venaient du passage de l antiméridien : quatre tracés de frontieres sautent de la longitude 180 a -180, le segment dessinait une ligne droite a travers toute la projection ; le tracé se coupe maintenant au bond ( mesure dans le plan, pas en pixels, pour ne pas casser les segments au fort zoom ) ; les etiquettes de villes, elles, etaient nettes mais empilees au zoom ( l Europe surtout ) : chaque pose garde desormais sa place, une etiquette n est plus tracee par-dessus une autre, les couches prioraires ( capitales, grandes villes ) passent avant les petites. Code Dart uniquement, donnees et base embarquee inchangees.
- **Lot 48 de zoom des cartes geographiques ( code seul, base 1.5.64 inchangee )** : au zoom, epaisseurs des traits, rayons des points et tailles des etiquettes restent desormais constants a l ecran ( le peintre contre-calcul par le zoom : jadis l epaisseur croissait comme la racine du zoom en plus du zoom de l InteractiveViewer, les etiquettes gonflaient d autant ) ; les barres horizontales qui traversaient la carte du monde ont disparu : la fermeture des tracés ( close ) s appliquait a toutes les couches, elle dessinait une corde droite du dernier au premier point de chaque polyligne ouverte ( routes, fleuves ), visible en barre au zoom ; la fermeture ne se trace plus que pour les couches de polygones ( departements, contour, membres, autres, hors-ue, frontieres ). Code Dart uniquement, donnees et base embarquee inchangees.
- **Lot 47 de correctif des cartes geographiques ( code seul, base 1.5.64 inchangee )** : les cartes France, Union europeenne et Monde restaient vides, seuls les points et etiquettes des villes s affichaient, quel que soit le theme ; la cause etait le decodage des geometries de la table geo : la lecture des coordonnees float32 partait de l octet 0 du tampon entier ( l en-tete n compris ) au lieu de la sous-vue aligee, tous les polygones etaient donc traces a des coordonnees aberrantes, hors ecran ; la copie aligee des octets des points restaure departements, contours, fleuves, routes et frontieres dans les trois cartes, en themes clair et sombre. Code Dart uniquement, donnees et base embarquee inchangees.
- **Lot 45 de presentation, gabarit de styles, selection par temps et drapeaux rendus ( code seul, base 1.5.64 inchangee )** : la mise en forme des terminaisons et des parentheses remonte a une seule constante du gabarit commun, utilisee par les neuf langues, et s adapte au theme : bordeaux en clair, rose soutenu ( 0xfff2848f, lisible sur fond fonce ) en sombre ; les segments entre parentheses ( participes feminins, marqueurs US/GB ) passent en gris ; l infinitif passe porte enfin sa terminaison surlignee ( fr avoir mange, es haber comido, it avere mangiato, pt ter zicado, de gemacht haben, ro a fi lucrat ) ; la selection de texte se limite a un seul temps a la fois ( chaque carte de temps est sa propre zone de selection, les definitions aussi ), un glissement ne deborde plus sur les temps voisins ; les drapeaux de la barre de navigation se dessinent de nouveau ( les bandes Expanded/ColoredBox ne rendaient pas dans le slot d icone de la NavigationRail, seules les bandes DecoratedBox a taille fixe s affichent ). Code Dart uniquement, donnees et base embarquee inchangees.
- **Lot 44 de presentation, correctifs de surlignage, drapeaux corrects et texte selectionnable ( code seul, base 1.5.64 inchangee )** : les variantes a barre oblique ( es malpariera/malpariese, hubiera/hubiese ) s affichaient colles sans le separateur, la barre revient ; l espace devant la terminaison surlignee d un compose est preserve ( ro ai lucra, sa lucrez, plus les composes des autres langues ) ; les modeles portugais et italiens a formes pleines sans radical encode ( zicar, et les auxiliaires ) retrouvent leurs terminaisons par plus long debut commun ; le participe et le gerondif roumains, les participes it/pt sans radical, sont surlignes par coupe sur l infinitif ; la premiere personne tcheque porte sa terminaison quand elle partage la tige ; les drapeaux sont corriges : tricolores verticaux ( france, italie, roumanie ), portugal vert sur deux cinquiemes et rouge sur trois, union jack dessine pour l anglais ; le texte des planches de conjugaison ( formes et definitions ) est selectionnable a la souris ou a l appui long, sur plusieurs lignes, pour copier, dans toutes les langues. Code Dart uniquement, donnees et base embarquee inchangees.
- **Lot 43 de presentation, terminaisons surlignees et en-tete fixe ( version 1.5.64 )** : la terminaison de chaque personne est surlignee ( rouge fonce, gras ) dans toutes les langues et tous les temps, pas seulement en francais : es tous temps ( y compris compose sur haber et participio ), it et pt meme pour les modeles a forme pleine, de via les modeles et les auxiliaires haben/sein/werden, ro par plus long prefixe commun ( plus table par temps pour les composes ), pl et cs par suffixes calcules par branche ; les formes trop irregulieres ( fi/sunt, essere/sono... ) restent sans surlignage plutot que d afficher une terminaison fausse. L en-tete de l ecran de conjugaison ( nom de la langue, barre de recherche, suggestions ) devient fixe pour les neuf langues : seule la planche du verbe defile. Code Dart uniquement, donnees inchangees.
- **Lot 42bis, retouche des definitions allemandes ( version 1.5.63 )** : revue manuelle des 786 sens Sanders du lot 42 contre l'OCR brut : 307 sens de bruit sont supprimes ( sens venus des articles voisins comme erzen/fischen/haaren/zahlen/wellen, derivatifs nominaux comme Gaffer ou Zund-P., fragments de grammaire et de conjugaison ), 7 sens sont reecrits d'apres l'article reel ( diskutieren, lüpfen, erzen, reimen, ringeln, kropfen, löcken ) et un sens de kropfen est ajoute ; resultat : 480 sens Sanders conserves, aucun verbe ne reste sans definition. Base embarquee meta version 1.5.63.
- **Lot 42 de definitions allemandes ( version 1.5.62 )** : l'extraction du Sanders 1876 est rejouee en multi-sens ( outils/sanders_extract2.py, nouveau ) : 110 verbes passent d'un sens unique a leurs sens multiples ( ex. stammen : 4 sens ), 187 verbes gagnent leurs definitions Sanders, 786 sens ecrits ; les gloses des articles voisins et les references de citations sont filtrees, et un verbe dont l'extraction ne recoupe pas sa definition validee garde son ancien sens. Repare aussi brut.json : les cles RO_TPL_STR / RO_VERBS_STR / RO_VSRC_STR et les verbs / vsrc cs / en / es / pl perdus au lot 41 sont realignees sur la base embarquee. Base embarquee meta version 1.5.62.
- **Lot 41 de presentation, suggestions et typographie ( version 1.5.61 )** : la correspondance exacte passe en tete des suggestions ( Entrer apres avoir tape le mot choisit le mot tape, pas le suivant ) ; Tab remplit le champ avec la premiere suggestion puis les suivantes, Maj+Tab revient en arriere ; les noms des modes et des temps ainsi que les definitions commencent par une majuscule a l affichage ; les prefixes de numero restes de l import Sanders ( ex. « 3) seinen Stamm... » ) sont retires des 55 sens concernes. Base embarquee meta version 1.5.61.
- **Lot 40 de presentation, source la plus ancienne gardee et reglage Wiktionary seul ( version 1.5.60 )** : les doublons de sens entre sources restent dans les donnees et se tranchent a l affichage : quand deux sources donnent la meme definition, la plus ancienne est gardee ( Littré 1872, Sanders 1876, Petrocchi 1887, Słownik warszawski 1900, Webster et Figueiredo 1913, Real Academia 1913, Académie 8e 1932, glossaires du projet, puis Wiktionary ) ; un nouveau reglage « Definitions du Wiktionary uniquement » masque les definitions des dictionnaires et affiche alors celle du Wiktionary en cas de doublon. Base embarquee meta version 1.5.60.
- **Lot 39 de presentation, sources claires et doublons corriges ( version 1.5.59 )** : chaque sens porte desormais son etiquette de source ( fr. Wiktionnaire, Littré, Webster 1913, Petrocchi... ) affichee au-dessus de son groupe dans l encadre des definitions, comme pour le Wiktionary ; la ligne de source statique en dessous est retiree ; les marqueurs de domaine ( Fig., Terme de marine., v. tr. ) entrent dans le texte du sens au lieu de se confondre avec les sources ; les doublons d enregistrement sont fusionnes et les sens identiques dedupliques ( fr 3 267, es 198, pt 303 ) ; nettoyage des scories d import ( 434 sens sans definition, 360 textes avec liens wiki, sans definizione italien ) ; le sens rare de détonner est complete ( Variante de détoner ). Base embarquee meta version 1.5.59.
- **Lot 38 de correction, definition anglaise de rain completee ( version 1.5.58 )** : le verbe anglais rain n affichait que « Obsolete form of reign », le doublon d un enregistrement Wiktionary ecrasant le sens de la pluie ; les definitions sont fusionnees en un seul enregistrement : tomber en pluie ( Wiktionary ), tomber et verser en pluie ( Webster 1913 ), et la forme obsolete de reign en dernier. La base embarquee passe a meta version 1.5.58 ; la copie installee est reprise depuis l asset ( mecanisme du lot 35 ).
- **Lot 37 de presentation, gabarit commun des planches de conjugaison ( version 1.5.57 )** : les temps sont regroupes par mode ( indicatif, conditionnel, subjonctif... ) sous un titre par mode, et plusieurs temps s affichent horizontalement, cartes compactes a largeur naturelle ; les definitions sont regroupees par source : l etiquette ( ex. angl. Wiktionary ) n apparait plus a chaque ligne mais une fois par groupe ; chaque langue de conjugaison a une icone coloree ( drapeau en bandes + deux lettres ), y compris l anglais. Code Dart uniquement, donnees inchangees.
- **Lot 36 de correction, etat des ecrans recree par langue et par carte ( version 1.5.56 )** : Flutter reutilisait l etat d un ecran de conjugaison quand on changeait d onglet, puisque tous partagent le meme type de widget ; l ecran espagnol affichait donc le moteur francais charge au lancement ( verbes et planches en francais ). Chaque onglet porte desormais une cle ( ValueKey ) qui force la recreation de l etat : la bonne langue se charge a chaque changement d onglet, idem pour les cartes france/union/monde. La base embarquee passe a meta version 1.5.56 ( donnees inchangees ).
- **Lot 35 de correction, base installee passee a jour ( version 1.5.55 )** : l application ne recopiait jamais la base embarquee apres le premier lancement ; la copie installee ( dossier de support de l application ) est desormais reprise depuis l asset des que sa version ( table meta ) differe de versionBdd, ce qui repare aussi les installations anciennes. Le nom de la langue conjuguee est desormais affiche en titre dans chaque ecran de conjugaison. La base est reconstruite avec meta version 1.5.55 ( donnees inchangees ).
- **Lot 34 de localisation, noms des modes et des temps de conjugaison ( version 1.5.54 )** : les planches de conjugaison des langues etrangeres affichent desormais leurs propres noms de modes et de temps ( es : Indicativo, presente, preterito imperfecto, futuro simple ; it : Infinito, presente, passato prossimo ; pt : Infinitivo, presente, preterito perfeito composto ; de : Indikativ, Prasens, Prateritum, Perfekt, Futur II ; pl : Tryb oznajmujacy, czas terazniejszy, czas przeszly ; cs : Oznamovaci zpusob, pritomny, minuly, budouci ). Les pronoms etaient deja localises ; le roumain etait deja localise ; le francais reste en francais. La teinte des cartes ( lib/conj/socle.dart ) reconnait les nouveaux noms. Code Dart uniquement ( lib/conj/moteurs.dart, lib/conj/socle.dart, test/conj_test.dart ) ; donnees et base inchangees.
- **Comblement des définitions manquantes ( Wiktionary, CC BY-SA 4.0 )** :
  avec les filtres abandonnés, 439 verbes restaient sans définition
  ( fr 4, en 7, es 19, pl 356, cs 53 ). Ils ont été traités depuis
  les Wiktionary monolingues via l'API MediaWiki ( requêtes par
  lots `action=query` sur fr/en/es/pl/cs.wiktionary.org, extraction
  des sections « verbe » du wikitext ) : **379 comblés** ( fr 4,
  en 2, es 10, pl 318, cs 45 ) avec la définition native de la
  langue, ou à défaut le glossaire anglais de la section
  correspondante du Wiktionary anglophone ; **60 retirés** ( en 5 :
  hygiene, datagram, turbate, twilly, indigest ; es 9 ; pl 38 ;
  cs 8 ), mots qu'aucun Wiktionary ne définit comme verbe -
  artefacts d'extraction, selon la règle « sans définition =>
  retiré ». Scripts : collecte ad hoc ( lots `action=query`,
  nettoyage du wikitext : liens, modèles, références ), puis
  `outils/combler_defs.py` ( remplacement des définitions vides et
  retrait des mots non définis ) ; données :
  `outils/wikt_defs.json` et `outils/retires_wikt.json`. Après
  comblement : 0 verbe sans définition dans les huit langues.
- **Définitions natives pl/cs/ro ( Wiktionary monolingues, CC BY-SA 4.0 )** :
  les verbes polonais, tchèques et roumains reçoivent en priorité la
  définition rédigée dans leur langue par le Wiktionary correspondant,
  extraite des dumps Wikimedia ( `outils/parse_wikt.py` ) vers
  `outils/natifs_{pl,cs,ro}.json` ; les verbes restants gardent le
  glossaire anglais ( étiquette « angl. Wiktionary » ), à remplacer par
  des traductions ( étiquette « angl. Wiktionary, trad. » ) via
  `outils/completer_natifs.py` ( support natifs + traduits ).
  Un dépassement par un dictionnaire du domaine public ( fin 19e,
  début 20e ) a abouti : en it/pt via Petrocchi et Figueiredo ( cf.
  `outils/dictionnaires_pd.py` ), en polonais via le Słownik warszawski
  dont l'OCR archive.org est exploitable après examen ( version 1.5.7,
  `outils/dictionnaires_pd_pl.py` ) ; dexonline ( dump officiel tronqué
  au moment de la collecte, scraping interdit ), Săineanu ( pas d'OCR
  libre ),
  Ottův slovník ( encyclopédie ) ; revu si une numérisation libre
  apparaît.
- **Atelier SQL ( `outils/atelier.py` )** : stockage normalise optionnel
  des donnees de conjugaison dans `outils/atelier.db` : table `sources`
  ( index, nom, caracteristiques ), table `defs` ( langue, verbe, rang
  du sens, etiquette affichee, texte, cle etrangere `id_source`,
  `date_ajout` ), `verbes` ( langue, verbe, segment brut avec les
  formes ), `modeles`, `vsrc`, `verbes_lignes` ; `verbes.groupe`
  ( fr 1er/2e/3e, es/it/pt 1..3, ro I..IV ) et
  `verbes.particularite` ( en regulier/irregulier/double forme
  US/GB, de faible/forte, pl/cs terminaison de l infinitif,
  familles irregulieres et auxiliaires marquees ).
  `atelier.py import` remplissage depuis `brut.json` ; `atelier.py export` regenere
  `brut.json` apres edition ( l'export ne reecrit une definition que
  si son texte a change, et l'aller-retour sans edition est verifie
  octet pour octet ) ; `atelier.py verifier` compare sans ecrire.
  L'app continue de charger `conj_raw` dans la base embarquee :
