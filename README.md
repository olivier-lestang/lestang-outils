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

## Regénérer la base

La base est reconstruite à partir des fichiers de données du projet web :

```bash
node outils/extraire.js <chemin-du-projet-web>/web/ outils/brut.json
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
  polonais `Pl` et tchèque `Cs` écrits pour l'app) ; la base ne stocke que
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

- Conjugaison : en 40 327, it 12 429, pl 9 102, fr 8 539, es 8 981,
  pt 6 085, de 4 220, cs 4 151 ; définitions 100 % dans la langue de
  chaque carte (glossaires anglais pour pl/cs comme pour it/pt/de).
- France : 160 départements, 2 461 autoroutes, 2 884 nationales,
  50 984 départementales, 54 fleuves, LGV, 178 villes des transports,
  103 tronçons parisiens.
- Union : 322 contours membres, ZEE, 17 routes européennes, LGV,
  capitales et villes.
- Monde : 285 frontières, grandes villes.

## Licences

Code sous licence MIT (`LICENSE`). Conjugaisons produites par le générateur
maison du projet (SPDX-License-Identifier: MIT), enrichies et vérifiées
forme par forme depuis le Wiktionary via l'extraction kaikki.org/wiktextract
(licence CC BY-SA 4.0 ; attribution : Wiktionnaire/Wiktionary contributors).
Les conjugaisons polonaise et tchèque (moteurs Pl/Cs, MIT) sont extraites et
vérifiées par le même procédé : chaque forme affichée correspond au Wiktionary
ou est dérivée par des règles elles-mêmes contrôlées forme par forme ; les
verbes non conformes sont rejetés plutôt que risqués. Environ 150 verbes
très courants rejetés par ces règles (croisés avec les listes de fréquence
OpenSubtitles : zobaczyć, wziąć, pójść, muset...) sont réintégrés avec
toutes leurs formes copiées verbatim du Wiktionary.
Définitions : Dictionnaire de l'Académie française 8e éd. et Littré
(domaine public), Webster 1913 (GCIDE), Real Academia 1913 (domaine public),
et glossaires anglais abrégés du Wiktionary (CC BY-SA 4.0) pour
l'allemand, l'italien et le portugais. Météo : Open-Meteo, Météo-France,
MET Norway, wttr.in, IPMA, JMA, NWS, BOM, HKO (APIs publiques).

## Note sur l'archive

Ce dossier est le source complet de l'application, base SQLite comprise.
Le SDK Flutter n'est pas requis pour lire le code, seulement pour la
compiler.
