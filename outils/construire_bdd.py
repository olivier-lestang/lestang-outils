# -*- coding: utf-8 -*-
"""
Construit vibetab.db (SQLite) depuis brut.json, l'extraction des constantes
de donnees du projet vibetab. SPDX-License-Identifier: MIT.

Les geometries vivent dans le plan propre de chaque carte, comme dans le
fichier HTML d origine :
  - carte « france » : x = lon * cos(46.245 degres), y = lat ; les donnees
    sources sont en milliemes ( routes, contours ) ou dix-milliemes
    ( LGV, transports ) de degre ;
  - carte « union » : x = lon * cos(46.245 degres), y = lat ;
  - carte « monde » : lon, lat bruts.
BLOB geometry : u32 LE (nombre de points) puis paires float32 LE.
"""
import base64
import gzip
import json
import math
import os
import sqlite3
import struct
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
COS = math.cos(46.245 * math.pi / 180.0)


def blob(pts):
    b = [struct.pack('<I', len(pts))]
    for x, y in pts:
        # Float32 : precision native de l ecran, la donnee source est deja
        # en milliemes de degre, aucune perte visible a l affichage.
        b.append(struct.pack('<f', x))
        b.append(struct.pack('<f', y))
    return b''.join(b)


def deltas_seg(seg, unite, cosmo):
    """Un segment : premier point absolu, suivants en deltas."""
    pts, px, py = [], 0.0, 0.0
    for k, p in enumerate(seg.split(',')):
        c = p.split(' ')
        if len(c) < 2:
            continue
        try:
            dx, dy = int(c[0]), int(c[1])
        except ValueError:
            continue
        if k == 0:
            px, py = dx / unite, dy / unite
        else:
            px += dx / unite
            py += dy / unite
        pts.append((px * cosmo, py))
    return pts


def cordes(brut):
    """FR_JOINTS_STR : id -> points absolus en milliemes de degre."""
    cache = {}
    for e in brut['FR_JOINTS_STR'].split(';'):
        i = e.find('=')
        if i < 1:
            continue
        pts, x, y = [], 0, 0
        for k, p in enumerate(e[i + 1:].split(',')):
            s = p.split(' ')
            if len(s) < 2:
                continue
            try:
                dx, dy = int(s[0]), int(s[1])
            except ValueError:
                continue
            if k:
                x += dx
                y += dy
            else:
                x, y = dx, dy
            pts.append((x, y))
        if len(pts) > 1:
            cache[e[:i]] = pts
    return cache


def points_corde(joint, tok):
    """Points absolus d'une corde citee; tiret final = ordre inverse."""
    if tok.endswith('-'):
        base = joint.get(tok[:-1])
        return list(reversed(base)) if base else []
    return joint.get(tok) or []


def seg_avec_cordes(seg, joint, unite, cosmo):
    """Un segment pouvant citer des cordes @xxx (points absolus herites)."""
    pts, px, py = [], 0.0, 0.0
    init = False
    for p in seg.split(','):
        if p.startswith('@'):
            ch = points_corde(joint, p[1:])
            for a in ch:
                px, py = a[0] / unite, a[1] / unite
                pts.append((px * cosmo, py))
            init = True
            continue
        c = p.split(' ')
        if len(c) < 2:
            continue
        try:
            dx, dy = int(c[0]), int(c[1])
        except ValueError:
            continue
        if init or pts:
            px += dx / unite
            py += dy / unite
        else:
            px, py = dx / unite, dy / unite
        pts.append((px * cosmo, py))
    return pts


def traces(chaine, joint, unite, cosmo):
    """';' segments, chacun pouvant citer des cordes."""
    out = []
    for seg in chaine.split(';'):
        if not seg.strip():
            continue
        pts = seg_avec_cordes(seg, joint, unite, cosmo)
        if len(pts) > 1:
            out.append(pts)
    return out


def contour_pays(e, joint, cosmo):
    """Entree « CLE=points,points,... » avec cordes citees, unite 1000."""
    i = e.find('=')
    if i < 1:
        return None, None
    cle = e[:i]
    return cle, seg_avec_cordes(e[i + 1:], joint, 1000.0, cosmo)


