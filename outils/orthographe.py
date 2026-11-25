# Modernise l'orthographe des definitions issues des dictionnaires
# anciens, l app Flutter etant destinee a des utilisateurs jeunes :
#   - allemand : Sanders 1876 ( reforme de 1901 : th, dass, nass... )
#   - italien  : Petrocchi 1887 ( accents de syllabe interne, mejjo... )
#   - portugais: Figueiredo 1913 ( graphies pre-AO90 + accents abolis
#     par les reformes de 1945/1971, norme europeenne )
# Ne touche QUE les sens dont l etiquette est le dictionnaire ancien ;
# les coquilles OCR ( mots mutiles ) restent telles quelles.
# Usage : orthographe.py atelier.db [--ecrire]
# SPDX-License-Identifier : MIT
import re, sqlite3, sys

# ---------------- allemand ( Sanders 1876 ) : liste exhaustive revue ---
DE = {
    'Thieren': 'Tieren', 'Thiers': 'Tiers', 'Thierstimmen': 'Tierstimmen',
    'theils': 'teils', 'Theil': 'Teil', 'Theilen': 'Teilen',
    'Blüthe': 'Blüte', 'Eigenthum': 'Eigentum', 'Nothwendiges': 'Notwendiges',
    'kundthun': 'kundtun', 'muthwillige': 'mutwillige', 'werth': 'wert',
    'gutmüthigerem': 'gutmütigerem', 'athmen': 'atmen',
    'entrathen': 'entraten', 'thun': 'tun', 'thätig': 'tätig',
    'daß': 'dass', 'Daß': 'Dass', 'naß': 'nass',
}

