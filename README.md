# Lestang Outils

Application multiplateformes (Windows, macOS, Linux, iOS, Android) issue du
projet web Vibetab : conjugaisons (8 langues), cartes géographiques (France,
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
python3 outils/filtre_webster.py webster1913.json  # EN : Webster 1913
# PT : Novo Diccionario da Lingua Portugueza (Figueiredo 1913, OCR
# archive.org/download/DicionrioDeL.P1913, « Dicionário de L.P 1913_djvu.txt »)
python3 outils/parse_figueiredo.py figueiredo.txt figueiredo_verbes.json
python3 outils/filtre_figueiredo.py outils/brut.json figueiredo_verbes.json outils/brut.json
# IT : Petrocchi 1887 + Crusca 1819 (OCR Internet Archive)
#   vol. 1 : https://archive.org/download/nvodizionarioun01petr/nvodizionarioun01petr_djvu.txt
#   vol. 2 : https://archive.org/download/nvodizionarioun02petr/nvodizionarioun02petr_djvu.txt
#   Crusca ed. 1819 : dizionariodellal01cost ... 07cost ..._djvu.txt
python3 outils/parse_petrocchi.py petr1.txt petr2.txt petrocchi_verbes.json
python3 outils/parse_crusca.py crusca1.txt crusca02.txt crusca03.txt crusca04.txt crusca05.txt crusca06.txt crusca07.txt crusca_verbes.json
python3 outils/filtre_italien.py outils/brut.json petrocchi_verbes.json crusca_verbes.json outils/brut.json
python3 outils/construire_bdd.py
```

`extraire.js` charge les scripts de données de `index.html` et vide toutes
les constantes ; `construire_bdd.py` décode chaque format (routes, contours,
points, chaînes de conjugaison) et écrit `assets/lestang_outils.db` (~22 Mo).

Les langues polonaise (pl) et tchèque (cs) n'existent pas dans le moteur
web : leurs chaînes sont construites par `python3 outils/construire_pl_cs.py`
depuis les listes déjà vérifiées `outils/pl_ok.json` / `outils/cs_ok.json`
(extraction kaiki/Wiktionary vérifiée forme par forme).

La source de chaque verbe est stockée dans la base (ligne `vsrc` par langue :
la liste des verbes venus du Wiktionary, les autres venant du générateur
maison) et affichée sur chaque fiche de conjugaison. Pour la reconstruire
après une nouvelle extraction : extraire les données du moteur web **tel
qu'avant enrichissement** dans `outils/brut_orig.json`, puis lancer
`python3 outils/ajouter_vsrc.py` avant `construire_bdd.py`.

## Architecture

- `lib/conj/` : le portage Dart fidèle des moteurs de conjugaison
  (`socle.js`, `conjugaison-{fr,en,es,de,it,pt}.js` du web, plus les moteurs
  polonais `Pl` et tchèques `Cs` écrits pour l'app) ; la base ne stocke que
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

- Conjugaison : en 8 339, it 6 818, pl 9 102, fr 8 535, es 8 966,
  pt 4 792, de 4 220, cs 4 151 ; aucun doublon ; chaque verbe a une
  définition ; définitions 100 % dans la langue de chaque carte
  (glossaires anglais pour pl/cs comme pour de ; anglais :
  Webster 1913, portugais : Figueiredo 1913, italien : Petrocchi 1887
  et Crusca 1819).
- Le lexique anglais est épuré : pas de verbe composé à trait d union
  ( air-condition, birdy-sit ) ni de terme très spécialisé ;
  un verbe n est conservé que si le Webster's Revised Unabridged
  Dictionary ( 1913, texte du domaine public ; numérisation
  lunixbochs/webster, code MIT ) le définit, et sa définition vient
  alors de ce dictionnaire (`outils/filtre_webster.py`). Le lexique
  portugais suit la même règle avec le Figueiredo 1913 ; le lexique
  italien avec le Nòvo dizionàrio universale ( Petrocchi, 1887 ) et,
  à défaut, le Dizionario della Crusca ( éd. Costa-Cardinali, 1819 ).
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
| fr | 8 535 | 1 574 | Moteur maison ; verbes enrichis depuis le Wiktionnaire (kaikki), chaque forme vérifiée, source stockée par verbe | Académie 8e éd. + Littré, domaine public |
| en | 8 339 | 6 696 | Moteur maison ; enrichissement Wiktionary vérifié forme par forme, puis limité aux verbes définis par le Webster 1913 (double formes -ed/-t conservées) | Webster 1913, domaine public (numérisation lunixbochs/webster, MIT) |
| es | 8 966 | 3 755 | Moteur maison ; enrichissement Wiktionary vérifié forme par forme | Real Academia 1913, domaine public |
| de | 4 220 | 3 940 | Moteur maison ; enrichissement Wiktionary vérifié forme par forme | Glossaires anglais du Wiktionary, CC BY-SA 4.0 |
| it | 6 818 | 6 339 | Moteur maison ; enrichissement Wiktionary vérifié forme par forme, puis limité aux verbes définis par Petrocchi 1887 ou la Crusca 1819 | Nòvo dizionàrio universale (Pietro Petrocchi, 1887) + Dizionario degli Accademici della Crusca (éd. Costa-Cardinali, 1819), domaine public (OCR Internet Archive) |
| pt | 4 792 | 4 308 | Moteur maison ; enrichissement Wiktionary vérifié forme par forme, puis limité aux verbes définis par le Figueiredo 1913 | Novo Diccionario da Lingua Portugueza (Cândido de Figueiredo, 1913), domaine public (OCR Internet Archive) |
| pl | 9 102 | 9 102 | Moteur `Pl` ; extraction du Wiktionary polonais via kaikki, verbe accepté seulement si toutes les formes prédites correspondent ; 125 verbes fréquents réintégrés verbatim | Glossaires anglais du Wiktionary, CC BY-SA 4.0 |
| cs | 4 151 | 4 151 | Moteur `Cs` ; même procédé ; 21 verbes fréquents réintégrés verbatim | Glossaires anglais du Wiktionary, CC BY-SA 4.0 |

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
- **Pt, définitions portugaises ( Figueiredo 1913 )** : chaque verbe
  entré du Wiktionary reçoit, en remplacement de son glossaire
  anglais ( CC BY-SA ), les sens du Novo Diccionario da Lingua
  Portugueza de Cândido de Figueiredo ( 1913, domaine public, OCR
  Internet Archive ) via `outils/parse_figueiredo.py` et
  `outils/filtre_figueiredo.py` ( mise en correspondance tolérante à
  l'orthographe de 1913 : accents, consonnes doublées, c épicène ).
  Les 1 292 verbes absents de ce dictionnaire, emprunts ou sens
  postérieurs à 1913 ( controlar, vetar, detectar, dinamitar… ),
  sont retirés. Les verbes du générateur maison et leurs
  définitions sont conservés.
- **It, définitions italiennes ( Petrocchi 1887, Crusca 1819 )** :
  même principe pour l'italien. Le Nòvo dizionàrio universale de
  Pietro Petrocchi ( 1887, domaine public, OCR Internet Archive,
  tomes 1-2 ; tomaseobellini.it et l'édition isolée de 1912 ont été
  écartés, OCR inexploitables ou lemmes manquants ) est dépouillé par
  `outils/parse_petrocchi.py` ; à défaut ( 313 verbes ), le
  Dizionario degli Accademici della Crusca ( édition Costa-Cardinali,
  1819, domaine public, 7 volumes ) l'est par `outils/parse_crusca.py`.
  Les définitions remplacent les glossaires anglais ( CC BY-SA ) ;
  les 5 611 verbes définis par aucun des deux dictionnaires
  ( filmare, idrogenare, cristianizzare… ) sont retirés ; les
  verbes du générateur maison ( ex. cuocere, cullare ) restent avec
  leurs définitions. Résultat : it 12 429 -> 6 818, dont 6 026
  Petrocchi + 313 Crusca ; plus aucun glossaire anglais CC BY-SA
  pour l'italien.
- **Listes de fréquence OpenSubtitles** : utilisées uniquement pour
  sélectionner les verbes rejetés à réintégrer ; aucune donnée de ces
  listes n'est embarquée dans l'app ni dans la base.

Licences des données de conjugaison et définitions :

- Wiktionary/Wiktionnaire (conjugaisons enrichies, glossaires anglais de
  de/it/pt/pl/cs) : CC BY-SA 4.0, attribution « Wiktionary contributors »,
  via l'extraction https://kaikki.org (wiktextract).
- Novo Diccionario da Lingua Portugueza ( Cândido de Figueiredo,
  1913 ) : domaine public ; OCR Internet Archive,
  item DicionrioDeL.P1913.
- Nòvo dizionàrio universale ( Pietro Petrocchi, 1887, tomes 1-2 )
  et Dizionario degli Accademici della Crusca ( édition
  Costa-Cardinali, 1819, 7 volumes ) : domaine public ; OCR
  Internet Archive ( nvodizionarioun01petr / 02petr ;
  dizionariodellal01cost à 07cost ).
- Dictionnaire de l'Académie française 8e éd. (1932-1935), Littré
  (1872-1877), Webster 1913 (texte du domaine public ; numérisation
  lunixbochs/webster, code MIT), Real Academia 1913 : domaine public.


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
