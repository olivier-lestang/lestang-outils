#!/usr/bin/env python3
"""Rebuilds the world border layer of the embedded base at the 1:10M
   precision: Natural Earth 1:10M country rings simplified with a
   0.008 degree Douglas-Peucker tolerance, about 218 000 vertices,
   twenty times the 110M layer it replaces; the holes keep their
   orientation so the filled land still shows them.
   Usage: python3 outils/frontieres_10m.py [path of the base]
   SPDX-License-Identifier: MIT."""
import base64
import gzip
import os
import sqlite3
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_DB = os.path.join(HERE, '..', 'assets', 'lestang_outils.db')
B64 = os.path.join(HERE, 'monde-frontieres-10m.b64')
VERSION = '1.5.65'


def main():
    db = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_DB
    payload = gzip.decompress(base64.b64decode(open(B64).read()))
    rings = []
    i = 0
    while i < len(payload):
        n = struct.unpack_from('<i', payload, i)[0]
        rings.append(payload[i:i + 4 + 8 * n])
        i += 4 + 8 * n
    c = sqlite3.connect(db)
    c.execute("delete from geo where carte='monde' and couche='frontieres'")
    c.executemany(
        "insert into geo(carte, couche, etiquette, n, geom)"
        " values('monde','frontieres','',?,?)",
        [(struct.unpack_from('<i', r, 0)[0], r) for r in rings])
    c.execute("update meta set valeur=? where cle='version'", (VERSION,))
    c.commit()
    c.close()
    c = sqlite3.connect(db)
    c.execute('vacuum')
    c.close()
    print('world borders rebuilt: %d rings, %d vertices, base %s' % (
        len(rings),
        sum(struct.unpack_from('<i', r, 0)[0] for r in rings),
        VERSION))


if __name__ == '__main__':
    main()
