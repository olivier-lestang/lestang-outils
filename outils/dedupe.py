# Dedommage les listes de verbes de toutes les langues dans brut.json :
# premiere occurrence conservee, structure tpl/groupe preservee ( une ligne
# par template, meme devenue vide, pour garder l alignement des indices ).
# SPDX-License-Identifier: MIT
import json
import os

ICI = os.path.dirname(os.path.abspath(__file__))
LANGUES = ['fr', 'en', 'es', 'de', 'it', 'pt']


def main():
    with open(os.path.join(ICI, 'brut.json'), encoding='utf-8') as f:
        b = json.load(f)
    for cle in ['CONJ_VERBS_STR', 'EN_VERBS_STR', 'ES_VERBS_STR', 'DE_VERBS_STR',
                'IT_VERBS_STR', 'PT_VERBS_STR']:
        vus = set()  # doublons a l interieur d une meme langue seulement
        lignes = b[cle].split('\n')
        avant = sum(len([x for x in g.split(',') if x]) for g in lignes)
        nouvelles = []
        for grp in lignes:
            gardes = []
            for w in grp.split(','):
                nom = w.split(':')[0] if w else ''
                if w and nom not in vus:
                    vus.add(nom)
                    gardes.append(w)
            nouvelles.append(','.join(gardes))
        apres = sum(len([x for x in g.split(',') if x]) for g in nouvelles)
        b[cle] = '\n'.join(nouvelles)
        if avant != apres:
            print('%s : %d → %d ( -%d doublons )'
                  % (cle, avant, apres, avant - apres))
    with open(os.path.join(ICI, 'brut.json'), 'w', encoding='utf-8') as f:
        json.dump(b, f, ensure_ascii=False, separators=(',', ':'))


if __name__ == '__main__':
    main()
