# Corrige les coquilles OCR certaines dans les definitions des
# dictionnaires du domaine public ( remplacement mot a mot revu en
# contexte ; les scans LaTeX/refs de citations restent tels quels ).
# Concerne surtout le Sanders 1876 ( OCR maison Tesseract frk :
# fich=sich, dur<=durch... ) plus deux reparations it/pt (
# superfice=superficie, ob jeto=objeto, prospecto reverti ).
# Usage : coquilles_ocr.py atelier.db [--ecrire]
# SPDX-License-Identifier : MIT
import sqlite3, sys

# remplacements TEXTE, appliques tels quels ( plus surs que mot a mot )
FIX = [
    # --- allemand : OCR maison ( Sanders 1876 ) ---
    ('fich', 'sich'),
    ('dur<', 'durch'),
    ('Hindurc<', 'Hindurch'),
    ('sc<hwellend', 'schwellend'),
    ('na< Etwas', 'nam. Etwas'),
    ('flint ihm', 'flirrt ihm'),
    ('Berballhornung', 'Verballhornung'),
    ('Ausgangspunft', 'Ausgangspunkt'),
    ('schweilen machen', 'schwellen machen'),
    # --- allemand : formes decontractees pour un jeune public ---
    ('versehn', 'versehen'),
    ('gehn ', 'gehen '),
    # --- allemand : pre-1901 oublie en 1.4.1 ---
    ('Waaren', 'Waren'),
    # --- italien ( Petrocchi 1887, OCR archive.org ) ---
    ('superflce', 'superficie'),
    ('superfice', 'superficie'),
    # --- portugais ( Figueiredo 1913, OCR archive.org ) ---
    ('ob jeto', 'objeto'),
    ('de prospecto.', 'de prospector.'),
]

def corrige(t):
    for a, b in FIX:
        t = t.replace(a, b)
    return t

def main():
    ecrire = '--ecrire' in sys.argv
    db = sqlite3.connect([a for a in sys.argv[1:] if not a.startswith('--')][0])
    total = 0
    for source in ('Sanders 1876', 'Petrocchi 1887', 'Figueiredo 1913'):
        n = 0
        for rid, texte in db.execute(
                "SELECT rowid, texte FROM defs WHERE etiquette=?", (source,)):
            new = corrige(texte)
            if new != texte:
                n += 1
                if ecrire:
                    db.execute('UPDATE defs SET texte=? WHERE rowid=?', (new, rid))
        print('%-15s : %d sens corriges' % (source, n))
        total += n
    if ecrire:
        db.commit()
    print('total : %d, mode : %s' % (total, 'ECRITURE' if ecrire else 'lecture seule'))
    db.close()

if __name__ == '__main__':
    main()