def principal(brut, sortie):
    db = sqlite3.connect(sortie)
    db.executescript("""
PRAGMA journal_mode=OFF;
CREATE TABLE meta(cle TEXT PRIMARY KEY, valeur TEXT);
CREATE TABLE conj_raw(langue TEXT, quoi TEXT, valeur TEXT, PRIMARY KEY(langue, quoi));
CREATE TABLE geo(carte TEXT, couche TEXT, etiquette TEXT, n INTEGER, geom BLOB);
CREATE INDEX geo_cch ON geo(carte, couche);
CREATE TABLE points(carte TEXT, couche TEXT, nom TEXT, x REAL, y REAL, info TEXT);
CREATE INDEX points_cch ON points(carte, couche);
""")

    def geom(carte, couche, pts, etiquette=''):
        if len(pts) > 1:
            db.execute('INSERT INTO geo VALUES(?,?,?,?,?)',
                       (carte, couche, etiquette, len(pts), blob(pts)))

    def pt(carte, couche, nom, x, y, info=''):
        db.execute('INSERT INTO points VALUES(?,?,?,?,?,?)',
                   (carte, couche, nom, x, y, info))

    joint = cordes(brut)

    # ----------------------------------------------- conjugaison, neuf langues
    def dezippe(cle):
        return gzip.decompress(base64.b64decode(brut[cle])).decode('utf-8')

    langues = [
        ('fr', 'CONJ_TPL_STR', 'CONJ_VERBS_STR', 'CONJ_DEFS_B64'),
        ('en', 'EN_TPL_STR', 'EN_VERBS_STR', 'EN_DEFS_B64'),
        ('es', 'ES_TPL_STR', 'ES_VERBS_STR', 'ES_DEFS_B64'),
        ('de', 'DE_TPL_STR', 'DE_VERBS_STR', None),
        ('it', 'IT_TPL_STR', 'IT_VERBS_STR', None),
        ('pt', 'PT_TPL_STR', 'PT_VERBS_STR', None),
        ('pl', 'PL_TPL_STR', 'PL_VERBS_STR', None),
        ('cs', 'CS_TPL_STR', 'CS_VERBS_STR', None),
        ('ro', 'RO_TPL_STR', 'RO_VERBS_STR', None),
    ]
    for lg, tpl, verbs, defs_b64 in langues:
        db.execute('INSERT INTO conj_raw VALUES(?,?,?)', (lg, 'tpl', brut[tpl]))
        db.execute('INSERT INTO conj_raw VALUES(?,?,?)', (lg, 'verbs', brut[verbs]))
        txt = brut['%s_DEFS_STR' % lg.upper()] if defs_b64 is None else dezippe(defs_b64)
        db.execute('INSERT INTO conj_raw VALUES(?,?,?)', (lg, 'defs', txt))
        nb = len([e for e in txt.split('\u0002') if e])
        print('  conj %s : %d definitions' % (lg, nb))
        # source de chaque verbe : liste de ceux venus du Wiktionary
        cle_src = '%s_VSRC_STR' % lg.upper()
        if cle_src in brut:
            vsrc = brut[cle_src]
            db.execute('INSERT INTO conj_raw VALUES(?,?,?)', (lg, 'vsrc', vsrc))
            print('  conj %s : %d verbes du Wiktionary' %
                  (lg, len([e for e in vsrc.split('\n') if e])))

    # ---------------------------------------------- carte de France
    # contours administratifs reels (milliemes, premier absolu puis deltas)
    for e in brut['FR_DEPTS_GEOM_STR'].split(';'):
        eq = e.find('=')
        if eq < 1:
            continue
        code = e[:eq]
        pts, x, y = [], 0, 0
        for k, p in enumerate(e[eq + 1:].split(',')):
            s = p.split(' ')
            if len(s) < 2:
                continue
            try:
                dx, dy = int(s[0]), int(s[1])
            except ValueError:
                continue
            if k:
                x += dx
                y += dy
            else:
                x, y = dx, dy
            pts.append((x / 1000.0 * COS, y / 1000.0))
        if len(pts) > 3:
            geom('france', 'departements', pts, code)
    for e in brut['FR_DEPTS_STR'].split(';'):
        f = e.split('|')
        if len(f) >= 3:
            pt('france', 'chefs-lieux', f[1], float(f[2]) * COS, float(f[3]),
               'code=%s;region=%s' % (f[0], f[4] if len(f) > 4 else ''))
    for p in traces(brut['FR_REGION_BORDERS_STR'], joint, 1000.0, COS):
        geom('france', 'regions', p)
    for p in traces(brut['FR_OUTER_STR'], joint, 1000.0, COS):
        geom('france', 'contour', p)
    for couche, cle in [('autoroutes', 'FR_AUT_STR'), ('nationales', 'FR_RN_STR')]:
        n = 0
        for seg in brut[cle].split(';'):
            p = deltas_seg(seg, 10000.0, COS)
            if len(p) > 1:
                geom('france', couche, p)
                n += 1
        print('  FR %s : %d chaines' % (couche, n))
    n = 0
    for seg in brut['FR_RD_STR'].split(';'):
        p = deltas_seg(seg, 10000.0, COS)
        if len(p) > 1:
            geom('france', 'departementales', p)
            n += 1
    print('  FR departementales : %d chaines' % n)
    for couche, cle, unite in [('fleuves', 'FR_FLV_STR', 1000.0),
                               ('zee', 'FR_ZEE_STR', 1000.0),
                               ('lgv', 'FR_LGV_STR', 1000.0)]:
        for seg in brut[cle].split(';'):
            geom('france', couche, deltas_seg(seg, unite, COS))
    for e in brut['FR_LGV_STATIONS_STR'].split(';'):
        f = e.split('|')
        if len(f) >= 3:
            pt('france', 'lgv-stations', f[0], float(f[1]) * COS, float(f[2]))
    for couche, cle in [('villes', 'FR_TOWNS_STR'), ('grandes-villes', 'FR_CITIES_STR')]:
        for e in brut[cle].split(';'):
            f = e.split('|')
            if len(f) >= 4:
                pt('france', couche, f[0], float(f[1]) * COS, float(f[2]), 'pop=' + f[3])

    def reseaux(chaine, couche, avec_badge):
        n = 0
        for e in chaine.split(';'):
            f = e.split('|')
            besoin = 4 if avec_badge else 3
            if len(f) < besoin:
                continue
            etiquette = f[0] + '|' + f[1] + ('|' + f[2] if avec_badge else '')
            for seg in f[besoin - 1].split('&'):
                p = deltas_seg(seg, 10000.0, COS)
                if len(p) > 1:
                    geom('france', couche, p, etiquette)
                    n += 1
        print('  FR %s : %d tracons' % (couche, n))

    reseaux(brut['FR_TransportsParis_Str'], 'paris', False)
    reseaux(brut['FR_TransportsVilles_Str'], 'villes-transports', True)
    for couche, cle in [('stations', 'FR_TransportsVilles_Stations_Str'),
                        ('paris-stations', 'FR_TransportsParis_Stations_Str')]:
        for e in brut[cle].split(';'):
            f = e.split('|')
            if len(f) >= 3:
                pt('france', couche, f[0], float(f[1]) * COS, float(f[2]),
                   '|'.join(f[3:]))

    # ---------------------------------------------- carte de l Union
    for couche, cle in [('membres', 'UE_MEMBERS_STR'), ('autres', 'UE_OTHERS_STR'),
                        ('hors-ue', 'UE_HORSNE_STR'), ('hors-ue-2', 'UE_HORS2_STR'),
                        ('hors-ue-3', 'UE_HORS3_STR')]:
        if cle not in brut:
            continue
        n = 0
        for e in brut[cle].split(';'):
            iso, p = contour_pays(e, joint, COS)
            if iso and len(p) > 2:
                geom('union', couche, p, iso)
                n += 1
        print('  UE %s : %d contours' % (couche, n))
    for e in brut['UE_ZEE_STR'].split(';'):
        iso, p = contour_pays(e, joint, COS)
        if iso and len(p) > 2:
            geom('union', 'zee', p, iso)
    for couche, cle, unite in [
            ('fleuves', 'UE_RIVERS_STR', 1000.0),
            ('grands-fleuves', 'UE_MAJ_STR', 1000.0),
            ('eroutes', 'UE_EROADS_STR', 1000.0),
            ('routes-voisins-brutes', 'FR_NAT_ROADS_STR', 1000.0),
            ('lgv', 'UE_LGV_STR', 10000.0)]:
        for seg in brut[cle].split(';'):
            if '=' in seg.split(',')[0] and couche == 'routes-voisins-brutes':
                i = seg.find('=')
                j = seg.find('=', i + 1)
                corps = seg[j + 1:] if j > i else seg[i + 1:]
                for morceau in corps.split(';'):
                    geom('union', couche, deltas_seg(morceau, unite, COS))
            else:
                geom('union', couche, deltas_seg(seg, unite, COS))
    for e in brut['UE_LGV_STATIONS_STR'].split(';'):
        f = e.split('|')
        if len(f) >= 3:
            pt('union', 'lgv-stations', f[0], float(f[1]) * COS, float(f[2]))
    for couche, cle, mini in [('villes', 'UE_CITIES_STR', 0),
                              ('capitales', 'UE_CAPS_STR', 0)]:
        for e in brut[cle].split(';'):
            f = e.split('|')
            if couche == 'villes' and len(f) >= 4:
                pt('union', 'villes', f[0], float(f[1]) * COS, float(f[2]), 'pop=' + f[3])
            elif couche == 'capitales' and len(f) >= 3:
                pt('union', 'capitales', f[2], float(f[0]) * COS, float(f[1]),
                   'pop=' + (f[5] if len(f) > 5 else ''))
    for cle, couche in [('FR_AUT_REF_STR', 'refs-aut'), ('FR_RN_REF_STR', 'refs-rn'),
                        ('FR_RD_REF_STR', 'refs-rd'), ('UE_ER_REF_STR', 'refs-er')]:
        if cle not in brut:
            continue
        for e in brut[cle].split(';'):
            f = e.split('|')
            if f[0].strip().isdigit():
                pt('union', couche, 'index:' + f[0], 0.0, 0.0, f[1])
    noms_er = [n for n in brut['UE_ER_NAMES_STR'].split(',') if n]
    for i, n in enumerate(noms_er):
        db.execute('INSERT INTO points VALUES(?,?,?,?,?,?)',
                   ('union', 'noms-eroutes', n, 0.0, 0.0, str(i)))

    # ---------------------------------------------- carte du monde
    n = 0
    for e in brut['WM_BORDERS_STR'].split('|'):
        pts = []
        for p in e.split(' '):
            c = p.split(',')
            if len(c) < 2:
                continue
            try:
                lon, lat = float(c[0]), float(c[1])
            except ValueError:
                continue
            pts.append((lon, lat))
        if len(pts) > 1:
            geom('monde', 'frontieres', pts)
            n += 1
    print('  Monde : %d contours' % n)
    for e in brut['UE_CITIES_STR'].split(';'):
        f = e.split('|')
        if len(f) >= 4 and float(f[3]) > 900000:
            pt('monde', 'villes', f[0], float(f[1]), float(f[2]), 'pop=' + f[3])
    for e in brut['FR_CITIES_STR'].split(';'):
        f = e.split('|')
        if len(f) >= 4:
            pt('monde', 'villes', f[0], float(f[1]) / COS, float(f[2]), 'pop=' + f[3])

    # meme valeur que versionBdd dans lib/bdd.dart : la copie installee
    # par l application est reprise depuis l asset si elle differe.
    db.execute('INSERT INTO meta VALUES(?,?)', ('version', '1.5.64'))
    db.commit()
    db.close()


if __name__ == '__main__':
    entree = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ICI, 'brut.json')
    sortie = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ICI, '..', 'assets', 'lestang_outils.db')
    os.makedirs(os.path.dirname(sortie), exist_ok=True)
    with open(entree, encoding='utf-8') as f:
        brut = json.load(f)
    principal(brut, sortie)
    print('base ecrite :', sortie, os.path.getsize(sortie), 'octets')
