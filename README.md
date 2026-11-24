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

- Conjugaison : en 19 075, it 12 429, pl 9 102, fr 8 535, es 8 966,
  pt 6 085, de 4 220, cs 4 151 ; aucun doublon ; définitions 100 % dans
  la langue de chaque carte (glossaires anglais pour pl/cs comme pour
  it/pt/de).
- Le lexique anglais est épuré : pas de verbe composé à trait d union
  ( air-condition, birdy-sit ) ni de terme très spécialisé ;
  un verbe Wiktionary n est conservé que si lui-même ou l une de ses
  formes fléchies usuelles figure dans la liste de frequence
  OpenSubtitles complète ( hermitdave/FrequencyWords en_full.txt,
  utilisée uniquement pour ce tri, aucune donnée embarquée ).
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
| en | 19 075 | 17 432 | Moteur maison ; enrichissement Wiktionary vérifié forme par forme, puis épuré (composés à trait d union et termes très spécialisés retirés) et complété des doubles formes -ed/-t | Webster 1913 (GCIDE), domaine public |
| es | 8 966 | 3 755 | Moteur maison ; enrichissement Wiktionary vérifié forme par forme | Real Academia 1913, domaine public |
| de | 4 220 | 3 940 | Moteur maison ; enrichissement Wiktionary vérifié forme par forme | Glossaires anglais du Wiktionary, CC BY-SA 4.0 |
| it | 12 429 | 11 950 | Moteur maison ; enrichissement Wiktionary vérifié forme par forme | Glossaires anglais du Wiktionary, CC BY-SA 4.0 |
| pt | 6 085 | 5 601 | Moteur maison ; enrichissement Wiktionary vérifié forme par forme | Glossaires anglais du Wiktionary, CC BY-SA 4.0 |
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
- **Listes de fréquence OpenSubtitles** : utilisées uniquement pour
  sélectionner les verbes rejetés à réintégrer ; aucune donnée de ces
  listes n'est embarquée dans l'app ni dans la base.

Licences des données de conjugaison et définitions :

- Wiktionary/Wiktionnaire (conjugaisons enrichies, glossaires anglais de
  de/it/pt/pl/cs) : CC BY-SA 4.0, attribution « Wiktionary contributors »,
  via l'extraction https://kaikki.org (wiktextract).
- Dictionnaire de l'Académie française 8e éd. (1932-1935), Littré
  (1872-1877), Webster 1913 (GCIDE), Real Academia 1913 : domaine public.


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
