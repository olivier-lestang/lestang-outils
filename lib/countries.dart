/* The names of the countries of the marked cities of the world map,
   by ISO code and by language: the cities dialog groups them and
   sorts them by their translated name, the code of the city picks the
   row, a code without a translation falls back to the English name
   the city list carries.
   SPDX-License-Identifier: MIT. */
import 'l10n.dart' show appLanguage;

const Map<String, Map<String, String>> _names = {
  'AD': {
    'fr': 'Andorre', 'en': 'Andorra', 'es': 'Andorra', 'pt': 'Andorra',
    'it': 'Andorra', 'de': 'Andorra', 'zh-Hans': '安道尔', 'zh-Hant': '安道爾',
  },
  'AE': {
    'fr': 'Émirats arabes unis', 'en': 'United Arab Emirates',
    'es': 'Emiratos Árabes Unidos', 'pt': 'Emirados Árabes Unidos',
    'it': 'Emirati Arabi Uniti', 'de': 'Vereinigte Arabische Emirate',
    'zh-Hans': '阿拉伯联合酋长国', 'zh-Hant': '阿拉伯聯合大公國',
  },
  'AF': {
    'fr': 'Afghanistan', 'en': 'Afghanistan', 'es': 'Afganistán',
    'pt': 'Afeganistão', 'it': 'Afghanistan', 'de': 'Afghanistan',
    'zh-Hans': '阿富汗', 'zh-Hant': '阿富汗',
  },
  'AG': {
    'fr': 'Antigua-et-Barbuda', 'en': 'Antigua and Barbuda',
    'es': 'Antigua y Barbuda', 'pt': 'Antígua e Barbuda',
    'it': 'Antigua e Barbuda', 'de': 'Antigua und Barbuda',
    'zh-Hans': '安提瓜和巴布达', 'zh-Hant': '安地卡及巴布達',
  },
  'AL': {
    'fr': 'Albanie', 'en': 'Albania', 'es': 'Albania', 'pt': 'Albânia',
    'it': 'Albania', 'de': 'Albanien', 'zh-Hans': '阿尔巴尼亚', 'zh-Hant': '阿爾巴尼亞',
  },
  'AM': {
    'fr': 'Arménie', 'en': 'Armenia', 'es': 'Armenia', 'pt': 'Armênia',
    'it': 'Armenia', 'de': 'Armenien', 'zh-Hans': '亚美尼亚', 'zh-Hant': '亞美尼亞',
  },
  'AO': {
    'fr': 'Angola', 'en': 'Angola', 'es': 'Angola', 'pt': 'Angola',
    'it': 'Angola', 'de': 'Angola', 'zh-Hans': '安哥拉', 'zh-Hant': '安哥拉',
  },
  'AR': {
    'fr': 'Argentine', 'en': 'Argentina', 'es': 'Argentina',
    'pt': 'Argentina', 'it': 'Argentina', 'de': 'Argentinien',
    'zh-Hans': '阿根廷', 'zh-Hant': '阿根廷',
  },
  'AT': {
    'fr': 'Autriche', 'en': 'Austria', 'es': 'Austria', 'pt': 'Áustria',
    'it': 'Austria', 'de': 'Österreich', 'zh-Hans': '奥地利', 'zh-Hant': '奧地利',
  },
  'AU': {
    'fr': 'Australie', 'en': 'Australia', 'es': 'Australia',
    'pt': 'Austrália', 'it': 'Australia', 'de': 'Australien',
    'zh-Hans': '澳大利亚', 'zh-Hant': '澳洲',
  },
  'AZ': {
    'fr': 'Azerbaïdjan', 'en': 'Azerbaijan', 'es': 'Azerbaiyán',
    'pt': 'Azerbaijão', 'it': 'Azerbaijan', 'de': 'Aserbaidschan',
    'zh-Hans': '阿塞拜疆', 'zh-Hant': '亞塞拜然',
  },
  'BA': {
    'fr': 'Bosnie-Herzégovine', 'en': 'Bosnia and Herzegovina',
    'es': 'Bosnia y Herzegovina', 'pt': 'Bósnia e Herzegovina',
    'it': 'Bosnia ed Erzegovina', 'de': 'Bosnien und Herzegowina',
    'zh-Hans': '波斯尼亚和黑塞哥维那', 'zh-Hant': '波士尼亞與赫塞哥維納',
  },
  'BB': {
    'fr': 'Barbade', 'en': 'Barbados', 'es': 'Barbados', 'pt': 'Barbados',
    'it': 'Barbados', 'de': 'Barbados', 'zh-Hans': '巴巴多斯', 'zh-Hant': '巴貝多',
  },
  'BD': {
    'fr': 'Bangladesh', 'en': 'Bangladesh', 'es': 'Bangladesh',
    'pt': 'Bangladesh', 'it': 'Bangladesh', 'de': 'Bangladesch',
    'zh-Hans': '孟加拉国', 'zh-Hant': '孟加拉',
  },
  'BE': {
    'fr': 'Belgique', 'en': 'Belgium', 'es': 'Bélgica', 'pt': 'Bélgica',
    'it': 'Belgio', 'de': 'Belgien', 'zh-Hans': '比利时', 'zh-Hant': '比利時',
  },
  'BF': {
    'fr': 'Burkina Faso', 'en': 'Burkina Faso', 'es': 'Burkina Faso',
    'pt': 'Burkina Faso', 'it': 'Burkina Faso', 'de': 'Burkina Faso',
    'zh-Hans': '布基纳法索', 'zh-Hant': '布吉納法索',
  },
  'BG': {
    'fr': 'Bulgarie', 'en': 'Bulgaria', 'es': 'Bulgaria',
    'pt': 'Bulgária', 'it': 'Bulgaria', 'de': 'Bulgarien',
    'zh-Hans': '保加利亚', 'zh-Hant': '保加利亞',
  },
  'BH': {
    'fr': 'Bahreïn', 'en': 'Bahrain', 'es': 'Baréin', 'pt': 'Barém',
    'it': 'Bahrein', 'de': 'Bahrain', 'zh-Hans': '巴林', 'zh-Hant': '巴林',
  },
  'BI': {
    'fr': 'Burundi', 'en': 'Burundi', 'es': 'Burundi', 'pt': 'Burundi',
    'it': 'Burundi', 'de': 'Burundi', 'zh-Hans': '布隆迪', 'zh-Hant': '蒲隆地',
  },
  'BJ': {
    'fr': 'Bénin', 'en': 'Benin', 'es': 'Benín', 'pt': 'Benin',
    'it': 'Benin', 'de': 'Benin', 'zh-Hans': '贝宁', 'zh-Hant': '貝南',
  },
  'BM': {
    'fr': 'Bermudes', 'en': 'Bermuda', 'es': 'Bermudas', 'pt': 'Bermudas',
    'it': 'Bermuda', 'de': 'Bermuda', 'zh-Hans': '百慕大', 'zh-Hant': '百慕達',
  },
  'BN': {
    'fr': 'Brunei', 'en': 'Brunei', 'es': 'Brunéi', 'pt': 'Brunei',
    'it': 'Brunei', 'de': 'Brunei', 'zh-Hans': '文莱', 'zh-Hant': '汶萊',
  },
  'BO': {
    'fr': 'Bolivie', 'en': 'Bolivia', 'es': 'Bolivia', 'pt': 'Bolívia',
    'it': 'Bolivia', 'de': 'Bolivien', 'zh-Hans': '玻利维亚', 'zh-Hant': '玻利維亞',
  },
  'BR': {
    'fr': 'Brésil', 'en': 'Brazil', 'es': 'Brasil', 'pt': 'Brasil',
    'it': 'Brasile', 'de': 'Brasilien', 'zh-Hans': '巴西', 'zh-Hant': '巴西',
  },
  'BS': {
    'fr': 'Bahamas', 'en': 'The Bahamas', 'es': 'Bahamas', 'pt': 'Bahamas',
    'it': 'Bahamas', 'de': 'Bahamas', 'zh-Hans': '巴哈马', 'zh-Hant': '巴哈馬',
  },
  'BT': {
    'fr': 'Bhoutan', 'en': 'Bhutan', 'es': 'Bután', 'pt': 'Butão',
    'it': 'Bhutan', 'de': 'Bhutan', 'zh-Hans': '不丹', 'zh-Hant': '不丹',
  },
  'BW': {
    'fr': 'Botswana', 'en': 'Botswana', 'es': 'Botsuana', 'pt': 'Botsuana',
    'it': 'Botswana', 'de': 'Botswana', 'zh-Hans': '博茨瓦纳', 'zh-Hant': '波札那',
  },
  'BY': {
    'fr': 'Biélorussie', 'en': 'Belarus', 'es': 'Bielorrusia',
    'pt': 'Bielorrússia', 'it': 'Bielorussia', 'de': 'Belarus',
    'zh-Hans': '白俄罗斯', 'zh-Hant': '白俄羅斯',
  },
  'BZ': {
    'fr': 'Belize', 'en': 'Belize', 'es': 'Belice', 'pt': 'Belize',
    'it': 'Belize', 'de': 'Belize', 'zh-Hans': '伯利兹', 'zh-Hant': '貝里斯',
  },
  'CA': {
    'fr': 'Canada', 'en': 'Canada', 'es': 'Canadá', 'pt': 'Canadá',
    'it': 'Canada', 'de': 'Kanada', 'zh-Hans': '加拿大', 'zh-Hant': '加拿大',
  },
  'CD': {
    'fr': 'Congo (Kinshasa)', 'en': 'Congo (Kinshasa)',
    'es': 'Congo (Kinshasa)', 'pt': 'Congo (Kinshasa)',
    'it': 'Congo (Kinshasa)', 'de': 'Kongo (Kinshasa)',
    'zh-Hans': '刚果（金）', 'zh-Hant': '剛果（金）',
  },
  'CF': {
    'fr': 'République centrafricaine', 'en': 'Central African Republic',
    'es': 'República Centroafricana', 'pt': 'República Centro-Africana',
    'it': 'Repubblica Centrafricana', 'de': 'Zentralafrikanische Republik',
    'zh-Hans': '中非共和国', 'zh-Hant': '中非共和國',
  },
  'CG': {
    'fr': 'Congo (Brazzaville)', 'en': 'Congo (Brazzaville)',
    'es': 'Congo (Brazzaville)', 'pt': 'Congo (Brazzaville)',
    'it': 'Congo (Brazzaville)', 'de': 'Kongo (Brazzaville)',
    'zh-Hans': '刚果（布）', 'zh-Hant': '剛果（布）',
  },
  'CH': {
    'fr': 'Suisse', 'en': 'Switzerland', 'es': 'Suiza', 'pt': 'Suíça',
    'it': 'Svizzera', 'de': 'Schweiz', 'zh-Hans': '瑞士', 'zh-Hant': '瑞士',
  },
  'CI': {
    'fr': 'Côte d’Ivoire', 'en': 'Ivory Coast', 'es': 'Costa de Marfil',
    'pt': 'Costa do Marfim', 'it': 'Costa d’Avorio', 'de': 'Elfenbeinküste',
    'zh-Hans': '科特迪瓦', 'zh-Hant': '象牙海岸',
  },
  'CL': {
    'fr': 'Chili', 'en': 'Chile', 'es': 'Chile', 'pt': 'Chile',
    'it': 'Cile', 'de': 'Chile', 'zh-Hans': '智利', 'zh-Hant': '智利',
  },
  'CM': {
    'fr': 'Cameroun', 'en': 'Cameroon', 'es': 'Camerún', 'pt': 'Camarões',
    'it': 'Camerun', 'de': 'Kamerun', 'zh-Hans': '喀麦隆', 'zh-Hant': '喀麥隆',
  },
  'CN': {
    'fr': 'Chine', 'en': 'China', 'es': 'China', 'pt': 'China',
    'it': 'Cina', 'de': 'China', 'zh-Hans': '中国', 'zh-Hant': '中國',
  },
  'CO': {
    'fr': 'Colombie', 'en': 'Colombia', 'es': 'Colombia', 'pt': 'Colômbia',
    'it': 'Colombia', 'de': 'Kolumbien', 'zh-Hans': '哥伦比亚', 'zh-Hant': '哥倫比亞',
  },
  'CR': {
    'fr': 'Costa Rica', 'en': 'Costa Rica', 'es': 'Costa Rica',
    'pt': 'Costa Rica', 'it': 'Costa Rica', 'de': 'Costa Rica',
    'zh-Hans': '哥斯达黎加', 'zh-Hant': '哥斯大黎加',
  },
  'CU': {
    'fr': 'Cuba', 'en': 'Cuba', 'es': 'Cuba', 'pt': 'Cuba',
    'it': 'Cuba', 'de': 'Kuba', 'zh-Hans': '古巴', 'zh-Hant': '古巴',
  },
  'CV': {
    'fr': 'Cap-Vert', 'en': 'Cape Verde', 'es': 'Cabo Verde',
    'pt': 'Cabo Verde', 'it': 'Capo Verde', 'de': 'Kap Verde',
    'zh-Hans': '佛得角', 'zh-Hant': '維德角',
  },
  'CY': {
    'fr': 'Chypre', 'en': 'Cyprus', 'es': 'Chipre', 'pt': 'Chipre',
    'it': 'Cipro', 'de': 'Zypern', 'zh-Hans': '塞浦路斯', 'zh-Hant': '賽普勒斯',
  },
  'CZ': {
    'fr': 'Tchéquie', 'en': 'Czech Republic', 'es': 'Chequia',
    'pt': 'Chéquia', 'it': 'Cechia', 'de': 'Tschechien',
    'zh-Hans': '捷克', 'zh-Hant': '捷克',
  },
  'DE': {
    'fr': 'Allemagne', 'en': 'Germany', 'es': 'Alemania', 'pt': 'Alemanha',
    'it': 'Germania', 'de': 'Deutschland', 'zh-Hans': '德国', 'zh-Hant': '德國',
  },
  'DJ': {
    'fr': 'Djibouti', 'en': 'Djibouti', 'es': 'Yibuti', 'pt': 'Djibuti',
    'it': 'Gibuti', 'de': 'Dschibuti', 'zh-Hans': '吉布提', 'zh-Hant': '吉布地',
  },
  'DK': {
    'fr': 'Danemark', 'en': 'Denmark', 'es': 'Dinamarca', 'pt': 'Dinamarca',
    'it': 'Danimarca', 'de': 'Dänemark', 'zh-Hans': '丹麦', 'zh-Hant': '丹麥',
  },
  'DM': {
    'fr': 'Dominique', 'en': 'Dominica', 'es': 'Dominica', 'pt': 'Dominica',
    'it': 'Dominica', 'de': 'Dominica', 'zh-Hans': '多米尼克', 'zh-Hant': '多米尼克',
  },
  'DO': {
    'fr': 'République dominicaine', 'en': 'Dominican Republic',
    'es': 'República Dominicana', 'pt': 'República Dominicana',
    'it': 'Repubblica Dominicana', 'de': 'Dominikanische Republik',
    'zh-Hans': '多米尼加共和国', 'zh-Hant': '多明尼加共和國',
  },
  'DZ': {
    'fr': 'Algérie', 'en': 'Algeria', 'es': 'Argelia', 'pt': 'Argélia',
    'it': 'Algeria', 'de': 'Algerien', 'zh-Hans': '阿尔及利亚', 'zh-Hant': '阿爾及利亞',
  },
  'EC': {
    'fr': 'Équateur', 'en': 'Ecuador', 'es': 'Ecuador', 'pt': 'Equador',
    'it': 'Ecuador', 'de': 'Ecuador', 'zh-Hans': '厄瓜多尔', 'zh-Hant': '厄瓜多',
  },
  'EE': {
    'fr': 'Estonie', 'en': 'Estonia', 'es': 'Estonia', 'pt': 'Estónia',
    'it': 'Estonia', 'de': 'Estland', 'zh-Hans': '爱沙尼亚', 'zh-Hant': '愛沙尼亞',
  },
  'EG': {
    'fr': 'Égypte', 'en': 'Egypt', 'es': 'Egipto', 'pt': 'Egito',
    'it': 'Egitto', 'de': 'Ägypten', 'zh-Hans': '埃及', 'zh-Hant': '埃及',
  },
  'EH': {
    'fr': 'Sahara occidental', 'en': 'Western Sahara',
    'es': 'Sahara Occidental', 'pt': 'Saara Ocidental',
    'it': 'Sahara Occidentale', 'de': 'Westsahara',
    'zh-Hans': '西撒哈拉', 'zh-Hant': '西撒哈拉',
  },
  'ER': {
    'fr': 'Érythrée', 'en': 'Eritrea', 'es': 'Eritrea', 'pt': 'Eritreia',
    'it': 'Eritrea', 'de': 'Eritrea', 'zh-Hans': '厄立特里亚', 'zh-Hant': '厄利垂亞',
  },
  'ES': {
    'fr': 'Espagne', 'en': 'Spain', 'es': 'España', 'pt': 'Espanha',
    'it': 'Spagna', 'de': 'Spanien', 'zh-Hans': '西班牙', 'zh-Hant': '西班牙',
  },
  'ET': {
    'fr': 'Éthiopie', 'en': 'Ethiopia', 'es': 'Etiopía', 'pt': 'Etiópia',
    'it': 'Etiopia', 'de': 'Äthiopien', 'zh-Hans': '埃塞俄比亚', 'zh-Hant': '衣索比亞',
  },
  'FI': {
    'fr': 'Finlande', 'en': 'Finland', 'es': 'Finlandia', 'pt': 'Finlândia',
    'it': 'Finlandia', 'de': 'Finnland', 'zh-Hans': '芬兰', 'zh-Hant': '芬蘭',
  },
  'FJ': {
    'fr': 'Fidji', 'en': 'Fiji', 'es': 'Fiyi', 'pt': 'Fiji',
    'it': 'Figi', 'de': 'Fidschi', 'zh-Hans': '斐济', 'zh-Hant': '斐濟',
  },
  'FM': {
    'fr': 'États fédérés de Micronésie', 'en': 'Federated States of Micronesia',
    'es': 'Estados Federados de Micronesia', 'pt': 'Estados Federados da Micronésia',
    'it': 'Stati Federati di Micronesia', 'de': 'Föderierte Staaten von Mikronesien',
    'zh-Hans': '密克罗尼西亚联邦', 'zh-Hant': '密克羅尼西亞聯邦',
  },
  'FR': {
    'fr': 'France', 'en': 'France', 'es': 'Francia', 'pt': 'França',
    'it': 'Francia', 'de': 'Frankreich', 'zh-Hans': '法国', 'zh-Hant': '法國',
  },
  'GA': {
    'fr': 'Gabon', 'en': 'Gabon', 'es': 'Gabón', 'pt': 'Gabão',
    'it': 'Gabon', 'de': 'Gabun', 'zh-Hans': '加蓬', 'zh-Hant': '加彭',
  },
  'GB': {
    'fr': 'Royaume-Uni', 'en': 'United Kingdom', 'es': 'Reino Unido',
    'pt': 'Reino Unido', 'it': 'Regno Unito', 'de': 'Vereinigtes Königreich',
    'zh-Hans': '英国', 'zh-Hant': '英國',
  },
  'GD': {
    'fr': 'Grenade', 'en': 'Grenada', 'es': 'Granada', 'pt': 'Granada',
    'it': 'Grenada', 'de': 'Grenada', 'zh-Hans': '格林纳达', 'zh-Hant': '格瑞那達',
  },
  'GE': {
    'fr': 'Géorgie', 'en': 'Georgia', 'es': 'Georgia', 'pt': 'Geórgia',
    'it': 'Georgia', 'de': 'Georgien', 'zh-Hans': '格鲁吉亚', 'zh-Hant': '喬治亞',
  },
  'GH': {
    'fr': 'Ghana', 'en': 'Ghana', 'es': 'Ghana', 'pt': 'Gana',
    'it': 'Ghana', 'de': 'Ghana', 'zh-Hans': '加纳', 'zh-Hant': '迦納',
  },
  'GM': {
    'fr': 'Gambie', 'en': 'The Gambia', 'es': 'Gambia', 'pt': 'Gâmbia',
    'it': 'Gambia', 'de': 'Gambia', 'zh-Hans': '冈比亚', 'zh-Hant': '甘比亞',
  },
  'GN': {
    'fr': 'Guinée', 'en': 'Guinea', 'es': 'Guinea', 'pt': 'Guiné',
    'it': 'Guinea', 'de': 'Guinea', 'zh-Hans': '几内亚', 'zh-Hant': '幾內亞',
  },
  'GQ': {
    'fr': 'Guinée équatoriale', 'en': 'Equatorial Guinea',
    'es': 'Guinea Ecuatorial', 'pt': 'Guiné Equatorial',
    'it': 'Guinea Equatoriale', 'de': 'Äquatorialguinea',
    'zh-Hans': '赤道几内亚', 'zh-Hant': '赤道幾內亞',
  },
  'GR': {
    'fr': 'Grèce', 'en': 'Greece', 'es': 'Grecia', 'pt': 'Grécia',
    'it': 'Grecia', 'de': 'Griechenland', 'zh-Hans': '希腊', 'zh-Hant': '希臘',
  },
  'GT': {
    'fr': 'Guatemala', 'en': 'Guatemala', 'es': 'Guatemala', 'pt': 'Guatemala',
    'it': 'Guatemala', 'de': 'Guatemala', 'zh-Hans': '危地马拉', 'zh-Hant': '瓜地馬拉',
  },
  'GW': {
    'fr': 'Guinée-Bissau', 'en': 'Guinea Bissau', 'es': 'Guinea-Bisáu',
    'pt': 'Guiné-Bissau', 'it': 'Guinea-Bissau', 'de': 'Guinea-Bissau',
    'zh-Hans': '几内亚比绍', 'zh-Hant': '幾內亞比索',
  },
  'GY': {
    'fr': 'Guyana', 'en': 'Guyana', 'es': 'Guyana', 'pt': 'Guiana',
    'it': 'Guyana', 'de': 'Guyana', 'zh-Hans': '圭亚那', 'zh-Hant': '蓋亞那',
  },
  'HK': {
    'fr': 'Hong Kong', 'en': 'Hong Kong S.A.R.', 'es': 'Hong Kong',
    'pt': 'Hong Kong', 'it': 'Hong Kong', 'de': 'Hongkong',
    'zh-Hans': '香港', 'zh-Hant': '香港',
  },
  'HN': {
    'fr': 'Honduras', 'en': 'Honduras', 'es': 'Honduras', 'pt': 'Honduras',
    'it': 'Honduras', 'de': 'Honduras', 'zh-Hans': '洪都拉斯', 'zh-Hant': '宏都拉斯',
  },
  'HR': {
    'fr': 'Croatie', 'en': 'Croatia', 'es': 'Croacia', 'pt': 'Croácia',
    'it': 'Croazia', 'de': 'Kroatien', 'zh-Hans': '克罗地亚', 'zh-Hant': '克羅埃西亞',
  },
  'HT': {
    'fr': 'Haïti', 'en': 'Haiti', 'es': 'Haití', 'pt': 'Haiti',
    'it': 'Haiti', 'de': 'Haiti', 'zh-Hans': '海地', 'zh-Hant': '海地',
  },
  'HU': {
    'fr': 'Hongrie', 'en': 'Hungary', 'es': 'Hungría', 'pt': 'Hungria',
    'it': 'Ungheria', 'de': 'Ungarn', 'zh-Hans': '匈牙利', 'zh-Hant': '匈牙利',
  },
  'ID': {
    'fr': 'Indonésie', 'en': 'Indonesia', 'es': 'Indonesia',
    'pt': 'Indonésia', 'it': 'Indonesia', 'de': 'Indonesien',
    'zh-Hans': '印度尼西亚', 'zh-Hant': '印尼',
  },
  'IE': {
    'fr': 'Irlande', 'en': 'Ireland', 'es': 'Irlanda', 'pt': 'Irlanda',
    'it': 'Irlanda', 'de': 'Irland', 'zh-Hans': '爱尔兰', 'zh-Hant': '愛爾蘭',
  },
  'IL': {
    'fr': 'Israël', 'en': 'Israel', 'es': 'Israel', 'pt': 'Israel',
    'it': 'Israele', 'de': 'Israel', 'zh-Hans': '以色列', 'zh-Hant': '以色列',
  },
  'IN': {
    'fr': 'Inde', 'en': 'India', 'es': 'India', 'pt': 'Índia',
    'it': 'India', 'de': 'Indien', 'zh-Hans': '印度', 'zh-Hant': '印度',
  },
  'IQ': {
    'fr': 'Irak', 'en': 'Iraq', 'es': 'Irak', 'pt': 'Iraque',
    'it': 'Iraq', 'de': 'Irak', 'zh-Hans': '伊拉克', 'zh-Hant': '伊拉克',
  },
  'IR': {
    'fr': 'Iran', 'en': 'Iran', 'es': 'Irán', 'pt': 'Irão',
    'it': 'Iran', 'de': 'Iran', 'zh-Hans': '伊朗', 'zh-Hant': '伊朗',
  },
  'IS': {
    'fr': 'Islande', 'en': 'Iceland', 'es': 'Islandia', 'pt': 'Islândia',
    'it': 'Islanda', 'de': 'Island', 'zh-Hans': '冰岛', 'zh-Hant': '冰島',
  },
  'IT': {
    'fr': 'Italie', 'en': 'Italy', 'es': 'Italia', 'pt': 'Itália',
    'it': 'Italia', 'de': 'Italien', 'zh-Hans': '意大利', 'zh-Hant': '義大利',
  },
  'JM': {
    'fr': 'Jamaïque', 'en': 'Jamaica', 'es': 'Jamaica', 'pt': 'Jamaica',
    'it': 'Giamaica', 'de': 'Jamaika', 'zh-Hans': '牙买加', 'zh-Hant': '牙買加',
  },
  'JO': {
    'fr': 'Jordanie', 'en': 'Jordan', 'es': 'Jordania', 'pt': 'Jordânia',
    'it': 'Giordania', 'de': 'Jordanien', 'zh-Hans': '约旦', 'zh-Hant': '約旦',
  },
  'JP': {
    'fr': 'Japon', 'en': 'Japan', 'es': 'Japón', 'pt': 'Japão',
    'it': 'Giappone', 'de': 'Japan', 'zh-Hans': '日本', 'zh-Hant': '日本',
  },
  'KE': {
    'fr': 'Kenya', 'en': 'Kenya', 'es': 'Kenia', 'pt': 'Quénia',
    'it': 'Kenya', 'de': 'Kenia', 'zh-Hans': '肯尼亚', 'zh-Hant': '肯亞',
  },
  'KG': {
    'fr': 'Kirghizistan', 'en': 'Kyrgyzstan', 'es': 'Kirguistán',
    'pt': 'Quirguistão', 'it': 'Kirghizistan', 'de': 'Kirgisistan',
    'zh-Hans': '吉尔吉斯斯坦', 'zh-Hant': '吉爾吉斯',
  },
  'KH': {
    'fr': 'Cambodge', 'en': 'Cambodia', 'es': 'Camboya', 'pt': 'Camboja',
    'it': 'Cambogia', 'de': 'Kambodscha', 'zh-Hans': '柬埔寨', 'zh-Hant': '柬埔寨',
  },
  'KI': {
    'fr': 'Kiribati', 'en': 'Kiribati', 'es': 'Kiribati', 'pt': 'Kiribati',
    'it': 'Kiribati', 'de': 'Kiribati', 'zh-Hans': '基里巴斯', 'zh-Hant': '吉里巴斯',
  },
  'KM': {
    'fr': 'Comores', 'en': 'Comoros', 'es': 'Comoras', 'pt': 'Comores',
    'it': 'Comore', 'de': 'Komoren', 'zh-Hans': '科摩罗', 'zh-Hant': '葛摩',
  },
  'KN': {
    'fr': 'Saint-Kitts-et-Nevis', 'en': 'Saint Kitts and Nevis',
    'es': 'San Cristóbal y Nieves', 'pt': 'São Cristóvão e Neves',
    'it': 'Saint Kitts e Nevis', 'de': 'St. Kitts und Nevis',
    'zh-Hans': '圣基茨和尼维斯', 'zh-Hant': '聖克里斯多福及尼維斯',
  },
  'KP': {
    'fr': 'Corée du Nord', 'en': 'North Korea', 'es': 'Corea del Norte',
    'pt': 'Coreia do Norte', 'it': 'Corea del Nord', 'de': 'Nordkorea',
    'zh-Hans': '朝鲜', 'zh-Hant': '北韓',
  },
  'KR': {
    'fr': 'Corée du Sud', 'en': 'South Korea', 'es': 'Corea del Sur',
    'pt': 'Coreia do Sul', 'it': 'Corea del Sud', 'de': 'Südkorea',
    'zh-Hans': '韩国', 'zh-Hant': '南韓',
  },
  'KW': {
    'fr': 'Koweït', 'en': 'Kuwait', 'es': 'Kuwait', 'pt': 'Kuwait',
    'it': 'Kuwait', 'de': 'Kuwait', 'zh-Hans': '科威特', 'zh-Hant': '科威特',
  },
  'KZ': {
    'fr': 'Kazakhstan', 'en': 'Kazakhstan', 'es': 'Kazajistán',
    'pt': 'Cazaquistão', 'it': 'Kazakistan', 'de': 'Kasachstan',
    'zh-Hans': '哈萨克斯坦', 'zh-Hant': '哈薩克',
  },
  'LA': {
    'fr': 'Laos', 'en': 'Laos', 'es': 'Laos', 'pt': 'Laos',
    'it': 'Laos', 'de': 'Laos', 'zh-Hans': '老挝', 'zh-Hant': '寮國',
  },
  'LB': {
    'fr': 'Liban', 'en': 'Lebanon', 'es': 'Líbano', 'pt': 'Líbano',
    'it': 'Libano', 'de': 'Libanon', 'zh-Hans': '黎巴嫩', 'zh-Hant': '黎巴嫩',
  },
  'LC': {
    'fr': 'Sainte-Lucie', 'en': 'Saint Lucia', 'es': 'Santa Lucía',
    'pt': 'Santa Lúcia', 'it': 'Santa Lucia', 'de': 'St. Lucia',
    'zh-Hans': '圣卢西亚', 'zh-Hant': '聖露西亞',
  },
  'LI': {
    'fr': 'Liechtenstein', 'en': 'Liechtenstein', 'es': 'Liechtenstein',
    'pt': 'Liechtenstein', 'it': 'Liechtenstein', 'de': 'Liechtenstein',
    'zh-Hans': '列支敦士登', 'zh-Hant': '列支敦斯登',
  },
  'LK': {
    'fr': 'Sri Lanka', 'en': 'Sri Lanka', 'es': 'Sri Lanka',
    'pt': 'Sri Lanka', 'it': 'Sri Lanka', 'de': 'Sri Lanka',
    'zh-Hans': '斯里兰卡', 'zh-Hant': '斯里蘭卡',
  },
  'LR': {
    'fr': 'Libéria', 'en': 'Liberia', 'es': 'Liberia', 'pt': 'Libéria',
    'it': 'Liberia', 'de': 'Liberia', 'zh-Hans': '利比里亚', 'zh-Hant': '賴比瑞亞',
  },
  'LS': {
    'fr': 'Lesotho', 'en': 'Lesotho', 'es': 'Lesoto', 'pt': 'Lesoto',
    'it': 'Lesotho', 'de': 'Lesotho', 'zh-Hans': '莱索托', 'zh-Hant': '賴索托',
  },
  'LT': {
    'fr': 'Lituanie', 'en': 'Lithuania', 'es': 'Lituania', 'pt': 'Lituânia',
    'it': 'Lituania', 'de': 'Litauen', 'zh-Hans': '立陶宛', 'zh-Hant': '立陶宛',
  },
  'LU': {
    'fr': 'Luxembourg', 'en': 'Luxembourg', 'es': 'Luxemburgo',
    'pt': 'Luxemburgo', 'it': 'Lussemburgo', 'de': 'Luxemburg',
    'zh-Hans': '卢森堡', 'zh-Hant': '盧森堡',
  },
  'LV': {
    'fr': 'Lettonie', 'en': 'Latvia', 'es': 'Letonia', 'pt': 'Letónia',
    'it': 'Lettonia', 'de': 'Lettland', 'zh-Hans': '拉脱维亚', 'zh-Hant': '拉脫維亞',
  },
  'LY': {
    'fr': 'Libye', 'en': 'Libya', 'es': 'Libia', 'pt': 'Líbia',
    'it': 'Libia', 'de': 'Libyen', 'zh-Hans': '利比亚', 'zh-Hant': '利比亞',
  },
  'MA': {
    'fr': 'Maroc', 'en': 'Morocco', 'es': 'Marruecos', 'pt': 'Marrocos',
    'it': 'Marocco', 'de': 'Marokko', 'zh-Hans': '摩洛哥', 'zh-Hant': '摩洛哥',
  },
  'MC': {
    'fr': 'Monaco', 'en': 'Monaco', 'es': 'Mónaco', 'pt': 'Mónaco',
    'it': 'Monaco', 'de': 'Monaco', 'zh-Hans': '摩纳哥', 'zh-Hant': '摩納哥',
  },
  'MD': {
    'fr': 'Moldavie', 'en': 'Moldova', 'es': 'Moldavia', 'pt': 'Moldávia',
    'it': 'Moldavia', 'de': 'Moldau', 'zh-Hans': '摩尔多瓦', 'zh-Hant': '摩爾多瓦',
  },
  'ME': {
    'fr': 'Monténégro', 'en': 'Montenegro', 'es': 'Montenegro',
    'pt': 'Montenegro', 'it': 'Montenegro', 'de': 'Montenegro',
    'zh-Hans': '黑山', 'zh-Hant': '蒙特內哥羅',
  },
  'MG': {
    'fr': 'Madagascar', 'en': 'Madagascar', 'es': 'Madagascar',
    'pt': 'Madagáscar', 'it': 'Madagascar', 'de': 'Madagaskar',
    'zh-Hans': '马达加斯加', 'zh-Hant': '馬達加斯加',
  },
  'MH': {
    'fr': 'Îles Marshall', 'en': 'Marshall Islands', 'es': 'Islas Marshall',
    'pt': 'Ilhas Marshall', 'it': 'Isole Marshall', 'de': 'Marshallinseln',
    'zh-Hans': '马绍尔群岛', 'zh-Hant': '馬紹爾群島',
  },
  'MK': {
    'fr': 'Macédoine du Nord', 'en': 'North Macedonia',
    'es': 'Macedonia del Norte', 'pt': 'Macedónia do Norte',
    'it': 'Macedonia del Nord', 'de': 'Nordmazedonien',
    'zh-Hans': '北马其顿', 'zh-Hant': '北馬其頓',
  },
  'ML': {
    'fr': 'Mali', 'en': 'Mali', 'es': 'Malí', 'pt': 'Mali',
    'it': 'Mali', 'de': 'Mali', 'zh-Hans': '马里', 'zh-Hant': '馬利',
  },
  'MM': {
    'fr': 'Myanmar', 'en': 'Myanmar', 'es': 'Birmania', 'pt': 'Mianmar',
    'it': 'Myanmar', 'de': 'Myanmar', 'zh-Hans': '缅甸', 'zh-Hant': '緬甸',
  },
  'MN': {
    'fr': 'Mongolie', 'en': 'Mongolia', 'es': 'Mongolia', 'pt': 'Mongólia',
    'it': 'Mongolia', 'de': 'Mongolei', 'zh-Hans': '蒙古', 'zh-Hant': '蒙古',
  },
  'MR': {
    'fr': 'Mauritanie', 'en': 'Mauritania', 'es': 'Mauritania',
    'pt': 'Mauritânia', 'it': 'Mauritania', 'de': 'Mauretanien',
    'zh-Hans': '毛里塔尼亚', 'zh-Hant': '茅利塔尼亞',
  },
  'MT': {
    'fr': 'Malte', 'en': 'Malta', 'es': 'Malta', 'pt': 'Malta',
    'it': 'Malta', 'de': 'Malta', 'zh-Hans': '马耳他', 'zh-Hant': '馬爾他',
  },
  'MU': {
    'fr': 'Maurice', 'en': 'Mauritius', 'es': 'Mauricio', 'pt': 'Maurício',
    'it': 'Mauritius', 'de': 'Mauritius', 'zh-Hans': '毛里求斯', 'zh-Hant': '模里西斯',
  },
  'MV': {
    'fr': 'Maldives', 'en': 'Maldives', 'es': 'Maldivas', 'pt': 'Maldivas',
    'it': 'Maldive', 'de': 'Malediven', 'zh-Hans': '马尔代夫', 'zh-Hant': '馬爾地夫',
  },
  'MW': {
    'fr': 'Malawi', 'en': 'Malawi', 'es': 'Malaui', 'pt': 'Malávi',
    'it': 'Malawi', 'de': 'Malawi', 'zh-Hans': '马拉维', 'zh-Hant': '馬拉威',
  },
  'MX': {
    'fr': 'Mexique', 'en': 'Mexico', 'es': 'México', 'pt': 'México',
    'it': 'Messico', 'de': 'Mexiko', 'zh-Hans': '墨西哥', 'zh-Hant': '墨西哥',
  },
  'MY': {
    'fr': 'Malaisie', 'en': 'Malaysia', 'es': 'Malasia', 'pt': 'Malásia',
    'it': 'Malesia', 'de': 'Malaysia', 'zh-Hans': '马来西亚', 'zh-Hant': '馬來西亞',
  },
  'MZ': {
    'fr': 'Mozambique', 'en': 'Mozambique', 'es': 'Mozambique',
    'pt': 'Moçambique', 'it': 'Mozambico', 'de': 'Mosambik',
    'zh-Hans': '莫桑比克', 'zh-Hant': '莫三比克',
  },
  'NA': {
    'fr': 'Namibie', 'en': 'Namibia', 'es': 'Namibia', 'pt': 'Namíbia',
    'it': 'Namibia', 'de': 'Namibia', 'zh-Hans': '纳米比亚', 'zh-Hant': '納米比亞',
  },
  'NE': {
    'fr': 'Niger', 'en': 'Niger', 'es': 'Níger', 'pt': 'Níger',
    'it': 'Niger', 'de': 'Niger', 'zh-Hans': '尼日尔', 'zh-Hant': '尼日',
  },
  'NG': {
    'fr': 'Nigéria', 'en': 'Nigeria', 'es': 'Nigeria', 'pt': 'Nigéria',
    'it': 'Nigeria', 'de': 'Nigeria', 'zh-Hans': '尼日利亚', 'zh-Hant': '奈及利亞',
  },
  'NI': {
    'fr': 'Nicaragua', 'en': 'Nicaragua', 'es': 'Nicaragua', 'pt': 'Nicarágua',
    'it': 'Nicaragua', 'de': 'Nicaragua', 'zh-Hans': '尼加拉瓜', 'zh-Hant': '尼加拉瓜',
  },
  'NL': {
    'fr': 'Pays-Bas', 'en': 'Netherlands', 'es': 'Países Bajos',
    'pt': 'Países Baixos', 'it': 'Paesi Bassi', 'de': 'Niederlande',
    'zh-Hans': '荷兰', 'zh-Hant': '荷蘭',
  },
  'NO': {
    'fr': 'Norvège', 'en': 'Norway', 'es': 'Noruega', 'pt': 'Noruega',
    'it': 'Norvegia', 'de': 'Norwegen', 'zh-Hans': '挪威', 'zh-Hant': '挪威',
  },
  'NP': {
    'fr': 'Népal', 'en': 'Nepal', 'es': 'Nepal', 'pt': 'Nepal',
    'it': 'Nepal', 'de': 'Nepal', 'zh-Hans': '尼泊尔', 'zh-Hant': '尼泊爾',
  },
  'NZ': {
    'fr': 'Nouvelle-Zélande', 'en': 'New Zealand', 'es': 'Nueva Zelanda',
    'pt': 'Nova Zelândia', 'it': 'Nuova Zelanda', 'de': 'Neuseeland',
    'zh-Hans': '新西兰', 'zh-Hant': '紐西蘭',
  },
  'OM': {
    'fr': 'Oman', 'en': 'Oman', 'es': 'Omán', 'pt': 'Omã',
    'it': 'Oman', 'de': 'Oman', 'zh-Hans': '阿曼', 'zh-Hant': '阿曼',
  },
  'PA': {
    'fr': 'Panama', 'en': 'Panama', 'es': 'Panamá', 'pt': 'Panamá',
    'it': 'Panama', 'de': 'Panama', 'zh-Hans': '巴拿马', 'zh-Hant': '巴拿馬',
  },
  'PE': {
    'fr': 'Pérou', 'en': 'Peru', 'es': 'Perú', 'pt': 'Peru',
    'it': 'Perù', 'de': 'Peru', 'zh-Hans': '秘鲁', 'zh-Hant': '秘魯',
  },
  'PG': {
    'fr': 'Papouasie-Nouvelle-Guinée', 'en': 'Papua New Guinea',
    'es': 'Papúa Nueva Guinea', 'pt': 'Papua-Nova Guiné',
    'it': 'Papua Nuova Guinea', 'de': 'Papua-Neuguinea',
    'zh-Hans': '巴布亚新几内亚', 'zh-Hant': '巴布亞紐幾內亞',
  },
  'PH': {
    'fr': 'Philippines', 'en': 'Philippines', 'es': 'Filipinas',
    'pt': 'Filipinas', 'it': 'Filippine', 'de': 'Philippinen',
    'zh-Hans': '菲律宾', 'zh-Hant': '菲律賓',
  },
  'PK': {
    'fr': 'Pakistan', 'en': 'Pakistan', 'es': 'Pakistán', 'pt': 'Paquistão',
    'it': 'Pakistan', 'de': 'Pakistan', 'zh-Hans': '巴基斯坦', 'zh-Hant': '巴基斯坦',
  },
  'PL': {
    'fr': 'Pologne', 'en': 'Poland', 'es': 'Polonia', 'pt': 'Polónia',
    'it': 'Polonia', 'de': 'Polen', 'zh-Hans': '波兰', 'zh-Hant': '波蘭',
  },
  'PR': {
    'fr': 'Porto Rico', 'en': 'Puerto Rico', 'es': 'Puerto Rico',
    'pt': 'Porto Rico', 'it': 'Porto Rico', 'de': 'Puerto Rico',
    'zh-Hans': '波多黎各', 'zh-Hant': '波多黎各',
  },
  'PT': {
    'fr': 'Portugal', 'en': 'Portugal', 'es': 'Portugal', 'pt': 'Portugal',
    'it': 'Portogallo', 'de': 'Portugal', 'zh-Hans': '葡萄牙', 'zh-Hant': '葡萄牙',
  },
  'PW': {
    'fr': 'Palaos', 'en': 'Palau', 'es': 'Palaos', 'pt': 'Palau',
    'it': 'Palau', 'de': 'Palau', 'zh-Hans': '帕劳', 'zh-Hant': '帛琉',
  },
  'PY': {
    'fr': 'Paraguay', 'en': 'Paraguay', 'es': 'Paraguay', 'pt': 'Paraguai',
    'it': 'Paraguay', 'de': 'Paraguay', 'zh-Hans': '巴拉圭', 'zh-Hant': '巴拉圭',
  },
  'QA': {
    'fr': 'Qatar', 'en': 'Qatar', 'es': 'Catar', 'pt': 'Catar',
    'it': 'Qatar', 'de': 'Katar', 'zh-Hans': '卡塔尔', 'zh-Hant': '卡達',
  },
  'RO': {
    'fr': 'Roumanie', 'en': 'Romania', 'es': 'Rumania', 'pt': 'Roménia',
    'it': 'Romania', 'de': 'Rumänien', 'zh-Hans': '罗马尼亚', 'zh-Hant': '羅馬尼亞',
  },
  'RS': {
    'fr': 'Serbie', 'en': 'Serbia', 'es': 'Serbia', 'pt': 'Sérvia',
    'it': 'Serbia', 'de': 'Serbien', 'zh-Hans': '塞尔维亚', 'zh-Hant': '塞爾維亞',
  },
  'RU': {
    'fr': 'Russie', 'en': 'Russia', 'es': 'Rusia', 'pt': 'Rússia',
    'it': 'Russia', 'de': 'Russland', 'zh-Hans': '俄罗斯', 'zh-Hant': '俄羅斯',
  },
  'RW': {
    'fr': 'Rwanda', 'en': 'Rwanda', 'es': 'Ruanda', 'pt': 'Ruanda',
    'it': 'Ruanda', 'de': 'Ruanda', 'zh-Hans': '卢旺达', 'zh-Hant': '盧安達',
  },
  'SA': {
    'fr': 'Arabie saoudite', 'en': 'Saudi Arabia', 'es': 'Arabia Saudita',
    'pt': 'Arábia Saudita', 'it': 'Arabia Saudita', 'de': 'Saudi-Arabien',
    'zh-Hans': '沙特阿拉伯', 'zh-Hant': '沙烏地阿拉伯',
  },
  'SB': {
    'fr': 'Îles Salomon', 'en': 'Solomon Islands', 'es': 'Islas Salomón',
    'pt': 'Ilhas Salomão', 'it': 'Isole Salomone', 'de': 'Salomonen',
    'zh-Hans': '所罗门群岛', 'zh-Hant': '索羅門群島',
  },
  'SC': {
    'fr': 'Seychelles', 'en': 'Seychelles', 'es': 'Seychelles',
    'pt': 'Seicheles', 'it': 'Seychelles', 'de': 'Seychellen',
    'zh-Hans': '塞舌尔', 'zh-Hant': '塞席爾',
  },
  'SD': {
    'fr': 'Soudan', 'en': 'Sudan', 'es': 'Sudán', 'pt': 'Sudão',
    'it': 'Sudan', 'de': 'Sudan', 'zh-Hans': '苏丹', 'zh-Hant': '蘇丹',
  },
  'SE': {
    'fr': 'Suède', 'en': 'Sweden', 'es': 'Suecia', 'pt': 'Suécia',
    'it': 'Svezia', 'de': 'Schweden', 'zh-Hans': '瑞典', 'zh-Hant': '瑞典',
  },
  'SG': {
    'fr': 'Singapour', 'en': 'Singapore', 'es': 'Singapur', 'pt': 'Singapura',
    'it': 'Singapore', 'de': 'Singapur', 'zh-Hans': '新加坡', 'zh-Hant': '新加坡',
  },
  'SI': {
    'fr': 'Slovénie', 'en': 'Slovenia', 'es': 'Eslovenia', 'pt': 'Eslovénia',
    'it': 'Slovenia', 'de': 'Slowenien', 'zh-Hans': '斯洛文尼亚', 'zh-Hant': '斯洛維尼亞',
  },
  'SK': {
    'fr': 'Slovaquie', 'en': 'Slovakia', 'es': 'Eslovaquia', 'pt': 'Eslováquia',
    'it': 'Slovacchia', 'de': 'Slowakei', 'zh-Hans': '斯洛伐克', 'zh-Hant': '斯洛伐克',
  },
  'SL': {
    'fr': 'Sierra Leone', 'en': 'Sierra Leone', 'es': 'Sierra Leona',
    'pt': 'Serra Leoa', 'it': 'Sierra Leone', 'de': 'Sierra Leone',
    'zh-Hans': '塞拉利昂', 'zh-Hant': '獅子山',
  },
  'SM': {
    'fr': 'Saint-Marin', 'en': 'San Marino', 'es': 'San Marino',
    'pt': 'São Marinho', 'it': 'San Marino', 'de': 'San Marino',
    'zh-Hans': '圣马力诺', 'zh-Hant': '聖馬利諾',
  },
  'SN': {
    'fr': 'Sénégal', 'en': 'Senegal', 'es': 'Senegal', 'pt': 'Senegal',
    'it': 'Senegal', 'de': 'Senegal', 'zh-Hans': '塞内加尔', 'zh-Hant': '塞內加爾',
  },
  'SO': {
    'fr': 'Somalie', 'en': 'Somalia', 'es': 'Somalia', 'pt': 'Somália',
    'it': 'Somalia', 'de': 'Somalia', 'zh-Hans': '索马里', 'zh-Hant': '索馬利亞',
  },
  'SR': {
    'fr': 'Suriname', 'en': 'Suriname', 'es': 'Surinam', 'pt': 'Suriname',
    'it': 'Suriname', 'de': 'Suriname', 'zh-Hans': '苏里南', 'zh-Hant': '蘇利南',
  },
  'SS': {
    'fr': 'Soudan du Sud', 'en': 'South Sudan', 'es': 'Sudán del Sur',
    'pt': 'Sudão do Sul', 'it': 'Sudan del Sud', 'de': 'Südsudan',
    'zh-Hans': '南苏丹', 'zh-Hant': '南蘇丹',
  },
  'ST': {
    'fr': 'Sao Tomé-et-Principe', 'en': 'Sao Tome and Principe',
    'es': 'Santo Tomé y Príncipe', 'pt': 'São Tomé e Príncipe',
    'it': 'Sao Tomé e Príncipe', 'de': 'São Tomé und Príncipe',
    'zh-Hans': '圣多美和普林西比', 'zh-Hant': '聖多美普林西比',
  },
  'SV': {
    'fr': 'Salvador', 'en': 'El Salvador', 'es': 'El Salvador',
    'pt': 'El Salvador', 'it': 'El Salvador', 'de': 'El Salvador',
    'zh-Hans': '萨尔瓦多', 'zh-Hant': '薩爾瓦多',
  },
  'SY': {
    'fr': 'Syrie', 'en': 'Syria', 'es': 'Siria', 'pt': 'Síria',
    'it': 'Siria', 'de': 'Syrien', 'zh-Hans': '叙利亚', 'zh-Hant': '敘利亞',
  },
  'SZ': {
    'fr': 'Eswatini', 'en': 'Swaziland', 'es': 'Esuatini', 'pt': 'Suazilândia',
    'it': 'eSwatini', 'de': 'Eswatini', 'zh-Hans': '斯威士兰', 'zh-Hant': '史瓦帝尼',
  },
  'TD': {
    'fr': 'Tchad', 'en': 'Chad', 'es': 'Chad', 'pt': 'Chade',
    'it': 'Ciad', 'de': 'Tschad', 'zh-Hans': '乍得', 'zh-Hant': '查德',
  },
  'TG': {
    'fr': 'Togo', 'en': 'Togo', 'es': 'Togo', 'pt': 'Togo',
    'it': 'Togo', 'de': 'Togo', 'zh-Hans': '多哥', 'zh-Hant': '多哥',
  },
  'TH': {
    'fr': 'Thaïlande', 'en': 'Thailand', 'es': 'Tailandia', 'pt': 'Tailândia',
    'it': 'Thailandia', 'de': 'Thailand', 'zh-Hans': '泰国', 'zh-Hant': '泰國',
  },
  'TJ': {
    'fr': 'Tadjikistan', 'en': 'Tajikistan', 'es': 'Tayikistán',
    'pt': 'Tajiquistão', 'it': 'Tagikistan', 'de': 'Tadschikistan',
    'zh-Hans': '塔吉克斯坦', 'zh-Hant': '塔吉克',
  },
  'TL': {
    'fr': 'Timor oriental', 'en': 'East Timor', 'es': 'Timor Oriental',
    'pt': 'Timor-Leste', 'it': 'Timor Est', 'de': 'Osttimor',
    'zh-Hans': '东帝汶', 'zh-Hant': '東帝汶',
  },
  'TM': {
    'fr': 'Turkménistan', 'en': 'Turkmenistan', 'es': 'Turkmenistán',
    'pt': 'Turcomenistão', 'it': 'Turkmenistan', 'de': 'Turkmenistan',
    'zh-Hans': '土库曼斯坦', 'zh-Hant': '土庫曼',
  },
  'TN': {
    'fr': 'Tunisie', 'en': 'Tunisia', 'es': 'Túnez', 'pt': 'Tunísia',
    'it': 'Tunisia', 'de': 'Tunesien', 'zh-Hans': '突尼斯', 'zh-Hant': '突尼西亞',
  },
  'TO': {
    'fr': 'Tonga', 'en': 'Tonga', 'es': 'Tonga', 'pt': 'Tonga',
    'it': 'Tonga', 'de': 'Tonga', 'zh-Hans': '汤加', 'zh-Hant': '東加',
  },
  'TR': {
    'fr': 'Turquie', 'en': 'Turkey', 'es': 'Turquía', 'pt': 'Turquia',
    'it': 'Turchia', 'de': 'Türkei', 'zh-Hans': '土耳其', 'zh-Hant': '土耳其',
  },
  'TT': {
    'fr': 'Trinité-et-Tobago', 'en': 'Trinidad and Tobago',
    'es': 'Trinidad y Tobago', 'pt': 'Trindade e Tobago',
    'it': 'Trinidad e Tobago', 'de': 'Trinidad und Tobago',
    'zh-Hans': '特立尼达和多巴哥', 'zh-Hant': '千里達及托巴哥',
  },
  'TV': {
    'fr': 'Tuvalu', 'en': 'Tuvalu', 'es': 'Tuvalu', 'pt': 'Tuvalu',
    'it': 'Tuvalu', 'de': 'Tuvalu', 'zh-Hans': '图瓦卢', 'zh-Hant': '吐瓦魯',
  },
  'TW': {
    'fr': 'Taïwan', 'en': 'Taiwan', 'es': 'Taiwán', 'pt': 'Taiwan',
    'it': 'Taiwan', 'de': 'Taiwan', 'zh-Hans': '台湾', 'zh-Hant': '臺灣',
  },
  'TZ': {
    'fr': 'Tanzanie', 'en': 'Tanzania', 'es': 'Tanzania', 'pt': 'Tanzânia',
    'it': 'Tanzania', 'de': 'Tansania', 'zh-Hans': '坦桑尼亚', 'zh-Hant': '坦尚尼亞',
  },
  'UA': {
    'fr': 'Ukraine', 'en': 'Ukraine', 'es': 'Ucrania', 'pt': 'Ucrânia',
    'it': 'Ucraina', 'de': 'Ukraine', 'zh-Hans': '乌克兰', 'zh-Hant': '烏克蘭',
  },
  'UG': {
    'fr': 'Ouganda', 'en': 'Uganda', 'es': 'Uganda', 'pt': 'Uganda',
    'it': 'Uganda', 'de': 'Uganda', 'zh-Hans': '乌干达', 'zh-Hant': '烏干達',
  },
  'US': {
    'fr': 'États-Unis', 'en': 'United States of America',
    'es': 'Estados Unidos', 'pt': 'Estados Unidos',
    'it': 'Stati Uniti', 'de': 'Vereinigte Staaten',
    'zh-Hans': '美国', 'zh-Hant': '美國',
  },
  'UY': {
    'fr': 'Uruguay', 'en': 'Uruguay', 'es': 'Uruguay', 'pt': 'Uruguai',
    'it': 'Uruguay', 'de': 'Uruguay', 'zh-Hans': '乌拉圭', 'zh-Hant': '烏拉圭',
  },
  'UZ': {
    'fr': 'Ouzbékistan', 'en': 'Uzbekistan', 'es': 'Uzbekistán',
    'pt': 'Usbequistão', 'it': 'Uzbekistan', 'de': 'Usbekistan',
    'zh-Hans': '乌兹别克斯坦', 'zh-Hant': '烏茲別克',
  },
  'VA': {
    'fr': 'Vatican', 'en': 'Vatican (Holy See)', 'es': 'Vaticano',
    'pt': 'Vaticano', 'it': 'Vaticano', 'de': 'Vatikan',
    'zh-Hans': '梵蒂冈', 'zh-Hant': '梵蒂岡',
  },
  'VC': {
    'fr': 'Saint-Vincent-et-les-Grenadines', 'en': 'Saint Vincent and the Grenadines',
    'es': 'San Vicente y las Granadinas', 'pt': 'São Vicente e Granadinas',
    'it': 'Saint Vincent e Grenadine', 'de': 'St. Vincent und die Grenadinen',
    'zh-Hans': '圣文森特和格林纳丁斯', 'zh-Hant': '聖文森及格瑞那丁',
  },
  'VE': {
    'fr': 'Venezuela', 'en': 'Venezuela', 'es': 'Venezuela', 'pt': 'Venezuela',
    'it': 'Venezuela', 'de': 'Venezuela', 'zh-Hans': '委内瑞拉', 'zh-Hant': '委內瑞拉',
  },
  'VN': {
    'fr': 'Viêt Nam', 'en': 'Vietnam', 'es': 'Vietnam', 'pt': 'Vietname',
    'it': 'Vietnam', 'de': 'Vietnam', 'zh-Hans': '越南', 'zh-Hant': '越南',
  },
  'VU': {
    'fr': 'Vanuatu', 'en': 'Vanuatu', 'es': 'Vanuatu', 'pt': 'Vanuatu',
    'it': 'Vanuatu', 'de': 'Vanuatu', 'zh-Hans': '瓦努阿图', 'zh-Hant': '萬那杜',
  },
  'WS': {
    'fr': 'Samoa', 'en': 'Samoa', 'es': 'Samoa', 'pt': 'Samoa',
    'it': 'Samoa', 'de': 'Samoa', 'zh-Hans': '萨摩亚', 'zh-Hant': '薩摩亞',
  },
  'YE': {
    'fr': 'Yémen', 'en': 'Yemen', 'es': 'Yemen', 'pt': 'Iémen',
    'it': 'Yemen', 'de': 'Jemen', 'zh-Hans': '也门', 'zh-Hant': '葉門',
  },
  'ZA': {
    'fr': 'Afrique du Sud', 'en': 'South Africa', 'es': 'Sudáfrica',
    'pt': 'África do Sul', 'it': 'Sudafrica', 'de': 'Südafrika',
    'zh-Hans': '南非', 'zh-Hant': '南非',
  },
  'ZM': {
    'fr': 'Zambie', 'en': 'Zambia', 'es': 'Zambia', 'pt': 'Zâmbia',
    'it': 'Zambia', 'de': 'Sambia', 'zh-Hans': '赞比亚', 'zh-Hant': '尚比亞',
  },
  'ZW': {
    'fr': 'Zimbabwe', 'en': 'Zimbabwe', 'es': 'Zimbabue', 'pt': 'Zimbábue',
    'it': 'Zimbabwe', 'de': 'Simbabwe', 'zh-Hans': '津巴布韦', 'zh-Hant': '辛巴威',
  },
};

/* the name of a country in the language of the interface, the English
   name of the city list stands in when the code has no entry */
String countryName(String cc, String english) =>
    _names[cc]?[appLanguage] ?? english;