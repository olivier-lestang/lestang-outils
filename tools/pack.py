# Emballe les fichiers de la base (outils/raw.json, test/data.json,
# assets/lestang_outils.db) dans un classeur workbook.xlsx : chaque fichier
# y est stocke gzipe puis base64, decoupe en morceaux d une seule colonne
# (base64 : aucun caractere a echapper en XML). L extraction se fait par
# python3 outils/extract.py <dossier-cible> (stdlib uniquement).
# SPDX-License-Identifier : MIT
import base64, gzip, os, sys, zipfile

FICHIERS = [
    ('brut', 'outils/raw.json'),
    ('data', 'test/data.json'),
    ('database', 'assets/lestang_outils.db'),
]
MORCEAU = 30000  # caracteres base64 par cellule

CT = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'''
for i in range(1, 5):
    CT += '<Override PartName="/xl/worksheets/sheet%d.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' % i
CT += '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/></Types>'

RELS = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>'''

STYLES = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts><fills count="1"><fill><patternFill patternType="none"/></fill></fills><borders count="1"><border/></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/></cellXfs></styleSheet>'''


def classeur(racine, sortie):
    feuilles = []  # (nom, lignes: list[list[str]])
    infos = [
        ['Classeur cargo Lestang Outils - base 9 langues (roumain inclus)'],
        ['Extraction, depuis le dossier racine du projet ou se trouve ce classeur :'],
        ['    python3 outils/extract.py .'],
        ['Fichiers restitues, octets exacts :'],
        ['chemin', 'taille', 'morceau'],
    ]
    for nom, rel in FICHIERS:
        p = os.path.join(racine, rel)
        brut = open(p, 'rb').read()
        b64 = base64.b64encode(gzip.compress(brut, 6)).decode()
        infos.append([rel, str(len(brut)), str(MORCEAU)])
        lignes = [[rel, str(len(brut)), str(MORCEAU)]]
        # ligne 1 : en-tete chemin|taille|morceau ; ensuite chaque ligne UNE cellule
        cellules = [[rel, str(len(brut)), str(MORCEAU)]]
        for i in range(0, len(b64), MORCEAU):
            cellules.append([b64[i:i + MORCEAU]])
        feuilles.append((nom, cellules))
        print('%s : %d octets (base64 %d)' % (nom, len(brut), len(b64)))
    feuilles.insert(0, ('infos', infos))

    noms = [n for n, _ in feuilles]
    wb = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'''
    for i, n in enumerate(noms, 1):
        wb += '<sheet name="%s" sheetId="%d" r:id="rId%d"/>' % (n, i, i)
    wb += '</sheets></workbook>'
    wrels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'''
    for i in range(1, len(noms) + 1):
        wrels += ('<Relationship Id="rId%d" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet%d.xml"/>' % (i, i))
    wrels += ('<Relationship Id="rId%d" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>' % (len(noms) + 1))

    def xml_vers(cellules):
        s = ['<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>']
        for r, ligne in enumerate(cellules, 1):
            s.append('<row r="%d">' % r)
            for c, v in enumerate(ligne, 1):
                col = chr(64 + c)
                esc = (v.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;'))
                s.append('<c r="%s%d" t="inlineStr"><is><t xml:space="preserve">%s</t></is></c>' % (col, r, esc))
            s.append('</row>')
        s.append('</sheetData></worksheet>')
        return ''.join(s)

    with zipfile.ZipFile(sortie, 'w', zipfile.ZIP_DEFLATED) as z:
        z.writestr('[Content_Types].xml', CT)
        z.writestr('_rels/.rels', RELS)
        z.writestr('xl/workbook.xml', wb)
        z.writestr('xl/_rels/workbook.xml.rels', wrels)
        z.writestr('xl/styles.xml', STYLES)
        for i, (n, cellules) in enumerate(feuilles, 1):
            z.writestr('xl/worksheets/sheet%d.xml' % i, xml_vers(cellules))
    print('classeur ecrit : %s (%d octets)' % (sortie, os.path.getsize(sortie)))


if __name__ == '__main__':
    racine = sys.argv[1] if len(sys.argv) > 1 else '.'
    sortie = sys.argv[2] if len(sys.argv) > 2 else 'workbook.xlsx'
    classeur(racine, sortie)