# ---------------- italien ( Petrocchi 1887 ) : regles -------------------
IT_MAP = {'à': 'a', 'è': 'e', 'é': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u'}
IT_REP = {'mèjjo': 'meglio', 'mèjji': 'megli', 'mègjo': 'meglio'}

def it_mod(w):
    low = w.lower()
    if low in IT_REP:
        f = IT_REP[low]
        return f.capitalize() if w[0].isupper() else f
    if len(w) > 1:
        w = ''.join(IT_MAP.get(c.lower(), c) if (c.lower() in IT_MAP and i != len(w) - 1) else c
                    for i, c in enumerate(w))
    w = re.sub('(?<=[a-zà-ù])([A-Z])(?=[a-z])', lambda m: m.group(1).lower(), w)
    return w

# ---------------- portugais ( Figueiredo 1913 ) : liste revue ----------
PT = {
    # consonnes muettes / doubles ( pre-AO90 )
    'carácter': 'caráter', 'objecto': 'objeto', 'objectar': 'objetar',
    'Emittir': 'Emitir', 'Transmittir': 'Transmitir', 'transmittir': 'transmitir',
    'Permittir': 'Permitir', 'victória': 'vitória', 'acceitar': 'aceitar',
    'Acceitar': 'Aceitar', 'ortográphicos': 'ortográficos',
    'Attribuir': 'Atribuir', 'attribuir': 'atribuir', 'Attribuír': 'Atribuir',
    'Conjecturar': 'Conjeturar', 'conjectura': 'conjetura',
    'Occultar': 'Ocultar', 'occultar': 'ocultar', 'occultamente': 'ocultamente',
    'accender': 'acender', 'Accender': 'Acender', 'accentos': 'acentos',
    'accrescentar': 'acrescentar', 'actual': 'atual', 'actualmente': 'atualmente',
    'actos': 'atos', 'activo': 'ativo', 'actividade': 'atividade',
    'ecclesiástico': 'eclesiástico', 'infecto': 'infeto', 'infecta': 'infeta',
    'leccionar': 'lecionar', 'occasião': 'ocasião', 'projectar': 'projetar',
    'projecto': 'projeto', 'projécteis': 'projéteis', 'recta': 'reta',
    'recto': 'reto', 'respectiva': 'respetiva', 'soccorro': 'socorro',
    'soccorrer': 'socorrer', 'systema': 'sistema', 'tacto': 'tato',
    'Tactear': 'Tatear', 'typográphicas': 'tipográficas',
    'Accommodar': 'Acomodar', 'Accusar': 'Acusar', 'accusar': 'acusar',
    'accusação': 'acusação', 'accusações': 'acusações',
    'Asphyxiar': 'Asfixiar', 'Attenuar': 'Atenuar', 'Attrahir': 'Atrair',
    'attrahir': 'atrair', 'Colleccionar': 'Colecionar',
    'coleccionar': 'coletar', 'colectar': 'coletar', 'collectar': 'coletar',
    'Crystallizar': 'Cristalizar', 'crystallino': 'cristalino',
    'Inspeccionar': 'Inspecionar', 'inspeccionar': 'inspecionar',
    'Invectivar': 'invetivar', 'Manufacturar': 'manufaturar',
    'Occupar': 'Ocupar', 'Reflectir': 'refletir', 'accepção': 'aceção',
    'accidentes': 'acidentes', 'adjectivo': 'adjetivo',
    'affectação': 'afetação', 'atmosphera': 'atmosfera',
    'attentamente': 'atentamente', 'attestar': 'atestar',
    'biographia': 'biografia', 'blasphêmia': 'blasfémia',
    'blasphêmias': 'blasfémias', 'catástrophe': 'catástrofe',
    'delicto': 'delito', 'desattender': 'desatender',
    'descripção': 'descrição', 'directamente': 'diretamente',
    'efectivo': 'efetivo', 'effectivo': 'efetivo', 'elephante': 'elefante',
    'estenographicamente': 'estenograficamente',
    'exacta': 'exata', 'exactamente': 'exatamente',
    'extractar': 'extrair', 'extracto': 'extrato', 'factura': 'fatura',
    'fructífero': 'frutífero', 'gráphicos': 'gráficos',
    'hydróphobo': 'hidrófobo', 'indirectamente': 'indiretamente',
    'inscripcão': 'inscrição', 'inscripção': 'inscrição',
    'inscripções': 'inscrições', 'insectos': 'insetos',
    'intellectuaes': 'intelectuais',
    'larynge': 'laringe', 'olfacto': 'olfato', 'photographia': 'fotografia',
    'physica': 'física', 'physicas': 'físicas', 'productos': 'produtos',
    'reproductores': 'reprodutores',
    'successivamente': 'sucessivamente', 'successivas': 'sucessivas',
    'successos': 'sucessos', 'syllabas': 'sílabas',
    'synthetizar': 'sintetizar', 'tachygraphar': 'taquigrafar',
    'triumpho': 'triunfo', 'Adoptar': 'Adotar', 'apromptar': 'aprontar',
    'eléctricas': 'elétricas', 'Electrizar': 'Eletrizar',
    'deminuír': 'deminuir', 'polluír': 'poluir', 'Annuír': 'Anuir',
    'sufíiciente': 'suficiente', 'metállicos': 'metálicos',
    # -cção / doubles divers
    'acção': 'ação', 'acções': 'ações', 'affinação': 'afinação',
    'affeição': 'afeição', 'afflicção': 'aflição', 'aflicção': 'aflição',
    'apparência': 'aparência', 'applicação': 'aplicação',
    'applicações': 'aplicações', 'contracção': 'contração',
    'construcção': 'construção', 'excepção': 'exceção',
    'extineção': 'extinção', 'funcções': 'funções', 'fracções': 'frações',
    'reproducção': 'reprodução', 'transacção': 'transação',
    'transacções': 'transações', 'reacção': 'reação', 'colecção': 'coleção',
    'offício': 'ofício', 'innocência': 'inocência',
    'incommunicável': 'incomunicável', 'illegítimo': 'ilegítimo',
    'intelligência': 'inteligência', 'commerciável': 'comerciável',
    'communhão': 'comunhão', 'communicação': 'comunicação',
    # accents abolis ( reformes 1945 / 1971 / AO90, norme europeenne )
    'moéda': 'moeda', 'almoéda': 'almoeda', 'carrêta': 'carreta',
    'corôa': 'coroa', 'relêvo': 'relevo', 'mêdo': 'medo',
    'bêbedo': 'bêbado', 'mathemática': 'matemática',
    'Mathemática': 'Matemática', 'prêmio': 'prémio', 'prêmios': 'prémios',
    'gênero': 'género', 'gêneros': 'géneros', 'gêlo': 'gelo', 'gêsso': 'gesso',
    'hidrogênio': 'hidrogénio', 'blasfêmia': 'blasfémia',
    'bôa': 'boa', 'bôas': 'boas', 'bôca': 'boca', 'bôto': 'boto',
    'fôlha': 'folha', 'fôrma': 'forma', 'fórma': 'forma', 'Fôrma': 'Forma',
    'fôrmas': 'formas', 'fórmas': 'formas', 'fôrça': 'força',
    'gôsto': 'gosto', 'gôzo': 'gozo', 'môlho': 'molho',
    'sôbre': 'sobre', 'sôpro': 'sopro', 'côr': 'cor', 'côres': 'cores',
    'escôa': 'escoa', 'dôr': 'dor', 'pêlo': 'pelo', 'pêso': 'peso',
    'vêr': 'ver', 'Vêr': 'Ver', 'véla': 'vela', 'vêla': 'vela',
    'vêrga': 'verga', 'vêrgas': 'vergas', 'sêr': 'ser', 'Sêr': 'Ser',
    'têr': 'ter', 'Têr': 'Ter', 'Lêr': 'ler', 'lêr': 'ler',
    'Colhêr': 'Colher', 'colhêr': 'colher', 'Fazêr': 'Fazer',
    'Movêr': 'Mover', 'Govêrno': 'Governo', 'govêrno': 'governo',
    'dêz': 'dez', 'déz': 'dez', 'jôgo': 'jogo', 'joêlho': 'joelho',
    'enjôo': 'enjoo', 'vôo': 'voo', 'cêrca': 'cerca', 'cêrco': 'cerco',
    'sêco': 'seco', 'sêde': 'sede', 'sêllo': 'selo', 'êrro': 'erro',
    'êsse': 'esse', 'êste': 'este', 'prôa': 'proa', 'estôpa': 'estopa',
    'rêde': 'rede', 'rôlas': 'rolas', 'rôlo': 'rolo', 'pôsto': 'posto',
    'pôrto': 'porto', 'Pór': 'pôr', 'volcões': 'vulcões', 'ozônio': 'ozono',
    'pállido': 'pálido', 'mercé': 'mercê', 'àlém': 'além',
}

def de_mod(t):
    return re.sub(r'\w+[-\w]*', lambda m: DE.get(m.group(0), m.group(0)), t)

def it_mod_t(t):
    return re.sub(r"[A-Za-zÀ-ÿ']+", lambda m: it_mod(m.group(0)), t)

def pt_mod(t):
    def f(m):
        w = m.group(0)
        if w in PT: return PT[w]
        lo = w.lower()
        if lo in PT:
            r = PT[lo]
            return r.capitalize() if w[0].isupper() else r
        return w
    return re.sub(r'\w+[-\w]*', f, t)

def main():
    ecrire = '--ecrire' in sys.argv
    db = sqlite3.connect([a for a in sys.argv[1:] if not a.startswith('--')][0])
    modifs = 0
    for source, fn in (('Sanders 1876', de_mod), ('Petrocchi 1887', it_mod_t),
                       ('Figueiredo 1913', pt_mod)):
        n = 0
        lig = db.execute("SELECT rowid, texte FROM defs WHERE etiquette=?",
                         (source,)).fetchall()
        for rid, texte in lig:
            new = fn(texte)
            if new != texte:
                n += 1
                if ecrire:
                    db.execute('UPDATE defs SET texte=? WHERE rowid=?', (new, rid))
        print('%-15s : %d sens modernises sur %d' % (source, n, len(lig)))
        modifs += n
    if ecrire:
        db.commit()
    print('total : %d, mode : %s' % (modifs, 'ECRITURE' if ecrire else 'lecture seule'))
    db.close()

if __name__ == '__main__':
    main()
