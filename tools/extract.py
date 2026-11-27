# Extrait les fichiers de la base depuis le classeur cargo workbook.xlsx
# (compresse dans le classeur gzip + base64, une colonne) et les ecrit
# octet a octet. Usage, depuis la racine du projet, le classeur a cote :
#     python3 outils/extract.py .
# stdlib uniquement. SPDX-License-Identifier : MIT
import base64, gzip, os, re, sys, zipfile


def cellules(z, nom_feuille):
    """Les lignes de la feuille : liste de listes de chaines."""
    with z.open('xl/worksheets/' + nom_feuille) as f:
        xml = f.read().decode('utf-8')
    lignes = []
    for rm in re.finditer(r'<row[^>]*>(.*?)</row>', xml, re.S):
        vals = []
        for tm in re.finditer(r'<t[^>]*>(.*?)</t>', rm.group(1), re.S):
            v = tm.group(1)
            v = v.replace('&lt;', '<').replace('&gt;', '>').replace('&amp;', '&')
            vals.append(v)
        lignes.append(vals)
    return lignes


def extraire(classeur, racine):
    with zipfile.ZipFile(classeur) as z:
        wb = z.read('xl/workbook.xml').decode('utf-8')
        noms = re.findall(r'<sheet name="([^"]+)"', wb)
        feuilleDe = {}
        rels = z.read('xl/_rels/workbook.xml.rels').decode('utf-8')
        cibles = re.findall(r'Target="worksheets/(sheet\d+\.xml)"', rels)
        for n, c in zip(noms, cibles):
            feuilleDe[n] = c
        for nom in ['brut', 'data', 'database']:
            lignes = cellules(z, feuilleDe[nom])
            chemin, taille, morceau = lignes[0][0], int(lignes[0][1]), int(lignes[0][2])
            b64 = ''.join(l[0] for l in lignes[1:] if l)
            brut = gzip.decompress(base64.b64decode(b64))
            assert len(brut) == taille, '%s : taille %d != %d' % (chemin, len(brut), taille)
            p = os.path.join(racine, chemin)
            os.makedirs(os.path.dirname(p), exist_ok=True)
            with open(p, 'wb') as f:
                f.write(brut)
            print('%s : %d octets ecrits' % (chemin, len(brut)))
        infos = cellules(z, feuilleDe.get('infos', cibles[0]))
        for l in infos:
            if l:
                print('  ' + ' | '.join(l))


if __name__ == '__main__':
    racine = sys.argv[1] if len(sys.argv) > 1 else '.'
    classeur = sys.argv[2] if len(sys.argv) > 2 else os.path.join(racine, 'workbook.xlsx')
    extraire(classeur, racine)
    print('extraction terminee')
