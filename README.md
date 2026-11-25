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
  numérisation de dictionnaire du domaine public ( fin 19e, début 20e )
  n'a pu être intégrée à ce jour : l'OCR du Słownik warszawski est
  illisible, le dump officiel de dexonline ( pour le roumain ) était
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
  début 20e ) n'a pas abouti à ce jour : Słownik warszawski ( OCR
  gothique illisible ), dexonline ( dump officiel tronqué au moment
  de la collecte, scraping interdit ), Săineanu ( pas d'OCR libre ),
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
  apres une edition dans l'atelier, relancer export puis
  `construire_bdd.py`. Les etiquettes de pl/cs/ro et des glossaires
  anglais servent a la fois d'etiquette affichee et de nom de source ;
  pour fr/en/es les etiquettes sont des marques de registre ou de
  domaine : `sources_defs.py` rattache tous les sens ( 118 270 ) a une
  source : fr par comparaison du texte avec le Littré ( 14 700, XML
  oeuvres/littre ) puis par elimination Académie 8e ( 6 691 ) ;
  en Webster 1913 ( 5 778, lunixbochs/webster ) uniquement si le texte
  du sens apparait mot a mot dans l article verbal du mot, sinon
  glossaire du Wiktionary anglais ; renvois fr. Wiktionary ;
  es verbatim du Diccionario de la RAE 1913-1914 ( 7 038 ), les
  glosses anglais « to ... » de ce lot herite ( 3 660 ) sont etiquetes
  angl. Wiktionary ; les redactions condensees de de/it/pt issues du
  generateur du projet sont etiquetees « Glossaire du générateur du
  projet » ( MIT ). Depuis la version 1.3 de l atelier,
  `outils/dictionnaires_pd.py` remplace en it/pt les sens des verbes
  couverts par Petrocchi 1887 ( 2 397 verbes, 3 300 sens ) et Figueiredo
  1913 ( 3 423 verbes, 3 427 sens ), etiquette et source = nom du
  dictionnaire, date 2026-11-25, OCR archive.org conserve tel quel ;
  l allemand attend un vrai OCR du Sanders 1876 ( Fraktur illisible ) ;
  NB :
  brut.json ne transporte ni `id_source` ni les colonnes
  `groupe`/`particularite` : apres un import, relancer
  `sources_defs.py` puis `classes.py`. Les dates d'ajout marquent les
  lots d'origine ( 2026-11-24 lot initial, 2026-11-25 roumain et
  definitions natives pl/cs/ro ).
- **Listes de fréquence OpenSubtitles** : utilisées uniquement pour
  sélectionner les verbes rejetés à réintégrer ; aucune donnée de ces
  listes n'est embarquée dans l'app ni dans la base.

Licences des données de conjugaison et définitions :

- Wiktionary/Wiktionnaire (conjugaisons enrichies, glossaires anglais de
  de/it/pt, définitions natives de pl/cs/ro) : CC BY-SA 4.0, attribution
  « Wiktionary contributors », via l'extraction https://kaikki.org
  (wiktextract) pour les glossaires anglais et les dumps Wikimedia
  (dumps.wikimedia.org, backup.wikimedia.org) pour les définitions
  natives du Wiktionary polonais, tchèque et roumain.
- Dictionnaire de l'Académie française 8e éd. (1932-1935) et Littré
  (1872-1877), définitions françaises : domaine public.
- Webster's Revised Unabridged Dictionary ( 1913, texte du domaine
  public ) : numérisation https://github.com/lunixbochs/webster
  ( code MIT, les définitions restent domaine public ).
- Real Academia Española, diccionario 1913-1914 : domaine public.
- Dictionnaires du domaine public intégrés depuis la version 1.3.0
  ( définitions it/pt, `outils/dictionnaires_pd.py` ) ; la Crusca reste
  essayée puis abandonnée. URLs des OCR ( Petrocchi et Figueiredo sont
  ceux utilisés ) :
  - Novo Diccionario da Lingua Portugueza ( Cândido de Figueiredo,
    1913 ) : https://archive.org/details/DicionrioDeL.P1913
    ( texte : https://archive.org/download/DicionrioDeL.P1913/DicionrioDeL.P1913_djvu.txt ).
  - Nòvo dizionàrio universale della lingua italiana ( Pietro
    Petrocchi, 1887, tomes 1-2 ) :
    https://archive.org/details/novodizionarioun01petruoft et
    https://archive.org/details/novodizionarioun02petruoft
    ( textes : ..._djvu.txt ).
  - Dizionario degli Accademici della Crusca ( édition
    Costa-Cardinali, 1819, 7 volumes ) :
    https://archive.org/details/dizionariodellal01cost ,
    https://archive.org/details/dizionariodellal02cost ,
    https://archive.org/details/dizionariodellal03cost ,
    https://archive.org/details/dizionariodellal04cost ,
    https://archive.org/details/dizionariodellal05cost ,
    https://archive.org/details/dizionariodellal06cost ,
    https://archive.org/details/dizionariodellal07cost .
  Tous : domaine public, OCR Internet Archive.


### Écrans et fonctions : sources et licences

- **Météo** : interrogée directement depuis l app, sans clé, aucune
  donnée redistribuée. Open-Meteo (agrégateur incluant les modèles
  Météo-France, données et API sous CC BY 4.0, attribution
  Open-Meteo.com) ; MET Norway (api.met.no, données NLOD/CC BY 4.0) ;
  wttr.in ; IPMA Portugal (données ouvertes, attribution IPMA) ; JMA
  Japon (attribution JMA) ; NWS/NOAA États-Unis (domaine public,
  gouvernement américain) ; BOM Australie (CC BY 4.0) ; HKO Hong Kong
  (attribution Observatoire de Hong Kong). Codes GDPS et géocodage :
  Open-Meteo.
- **Compresseur de PDF** : rastérise chaque page via pdfium
  ( package `printing`, Apache-2.0 ), encode en JPEG ( package `image`,
  MIT ), reconstruit le PDF ( package `pdf`, Apache-2.0 ). Traitement
  100 % local, aucun fichier n est envoyé sur le réseau.
- **Générateur de mot de passe** : tirage cryptographique uniforme
  (`Random.secure` de Dart, CSPRNG du système), quatre jeux de
  caractères au choix, 4 à 64 caractères, exclusion des ambigus au
  choix, 100 % local, aucun historique conservé.
- **Cartes** : contours et données géographiques (départements, routes
  européennes, frontières, villes, transports en commun) embarqués
  depuis les fichiers de données du projet web Vibetab, rendu local
  `CustomPaint` sans fond de carte ni service tiers.
- **Recherche web** : 47 moteurs paramétrables (DuckDuckGo, Google,
  Bing, Wikipédia, OpenStreetMap, cartes.gouv.fr…), la requête part
  directement vers le moteur choisi.

### Bibliothèques

- `sqlite3`, `sqlite3_flutter_libs`, `image` : MIT ; SQLite lui-même :
  domaine public.
- `pdf`, `printing` : Apache-2.0.
- `file_selector`, `path_provider`, `shared_preferences`, `url_launcher`,
  `share_plus`, `http`, `path` : BSD-3-Clause (projet Flutter/Dart).
- Météo : Open-Meteo, Météo-France, MET Norway, wttr.in, IPMA, JMA, NWS,
  BOM, HKO (APIs publiques, aucune donnée redistribuée).

## Note sur l'archive

Ce dossier est le source complet de l'application, base SQLite comprise.
Le SDK Flutter n'est pas requis pour lire le code, seulement pour la
compiler.
