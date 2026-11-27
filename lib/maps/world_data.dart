/* The data of the world map, ported from the web sources of the
   Drive folder nouvel-onglet-sources: the world city list
   ( WM_CITYLIST of js/monde/monde.js ), the real time zones with
   their IANA names per country and their longitude bands for the
   multi-zone countries ( WM_TZ and WM_TZ_CITY of
   js/monde/villes-marquees.js ), the Natural Earth time zone
   borders ( WM_TZ_BORDERS ) and the disputed border overlays
   ( WM_DISPUTED, WM_BERM, WM_KOSOVO, WM_CHYPRE, WM_GOLAN,
   WM_ARUNACHAL, WM_ESSEQUIBO, WM_SENKAKU ).
   SPDX-License-Identifier: MIT. */

/* a city of the world: name, country, country code, latitude,
   longitude, the WM_CITIES fields of the web */
class WorldCity {
  final String name, country, cc;
  final double lat, lon;
  const WorldCity(this.name, this.country, this.cc, this.lat, this.lon);
}

/* the whole list of the web, one city per line:
   name;country;code;latitude;longitude */
const String worldCityListStr = r'''
Kabul;Afghanistan;AF;34.52;69.18
Tirana;Albania;AL;41.33;19.82
Algiers;Algeria;DZ;36.76;3.05
Andorra;Andorra;AD;42.5;1.52
Huambo;Angola;AO;-12.75;15.76
Luanda;Angola;AO;-8.84;13.23
Saint John's;Antigua and Barbuda;AG;17.12;-61.85
Buenos Aires;Argentina;AR;-34.6;-58.4
Córdoba;Argentina;AR;-31.4;-64.18
Rosario;Argentina;AR;-32.95;-60.67
Yerevan;Armenia;AM;40.18;44.51
Adelaide;Australia;AU;-34.93;138.6
Brisbane;Australia;AU;-27.46;153.04
Canberra;Australia;AU;-35.28;149.13
Melbourne;Australia;AU;-37.82;144.98
Newcastle;Australia;AU;-32.85;151.82
Perth;Australia;AU;-31.96;115.84
Sydney;Australia;AU;-33.92;151.19
Vienna;Austria;AT;48.2;16.37
Baku;Azerbaijan;AZ;40.4;49.86
Manama;Bahrain;BH;26.24;50.58
Chittagong;Bangladesh;BD;22.33;91.8
Dhaka;Bangladesh;BD;23.72;90.41
Khulna;Bangladesh;BD;22.84;89.56
Bridgetown;Barbados;BB;13.1;-59.62
Minsk;Belarus;BY;53.9;27.57
Brussels;Belgium;BE;50.83;4.33
Belmopan;Belize;BZ;17.25;-88.77
Cotonou;Benin;BJ;6.4;2.52
Porto-Novo;Benin;BJ;6.48;2.62
Hamilton;Bermuda;BM;32.29;-64.78
Thimphu;Bhutan;BT;27.47;89.64
La Paz;Bolivia;BO;-16.5;-68.15
Santa Cruz;Bolivia;BO;-17.75;-63.23
Sucre;Bolivia;BO;-19.04;-65.26
Sarajevo;Bosnia and Herzegovina;BA;43.85;18.38
Gaborone;Botswana;BW;-24.65;25.91
Belém;Brazil;BR;-1.45;-48.48
Belo Horizonte;Brazil;BR;-19.92;-43.92
Brasília;Brazil;BR;-15.78;-47.92
Campinas;Brazil;BR;-22.9;-47.1
Curitiba;Brazil;BR;-25.42;-49.32
Florianópolis;Brazil;BR;-27.58;-48.52
Fortaleza;Brazil;BR;-3.75;-38.58
Goiânia;Brazil;BR;-16.72;-49.3
Maceió;Brazil;BR;-9.62;-35.73
Manaus;Brazil;BR;-3.1;-60
Natal;Brazil;BR;-5.78;-35.24
Porto Alegre;Brazil;BR;-30.05;-51.2
Recife;Brazil;BR;-8.08;-34.92
Rio de Janeiro;Brazil;BR;-22.93;-43.23
Salvador;Brazil;BR;-12.97;-38.48
São Luís;Brazil;BR;-2.52;-44.27
São Paulo;Brazil;BR;-23.56;-46.63
Vila Velha;Brazil;BR;-20.37;-40.32
Bandar Seri Begawan;Brunei;BN;4.88;114.93
Sofia;Bulgaria;BG;42.68;23.32
Ouagadougou;Burkina Faso;BF;12.37;-1.52
Bujumbura;Burundi;BI;-3.38;29.36
Phnom Penh;Cambodia;KH;11.55;104.92
Douala;Cameroon;CM;4.06;9.71
Yaounde;Cameroon;CM;3.87;11.52
Calgary;Canada;CA;51.08;-114.08
Edmonton;Canada;CA;53.55;-113.5
Montréal;Canada;CA;45.5;-73.58
Ottawa;Canada;CA;45.42;-75.7
Toronto;Canada;CA;43.7;-79.42
Vancouver;Canada;CA;49.27;-123.12
Praia;Cape Verde;CV;14.92;-23.52
Bangui;Central African Republic;CF;4.37;18.56
Ndjamena;Chad;TD;12.11;15.05
Santiago;Chile;CL;-33.45;-70.67
Valparaíso;Chile;CL;-33.05;-71.62
Ankang;China;CN;32.68;109.02
Anshan;China;CN;41.12;122.94
Baoshan;China;CN;25.12;99.15
Baotou;China;CN;40.65;109.82
Beijing;China;CN;39.93;116.39
Changchun;China;CN;43.87;125.34
Changsha;China;CN;28.2;112.97
Chengdu;China;CN;30.67;104.07
Chifeng;China;CN;42.27;118.95
Chongqing;China;CN;29.56;106.59
Dalian;China;CN;38.92;121.63
Daqing;China;CN;46.58;125
Dongguan;China;CN;23.05;113.74
Fuzhou;China;CN;26.08;119.3
Guangzhou;China;CN;23.14;113.33
Guiyang;China;CN;26.58;106.72
Handan;China;CN;36.58;114.48
Hangzhou;China;CN;30.25;120.17
Harbin;China;CN;45.75;126.65
Hefei;China;CN;31.85;117.28
Hengyang;China;CN;26.88;112.59
Hohhot;China;CN;40.82;111.66
Huainan;China;CN;32.63;116.98
Huaiyin;China;CN;33.58;119.03
Jiamusi;China;CN;46.83;130.35
Jilin;China;CN;43.85;126.55
Jinan;China;CN;36.67;117
Jinxi;China;CN;40.75;120.83
Kunming;China;CN;25.07;102.68
Lanzhou;China;CN;36.06;103.79
Linyi;China;CN;35.08;118.33
Lupanshui;China;CN;26.59;104.83
Mianyang;China;CN;31.47;104.77
Nanchang;China;CN;28.68;115.88
Nanchong;China;CN;30.78;106.13
Nanjing;China;CN;32.05;118.78
Nanning;China;CN;22.82;108.32
Nanyang;China;CN;33;112.53
Neijiang;China;CN;29.58;105.05
Ningbo;China;CN;29.88;121.55
Qingdao;China;CN;36.09;120.33
Qiqihar;China;CN;47.34;123.99
Quanzhou;China;CN;24.9;118.58
Shanghai;China;CN;31.22;121.44
Shantou;China;CN;23.37;116.67
Shenyeng;China;CN;41.8;123.45
Shenzhen;China;CN;22.55;114.12
Shijianzhuang;China;CN;38.05;114.48
Suzhou;China;CN;33.64;116.98
Taiyuan;China;CN;37.88;112.55
Tianjin;China;CN;39.13;117.2
Tianshui;China;CN;34.6;105.92
Ürümqi;China;CN;43.81;87.58
Wenzhou;China;CN;28.02;120.65
Wuhan;China;CN;30.58;114.27
Wuxi;China;CN;31.58;120.3
Xiamen;China;CN;24.45;118.08
Xian;China;CN;34.28;108.89
Xining;China;CN;36.62;101.77
Xuzhou;China;CN;34.28;117.18
Yantai;China;CN;37.53;121.4
Yulin;China;CN;22.63;110.15
Zaozhuang;China;CN;34.88;117.57
Zhanjiang;China;CN;21.2;110.38
Zhengzhou;China;CN;34.75;113.67
Zibo;China;CN;36.8;118.05
Barranquilla;Colombia;CO;10.96;-74.8
Bogota;Colombia;CO;4.6;-74.08
Cali;Colombia;CO;3.4;-76.5
Medellín;Colombia;CO;6.28;-75.58
Moroni;Comoros;KM;-11.7;43.24
Brazzaville;Congo (Brazzaville);CG;-4.26;15.28
Kinshasa;Congo (Kinshasa);CD;-4.33;15.31
Lubumbashi;Congo (Kinshasa);CD;-11.68;27.48
Mbuji-Mayi;Congo (Kinshasa);CD;-6.15;23.6
San José;Costa Rica;CR;9.94;-84.08
Zagreb;Croatia;HR;45.8;16
Havana;Cuba;CU;23.13;-82.36
Nicosia;Cyprus;CY;35.17;33.37
Prague;Czech Republic;CZ;50.08;14.47
København;Denmark;DK;55.68;12.56
Djibouti;Djibouti;DJ;11.6;43.15
Roseau;Dominica;DM;15.3;-61.39
Santiago;Dominican Republic;DO;19.5;-70.67
Santo Domingo;Dominican Republic;DO;18.47;-69.9
Dili;East Timor;TL;-8.56;125.58
Guayaquil;Ecuador;EC;-2.22;-79.92
Quito;Ecuador;EC;-0.21;-78.5
Alexandria;Egypt;EG;31.2;29.95
Cairo;Egypt;EG;30.05;31.25
San Salvador;El Salvador;SV;13.71;-89.2
Malabo;Equatorial Guinea;GQ;3.75;8.78
Asmara;Eritrea;ER;15.33;38.93
Tallinn;Estonia;EE;59.43;24.73
Addis Ababa;Ethiopia;ET;9.03;38.7
Palikir;Federated States of Micronesia;FM;6.92;158.15
Suva;Fiji;FJ;-18.13;178.44
Helsinki;Finland;FI;60.18;24.93
Lille;France;FR;50.65;3.08
Lyon;France;FR;45.77;4.83
Marseille;France;FR;43.29;5.38
Paris;France;FR;48.87;2.33
Libreville;Gabon;GA;0.39;9.46
Tbilisi;Georgia;GE;41.73;44.79
Berlin;Germany;DE;52.52;13.4
Frankfurt;Germany;DE;50.1;8.68
Hamburg;Germany;DE;53.55;10
Munich;Germany;DE;48.13;11.57
Accra;Ghana;GH;5.55;-0.22
Athens;Greece;GR;37.98;23.73
Saint George's;Grenada;GD;12.05;-61.74
Guatemala;Guatemala;GT;14.62;-90.53
Conakry;Guinea;GN;9.53;-13.68
Bissau;Guinea Bissau;GW;11.87;-15.6
Georgetown;Guyana;GY;6.8;-58.17
Port-au-Prince;Haiti;HT;18.54;-72.34
Tegucigalpa;Honduras;HN;14.1;-87.22
Hong Kong;Hong Kong S.A.R.;HK;22.3;114.19
Budapest;Hungary;HU;47.5;19.08
Reykjavík;Iceland;IS;64.15;-21.95
Agra;India;IN;27.17;78.02
Ahmedabad;India;IN;23.03;72.58
Allahabad;India;IN;25.45;81.84
Amritsar;India;IN;31.64;74.87
Asansol;India;IN;23.68;86.98
Aurangabad;India;IN;19.9;75.32
Bangalore;India;IN;12.97;77.56
Bhilai;India;IN;21.22;81.43
Bhopal;India;IN;23.25;77.41
Chennai;India;IN;13.09;80.28
Coimbatore;India;IN;11;76.95
Delhi;India;IN;28.67;77.23
Dhanbad;India;IN;23.8;86.42
Faridabad;India;IN;28.43;77.32
Ghaziabad;India;IN;28.66;77.41
Hyderabad;India;IN;17.4;78.48
Indore;India;IN;22.72;75.87
Jabalpur;India;IN;23.18;79.96
Jaipur;India;IN;26.92;75.81
Jamshedpur;India;IN;22.79;86.2
Kanpur;India;IN;26.46;80.32
Kochi;India;IN;10.02;76.22
Kolkata;India;IN;22.49;88.32
Lucknow;India;IN;26.86;80.91
Ludhiana;India;IN;30.93;75.87
Madurai;India;IN;9.92;78.12
Meerut;India;IN;29;77.7
Mumbai;India;IN;19.02;72.86
Nagpur;India;IN;21.17;79.09
Nasik;India;IN;20;73.78
New Delhi;India;IN;28.6;77.2
Patna;India;IN;25.62;85.13
Pune;India;IN;18.53;73.85
Rajkot;India;IN;22.31;70.8
Ranchi;India;IN;23.37;85.33
Sholapur;India;IN;17.67;75.9
Srinagar;India;IN;34.1;74.82
Surat;India;IN;21.2;72.84
Vadodara;India;IN;22.31;73.18
Varanasi;India;IN;25.33;83
Vijayawada;India;IN;16.52;80.63
Vishakhapatnam;India;IN;17.73;83.3
Bandung;Indonesia;ID;-6.95;107.57
Jakarta;Indonesia;ID;-6.17;106.83
Medan;Indonesia;ID;3.58;98.65
Palembang;Indonesia;ID;-2.98;104.75
Semarang;Indonesia;ID;-6.97;110.42
Surabaya;Indonesia;ID;-7.25;112.75
Ujungpandang;Indonesia;ID;-5.14;119.43
Isfahan;Iran;IR;32.7;51.7
Mashhad;Iran;IR;36.27;59.57
Shiraz;Iran;IR;29.63;52.57
Tabriz;Iran;IR;38.09;46.3
Tehran;Iran;IR;35.67;51.42
Baghdad;Iraq;IQ;33.34;44.39
Mosul;Iraq;IQ;36.35;43.15
Dublin;Ireland;IE;53.33;-6.25
Jerusalem;Israel;IL;31.78;35.21
Tel Aviv-Yafo;Israel;IL;32.08;34.77
Florence;Italy;IT;43.78;11.25
Milan;Italy;IT;45.47;9.21
Naples;Italy;IT;40.84;14.25
Rome;Italy;IT;41.9;12.48
Turin;Italy;IT;45.07;7.67
Abidjan;Ivory Coast;CI;5.32;-4.04
Yamoussoukro;Ivory Coast;CI;6.82;-5.28
Kingston;Jamaica;JM;17.98;-76.77
Fukuoka;Japan;JP;33.6;130.41
Hiroshima;Japan;JP;34.39;132.44
Kyoto;Japan;JP;35.03;135.75
Nagoya;Japan;JP;35.15;136.91
Ōsaka;Japan;JP;34.75;135.46
Sapporo;Japan;JP;43.07;141.34
Sendai;Japan;JP;38.29;141.02
Tokyo;Japan;JP;35.69;139.75
Amman;Jordan;JO;31.95;35.93
Almaty;Kazakhstan;KZ;43.32;76.92
Astana;Kazakhstan;KZ;51.18;71.43
Nairobi;Kenya;KE;-1.28;36.82
Tarawa;Kiribati;KI;1.34;173.02
Pristina;Kosovo;;42.67;21.17
Kuwait;Kuwait;KW;29.37;47.98
Bishkek;Kyrgyzstan;KG;42.87;74.59
Vientiane;Laos;LA;17.97;102.6
Riga;Latvia;LV;56.95;24.1
Beirut;Lebanon;LB;33.87;35.51
Maseru;Lesotho;LS;-29.32;27.48
Monrovia;Liberia;LR;6.31;-10.8
Banghazi;Libya;LY;32.12;20.07
Tripoli;Libya;LY;32.89;13.18
Vaduz;Liechtenstein;LI;47.13;9.52
Vilnius;Lithuania;LT;54.68;25.32
Luxembourg;Luxembourg;LU;49.61;6.13
Skopje;Macedonia;MK;42;21.43
Antananarivo;Madagascar;MG;-18.92;47.52
Lilongwe;Malawi;MW;-13.98;33.78
George Town;Malaysia;MY;5.41;100.33
Kuala Lumpur;Malaysia;MY;3.17;101.7
Putrajaya;Malaysia;MY;2.91;101.7
Malé;Maldives;MV;4.17;73.5
Bamako;Mali;ML;12.65;-8
Valletta;Malta;MT;35.9;14.51
Majuro;Marshall Islands;MH;7.1;171.38
Nouakchott;Mauritania;MR;18.09;-15.98
Port Louis;Mauritius;MU;-20.17;57.5
Guadalajara;Mexico;MX;20.67;-103.33
León;Mexico;MX;21.15;-101.7
Mexico City;Mexico;MX;19.44;-99.13
Monterrey;Mexico;MX;25.67;-100.33
Puebla;Mexico;MX;19.05;-98.2
Tijuana;Mexico;MX;32.5;-117.08
Torreón;Mexico;MX;25.57;-103.42
Chișinău;Moldova;MD;47.01;28.86
Monaco;Monaco;MC;43.74;7.41
Ulaanbaatar;Mongolia;MN;47.92;106.92
Podgorica;Montenegro;ME;42.47;19.27
Casablanca;Morocco;MA;33.6;-7.62
Fez;Morocco;MA;34.05;-5
Laayoune;Morocco;MA;27.15;-13.2
Rabat;Morocco;MA;34.03;-6.84
Maputo;Mozambique;MZ;-25.96;32.59
Mandalay;Myanmar;MM;21.97;96.09
Naypyidaw;Myanmar;MM;19.77;96.12
Rangoon;Myanmar;MM;16.78;96.17
Windhoek;Namibia;NA;-22.57;17.08
Kathmandu;Nepal;NP;27.72;85.32
Amsterdam;Netherlands;NL;52.35;4.92
The Hague;Netherlands;NL;52.08;4.27
Auckland;New Zealand;NZ;-36.85;174.76
Wellington;New Zealand;NZ;-41.3;174.78
Managua;Nicaragua;NI;12.15;-86.27
Niamey;Niger;NE;13.52;2.12
Abuja;Nigeria;NG;9.08;7.53
Benin City;Nigeria;NG;6.34;5.62
Ibadan;Nigeria;NG;7.38;3.93
Kaduna;Nigeria;NG;10.52;7.44
Kano;Nigeria;NG;12;8.52
Lagos;Nigeria;NG;6.44;3.39
Port Harcourt;Nigeria;NG;4.81;7.01
Pyongyang;North Korea;KP;39.02;125.75
Oslo;Norway;NO;59.92;10.75
Muscat;Oman;OM;23.61;58.59
Gujranwala;Pakistan;PK;32.16;74.19
Hyderabad;Pakistan;PK;25.38;68.37
Islamabad;Pakistan;PK;33.7;73.17
Karachi;Pakistan;PK;24.87;66.99
Lahore;Pakistan;PK;31.56;74.35
Multan;Pakistan;PK;30.2;71.46
Peshawar;Pakistan;PK;34.01;71.54
Melekeok;Palau;PW;7.49;134.63
Panama City;Panama;PA;8.97;-79.53
Port Moresby;Papua New Guinea;PG;-9.46;147.19
Asunción;Paraguay;PY;-25.3;-57.64
Lima;Peru;PE;-12.05;-77.05
Baguio City;Philippines;PH;16.43;120.57
Davao;Philippines;PH;7.11;125.63
Manila;Philippines;PH;14.6;120.98
Warsaw;Poland;PL;52.25;21
Lisbon;Portugal;PT;38.72;-9.14
San Juan;Puerto Rico;PR;18.44;-66.13
Doha;Qatar;QA;25.29;51.53
Bucharest;Romania;RO;44.43;26.1
Chelyabinsk;Russia;RU;55.15;61.44
Kazan;Russia;RU;55.75;49.13
Moscow;Russia;RU;55.75;37.62
Nizhny Novgorod;Russia;RU;56.33;44
Novosibirsk;Russia;RU;55.03;82.96
Omsk;Russia;RU;54.99;73.4
Rostov;Russia;RU;47.23;39.71
Samara;Russia;RU;53.2;50.15
St. Petersburg;Russia;RU;59.94;30.32
Ufa;Russia;RU;54.79;56.04
Yekaterinburg;Russia;RU;56.85;60.6
Kigali;Rwanda;RW;-1.95;30.06
Basseterre;Saint Kitts and Nevis;KN;17.3;-62.72
Castries;Saint Lucia;LC;14;-61
Kingstown;Saint Vincent and the Grenadines;VC;13.15;-61.21
Apia;Samoa;WS;-13.84;-171.74
San Marino;San Marino;SM;43.92;12.47
São Tomé;Sao Tome and Principe;ST;0.33;6.73
Jeddah;Saudi Arabia;SA;21.52;39.22
Makkah;Saudi Arabia;SA;21.43;39.82
Medina;Saudi Arabia;SA;24.5;39.58
Riyadh;Saudi Arabia;SA;24.64;46.77
Dakar;Senegal;SN;14.72;-17.47
Belgrade;Serbia;RS;44.82;20.47
Victoria;Seychelles;SC;-4.62;55.45
Freetown;Sierra Leone;SL;8.47;-13.23
Singapore;Singapore;SG;1.29;103.86
Bratislava;Slovakia;SK;48.15;17.12
Ljubljana;Slovenia;SI;46.06;14.51
Honiara;Solomon Islands;SB;-9.44;159.95
Mogadishu;Somalia;SO;2.07;45.37
Hargeysa;Somaliland;;9.56;44.07
Bloemfontein;South Africa;ZA;-29.12;26.23
Cape Town;South Africa;ZA;-33.92;18.43
Durban;South Africa;ZA;-29.87;30.98
Johannesburg;South Africa;ZA;-26.17;28.03
Port Elizabeth;South Africa;ZA;-33.97;25.6
Pretoria;South Africa;ZA;-25.71;28.23
Busan;South Korea;KR;35.1;129.01
Daejeon;South Korea;KR;36.34;127.43
Gwangju;South Korea;KR;35.17;126.91
Incheon;South Korea;KR;37.48;126.64
Seoul;South Korea;KR;37.57;127
Juba;South Sudan;SS;4.83;31.58
Barcelona;Spain;ES;41.38;2.18
Madrid;Spain;ES;40.4;-3.68
Seville;Spain;ES;37.41;-5.98
Colombo;Sri Lanka;LK;6.93;79.86
Sri Jawewardenepura Kotte;Sri Lanka;LK;6.9;79.95
Khartoum;Sudan;SD;15.59;32.53
Omdurman;Sudan;SD;15.62;32.48
Paramaribo;Suriname;SR;5.84;-55.17
Lobamba;Swaziland;SZ;-26.47;31.2
Mbabane;Swaziland;SZ;-26.32;31.13
Stockholm;Sweden;SE;59.35;18.1
Bern;Switzerland;CH;46.92;7.47
Geneva;Switzerland;CH;46.21;6.14
Zürich;Switzerland;CH;47.38;8.55
Aleppo;Syria;SY;36.23;37.17
Damascus;Syria;SY;33.5;36.3
Kaohsiung;Taiwan;TW;22.63;120.27
Taichung;Taiwan;TW;24.15;120.68
Taipei;Taiwan;TW;25.04;121.57
Dushanbe;Tajikistan;TJ;38.56;68.77
Dar es Salaam;Tanzania;TZ;-6.8;39.27
Dodoma;Tanzania;TZ;-6.18;35.75
Bangkok;Thailand;TH;13.75;100.52
Nassau;The Bahamas;BS;25.08;-77.35
Banjul;The Gambia;GM;13.45;-16.59
Lomé;Togo;TG;6.13;1.22
Nukualofa;Tonga;TO;-21.14;-175.22
Port-of-Spain;Trinidad and Tobago;TT;10.65;-61.52
Tunis;Tunisia;TN;36.8;10.18
Adana;Turkey;TR;36.99;35.32
Ankara;Turkey;TR;39.93;32.86
Bursa;Turkey;TR;40.2;29.07
Istanbul;Turkey;TR;41.1;29.01
İzmir;Turkey;TR;38.44;27.15
Ashgabat;Turkmenistan;TM;37.95;58.38
Funafuti;Tuvalu;TV;-8.52;179.22
Kampala;Uganda;UG;0.32;32.58
Dnipro;Ukraine;UA;48.48;35
Kharkiv;Ukraine;UA;50;36.25
Kiev;Ukraine;UA;50.43;30.52
Abu Dhabi;United Arab Emirates;AE;24.47;54.37
Dubai;United Arab Emirates;AE;25.23;55.28
Birmingham;United Kingdom;GB;52.47;-1.92
Glasgow;United Kingdom;GB;55.87;-4.25
London;United Kingdom;GB;51.5;-0.12
Manchester;United Kingdom;GB;53.5;-2.25
Atlanta;United States of America;US;33.83;-84.4
Austin;United States of America;US;30.27;-97.74
Baltimore;United States of America;US;39.3;-76.62
Boston;United States of America;US;42.33;-71.07
Bridgeport;United States of America;US;41.18;-73.2
Buffalo;United States of America;US;42.88;-78.88
Chicago;United States of America;US;41.83;-87.75
Cincinnati;United States of America;US;39.16;-84.46
Cleveland;United States of America;US;41.47;-81.69
Dallas;United States of America;US;32.82;-96.84
Denver;United States of America;US;39.74;-104.98
Detroit;United States of America;US;42.33;-83.08
Ft. Worth;United States of America;US;32.74;-97.34
Houston;United States of America;US;29.82;-95.34
Indianapolis;United States of America;US;39.75;-86.17
Kansas City;United States of America;US;39.11;-94.6
Las Vegas;United States of America;US;36.21;-115.22
Los Angeles;United States of America;US;33.99;-118.18
Memphis;United States of America;US;35.12;-90
Miami;United States of America;US;25.79;-80.22
Milwaukee;United States of America;US;43.05;-87.92
Minneapolis;United States of America;US;44.98;-93.25
New York;United States of America;US;40.75;-73.98
Norfolk;United States of America;US;36.85;-76.28
Orlando;United States of America;US;28.51;-81.38
Philadelphia;United States of America;US;40;-75.17
Phoenix;United States of America;US;33.54;-112.07
Pittsburgh;United States of America;US;40.43;-80
Portland;United States of America;US;45.52;-122.68
Raleigh;United States of America;US;35.82;-78.64
Sacramento;United States of America;US;38.58;-121.47
San Antonio;United States of America;US;29.49;-98.51
San Bernardino;United States of America;US;34.12;-117.3
San Diego;United States of America;US;32.82;-117.18
San Francisco;United States of America;US;37.74;-122.46
San Jose;United States of America;US;37.3;-121.85
Seattle;United States of America;US;47.57;-122.34
St. Louis;United States of America;US;38.64;-90.24
Tampa;United States of America;US;27.95;-82.46
Montevideo;Uruguay;UY;-34.86;-56.17
Tashkent;Uzbekistan;UZ;41.31;69.29
Port Vila;Vanuatu;VU;-17.73;168.32
Vatican City;Vatican (Holy See);VA;41.9;12.45
Caracas;Venezuela;VE;10.5;-66.92
Maracaibo;Venezuela;VE;10.73;-71.66
Valencia;Venezuela;VE;10.23;-67.98
Da Nang;Vietnam;VN;16.06;108.25
Haiphong;Vietnam;VN;20.83;106.68
Hanoi;Vietnam;VN;21.03;105.85
Ho Chi Minh City;Vietnam;VN;10.78;106.7
Bir Lehlou;Western Sahara;EH;26.12;-9.65
Aden;Yemen;YE;12.78;45.01
Sanaa;Yemen;YE;15.35;44.21
Lusaka;Zambia;ZM;-15.42;28.28
Harare;Zimbabwe;ZW;-17.82;31.04''';

/* the parsed list of the world cities, built once at first use */
final List<WorldCity> worldCities = [
  for (final line in worldCityListStr.trim().split('
'))
    if (line.trim().isNotEmpty)
      () {
        final f = line.split(';');
        return WorldCity(f[0], f[1], f[2], double.parse(f[3]), double.parse(f[4]));
      }()
];

/* the IANA time zone of a country: a single name, or longitude
   bands for the multi-zone countries, like WM_TZ of the web */
const worldTz = <String, Object> {
  'AF': 'Asia/Kabul',
  'AL': 'Europe/Tirane',
  'DZ': 'Africa/Algiers',
  'AD': 'Europe/Andorra',
  'AO': 'Africa/Luanda',
  'AG': 'America/Antigua',
  'AR': 'America/Argentina/Buenos_Aires',
  'AM': 'Asia/Yerevan',
  'AU': [
    [-180.0, 'Australia/Perth'],
    [120.0, 'Australia/Adelaide'],
    [142.5, 'Australia/Sydney'],
  ],
  'AT': 'Europe/Vienna',
  'AZ': 'Asia/Baku',
  'BH': 'Asia/Bahrain',
  'BB': 'America/Barbados',
  'BE': 'Europe/Brussels',
  'BZ': 'America/Belize',
  'BJ': 'Africa/Porto-Novo',
  'BM': 'Atlantic/Bermuda',
  'BT': 'Asia/Thimphu',
  'BA': 'Europe/Sarajevo',
  'BW': 'Africa/Gaborone',
  'BO': 'America/La_Paz',
  'BR': [
    [-180.0, 'America/Manaus'],
    [-55.0, 'America/Sao_Paulo'],
  ],
  'BN': 'Asia/Brunei',
  'BG': 'Europe/Sofia',
  'BF': 'Africa/Ouagadougou',
  'BI': 'Africa/Bujumbura',
  'KH': 'Asia/Phnom_Penh',
  'CM': 'Africa/Douala',
  'CA': [
    [-180.0, 'America/Vancouver'],
    [-110.0, 'America/Edmonton'],
    [-90.0, 'America/Toronto'],
  ],
  'CV': 'Atlantic/Cape_Verde',
  'CF': 'Africa/Bangui',
  'TD': 'Africa/Ndjamena',
  'CL': 'America/Santiago',
  'CN': 'Asia/Shanghai',
  'CO': 'America/Bogota',
  'KM': 'Indian/Comoro',
  'CG': 'Africa/Brazzaville',
  'CD': [
    [-180.0, 'Africa/Kinshasa'],
    [22.0, 'Africa/Lubumbashi'],
  ],
  'CR': 'America/Costa_Rica',
  'HR': 'Europe/Zagreb',
  'CU': 'America/Havana',
  'CY': 'Asia/Nicosia',
  'CZ': 'Europe/Prague',
  'DK': 'Europe/Copenhagen',
  'DJ': 'Africa/Djibouti',
  'DM': 'America/Dominica',
  'DO': 'America/Santo_Domingo',
  'TL': 'Asia/Dili',
  'EC': 'America/Guayaquil',
  'EG': 'Africa/Cairo',
  'SV': 'America/El_Salvador',
  'GQ': 'Africa/Malabo',
  'ER': 'Africa/Asmara',
  'EE': 'Europe/Tallinn',
  'ET': 'Africa/Addis_Ababa',
  'FM': 'Pacific/Pohnpei',
  'FJ': 'Pacific/Fiji',
  'FI': 'Europe/Helsinki',
  'FR': 'Europe/Paris',
  'GA': 'Africa/Libreville',
  'DE': 'Europe/Berlin',
  'GH': 'Africa/Accra',
  'GR': 'Europe/Athens',
  'GD': 'America/Grenada',
  'GT': 'America/Guatemala',
  'GN': 'Africa/Conakry',
  'GW': 'Africa/Bissau',
  'GY': 'America/Guyana',
  'HT': 'America/Port-au-Prince',
  'HK': 'Asia/Hong_Kong',
  'HU': 'Europe/Budapest',
  'IS': 'Atlantic/Reykjavik',
  'IN': 'Asia/Kolkata',
  'ID': [
    [-180.0, 'Asia/Jakarta'],
    [118.0, 'Asia/Makassar'],
  ],
  'IR': 'Asia/Tehran',
  'IQ': 'Asia/Baghdad',
  'IE': 'Europe/Dublin',
  'IL': 'Asia/Jerusalem',
  'IT': 'Europe/Rome',
  'CI': 'Africa/Abidjan',
  'JM': 'America/Jamaica',
  'JP': 'Asia/Tokyo',
  'JO': 'Asia/Amman',
  'KZ': 'Asia/Almaty',
  'KE': 'Africa/Nairobi',
  'KW': 'Asia/Kuwait',
  'KG': 'Asia/Bishkek',
  'LA': 'Asia/Vientiane',
  'LV': 'Europe/Riga',
  'LB': 'Asia/Beirut',
  'LS': 'Africa/Maseru',
  'LR': 'Africa/Monrovia',
  'LY': 'Africa/Tripoli',
  'LI': 'Europe/Vaduz',
  'LT': 'Europe/Vilnius',
  'LU': 'Europe/Luxembourg',
  'MK': 'Europe/Skopje',
  'MG': 'Indian/Antananarivo',
  'MW': 'Africa/Blantyre',
  'MY': 'Asia/Kuala_Lumpur',
  'MV': 'Indian/Maldives',
  'ML': 'Africa/Bamako',
  'MT': 'Europe/Malta',
  'MH': 'Pacific/Majuro',
  'MR': 'Africa/Nouakchott',
  'MU': 'Indian/Mauritius',
  'MD': 'Europe/Chisinau',
  'MC': 'Europe/Monaco',
  'ME': 'Europe/Podgorica',
  'MA': 'Africa/Casablanca',
  'MZ': 'Africa/Maputo',
  'MM': 'Asia/Yangon',
  'BD': 'Asia/Dhaka',
  'BY': 'Europe/Minsk',
  'GE': 'Asia/Tbilisi',
  'HN': 'America/Tegucigalpa',
  'KI': 'Pacific/Tarawa',
  'MN': 'Asia/Ulaanbaatar',
  'MX': [
    [-180.0, 'America/Tijuana'],
    [-110.0, 'America/Mexico_City'],
  ],
  'NA': 'Africa/Windhoek',
  'NP': 'Asia/Kathmandu',
  'NL': 'Europe/Amsterdam',
  'NZ': 'Pacific/Auckland',
  'NI': 'America/Managua',
  'NE': 'Africa/Niamey',
  'NG': 'Africa/Lagos',
  'KP': 'Asia/Pyongyang',
  'NO': 'Europe/Oslo',
  'OM': 'Asia/Muscat',
  'PK': 'Asia/Karachi',
  'PW': 'Pacific/Palau',
  'PA': 'America/Panama',
  'PG': 'Pacific/Port_Moresby',
  'PY': 'America/Asuncion',
  'PE': 'America/Lima',
  'PH': 'Asia/Manila',
  'PL': 'Europe/Warsaw',
  'PT': 'Europe/Lisbon',
  'PR': 'America/Puerto_Rico',
  'QA': 'Asia/Qatar',
  'RO': 'Europe/Bucharest',
  'RU': [
    [-180.0, 'Europe/Moscow'],
    [48.0, 'Europe/Samara'],
    [52.0, 'Asia/Yekaterinburg'],
    [68.0, 'Asia/Omsk'],
    [80.0, 'Asia/Novosibirsk'],
  ],
  'RW': 'Africa/Kigali',
  'KN': 'America/St_Kitts',
  'LC': 'America/St_Lucia',
  'VC': 'America/St_Vincent',
  'WS': 'Pacific/Apia',
  'SM': 'Europe/San_Marino',
  'ST': 'Africa/Sao_Tome',
  'SA': 'Asia/Riyadh',
  'SN': 'Africa/Dakar',
  'RS': 'Europe/Belgrade',
  'SC': 'Indian/Mahe',
  'SL': 'Africa/Freetown',
  'SG': 'Asia/Singapore',
  'SK': 'Europe/Bratislava',
  'SI': 'Europe/Ljubljana',
  'SB': 'Pacific/Guadalcanal',
  'SO': 'Africa/Mogadishu',
  'ZA': 'Africa/Johannesburg',
  'KR': 'Asia/Seoul',
  'SS': 'Africa/Juba',
  'ES': 'Europe/Madrid',
  'LK': 'Asia/Colombo',
  'SD': 'Africa/Khartoum',
  'SR': 'America/Paramaribo',
  'SZ': 'Africa/Mbabane',
  'SE': 'Europe/Stockholm',
  'CH': 'Europe/Zurich',
  'SY': 'Asia/Damascus',
  'TW': 'Asia/Taipei',
  'TJ': 'Asia/Dushanbe',
  'TZ': 'Africa/Dar_es_Salaam',
  'TH': 'Asia/Bangkok',
  'BS': 'America/Nassau',
  'GM': 'Africa/Banjul',
  'TG': 'Africa/Lome',
  'TO': 'Pacific/Tongatapu',
  'TT': 'America/Port_of_Spain',
  'TN': 'Africa/Tunis',
  'TR': 'Europe/Istanbul',
  'TM': 'Asia/Ashgabat',
  'TV': 'Pacific/Funafuti',
  'UG': 'Africa/Kampala',
  'UA': 'Europe/Kiev',
  'AE': 'Asia/Dubai',
  'GB': 'Europe/London',
  'US': [
    [-180.0, 'America/Los_Angeles'],
    [-115.0, 'America/Phoenix'],
    [-111.5, 'America/Denver'],
    [-101.0, 'America/Chicago'],
    [-87.0, 'America/New_York'],
  ],
  'UY': 'America/Montevideo',
  'UZ': 'Asia/Tashkent',
  'VU': 'Pacific/Efate',
  'VA': 'Europe/Rome',
  'VE': 'America/Caracas',
  'VN': 'Asia/Ho_Chi_Minh',
  'EH': 'Africa/El_Aaiun',
  'YE': 'Asia/Aden',
  'ZM': 'Africa/Lusaka',
  'ZW': 'Africa/Harare',
};

/* the time zone overrides of a few cities, WM_TZ_CITY of the web */
const worldTzCity = <String, String> {
  'Kazan': 'Europe/Moscow',
  'Pristina': 'Europe/Belgrade',
  'Hargeysa': 'Africa/Mogadishu',
};

/* the time zone borders of Natural Earth, one border per line,
   its points as longitude,latitude pairs separated by spaces */
const String worldTzBordersStr = r'''
-142.465,74.9 -142.44,70.227 -143.541,70.333 -144.814,70.206 -145.75,70.377 -147.176,70.394 -149.119,70.756 -151.196,70.668 -151.596,70.766 -151.669,70.917 -152.022,71.037 -153.183,71.135 -154.023,71.101 -154.444,71.264 -155.682,71.409 -156.313,71.61 -156.858,71.575 -157.526,71.331|-142.465,74.9 -142.53,90.0|-157.526,74.9 -157.526,90.0|180.0,48.0 170.0,53.0 174.929,56.33 180.0,59.502|170.0,53.0 169.387,52.603|-157.942,71.122 -158.266,71.044 -159.667,71.04 -161.285,70.521 -162.041,70.55 -162.762,70.375 -163.585,69.899 -163.75,69.685 -163.776,69.436 -164.066,69.254 -164.499,69.128 -166.59,69.038 -169.0,68.0 -169.0,65.5 -171.06,64.477|-157.942,71.122 -157.527,71.33|-169.698,68.516 -170.89,69.384|-171.714,69.957 -172.508,70.492|-172.509,74.9 -172.509,90.0|-172.483,15.0 -157.518,14.999 -157.517,5.5|-160.64,4.937 -160.64,4.061|-172.5,-1.001 -172.483,15.021|-172.513,48.001 -157.506,48.001 -157.506,29.999 -176.347,30.002 -176.347,27.592 -178.047,27.592 -178.047,30.003 -180.0,29.999|-172.513,48.001 -172.511,45.593|-172.513,48.001 -180.0,48.0|-180.0,34.999 -178.0,34.999|-167.998,-7.998 -168.0,-8.0|-167.998,-7.998 -167.998,-5.842|-168.0,-10.676 -168.0,-13.001|-167.0,-22.001 -163.0,-22.0 -163.0,-25.001 -157.506,-25.001 -157.506,-86.178|-172.539,-78.367 -172.54,-50.0|-172.539,-78.367 -172.538,-90.0|-172.5,-45.0 -172.5,-34.218|-172.5,-33.285 -172.5,-32.291|-172.5,-30.937 -172.5,-28.819|-172.5,-28.0 -172.5,-22.437|-172.5,-26.0 -180.0,-26.001 -177.011,-20.023 -177.011,-15.0|-172.5,-20.313 -172.5,-15.0 -171.237,-14.431 -171.003,-13.968 -171.197,-12.03|-171.261,-11.385 -171.294,-11.057|-170.73,-8.839 -169.396,-5.842|-169.348,53.044 -169.356,52.567 -159.492,54.554 -155.48,55.583 -146.19,59.215 -142.538,59.866 -142.529,-7.001|-169.348,53.044 -169.331,53.999 -174.01,59.999 -174.007,62.288|-142.529,-6.001 -136.998,-6.001 -137.0,-9.992|-142.529,-13.0 -142.5,-13.0|-137.0,-13.001 -133.0,-22.001 -133.0,-27.001 -140.0,-27.001 -140.0,-29.0 -142.529,-29.0 -142.529,-90.0|-133.0,-22.001 -127.51,-22.001 -127.508,49.811 -128.487,50.41 -128.696,50.616 -128.697,50.88 -128.123,51.139 -128.139,51.244 -128.44,51.489 -128.595,51.995 -129.23,52.314 -129.645,52.743 -129.861,52.811 -130.818,53.444 -130.875,53.662 -131.061,53.822 -131.054,54.012 -131.155,54.155 -131.311,54.103 -131.582,53.575 -131.555,53.409 -131.273,53.116 -131.269,52.91 -131.131,52.786 -131.111,52.64 -130.717,52.329 -130.622,52.143 -130.737,51.856 -130.893,51.755 -131.238,51.784 -132.432,52.642 -132.786,52.922 -133.447,53.734 -133.492,53.882 -133.416,54.269 -133.265,54.425 -133.023,54.463 -132.049,54.364 -131.564,54.498 -131.079,54.771 -130.637,54.66 -130.642,54.761 -130.317,54.937 -129.978,55.273 -130.144,55.724 -130.017,55.919 -130.071,56.084 -130.404,56.122 -130.472,56.225 -130.76,56.345 -131.56,56.594 -131.826,56.593 -131.872,56.794 -132.107,56.859 -132.032,57.028 -132.341,57.08 -132.231,57.197 -133.415,58.331 -133.392,58.404 -133.831,58.718 -134.222,58.843 -134.692,59.235 -134.958,59.281 -135.096,59.419 -135.018,59.559 -135.465,59.79 -136.35,59.592 -136.245,59.528 -136.468,59.462 -136.466,59.288 -136.569,59.172 -136.841,59.148 -137.487,58.9 -137.611,59.239 -138.599,59.754 -138.705,59.899 -139.182,60.073 -139.079,60.341 -139.68,60.327 -140.016,60.187 -140.424,60.293 -140.534,60.219 -140.995,60.304 -140.991,69.878 -140.433,69.813 -138.739,69.824 -138.41,69.727 -137.712,69.304 -136.654,69.12 -136.581,69.13 -136.513,69.295 -136.457,68.987|-133.0,-26.001 -127.507,-26.0 -127.507,-90.0|-159.012,-5.842 -158.479,-5.842 -158.487,-2.509|-156.08,-5.842 -154.566,-11.645|-150.497,-11.645 -150.0,-11.645|-150.0,-11.0 -150.0,-10.0 -150.135,-9.548 -155.529,4.937 -156.013,4.937|-172.483,17.551 -172.483,24.999|-179.693,59.686 -179.373,59.877|-178.809,60.211 -177.383,61.042|-175.966,61.848 -174.428,62.7|-180.0,-50.99 -172.969,-45.375|-172.508,70.5 -176.104,72.758 -180.0,75.0|-97.911,80.368 -97.797,80.25 -99.848,80.357 -101.071,80.21 -101.388,80.024 -101.284,79.841 -101.282,79.276 -102.0,79.361 -102.0,73.372 -93.276,72.153 -93.359,71.958 -93.106,71.852 -93.024,71.707 -92.373,71.43 -92.207,71.159 -92.228,70.925 -91.707,70.744 -91.517,70.561 -91.126,70.426 -90.902,70.205 -90.979,70.035 -90.822,69.944 -90.791,69.829 -89.805,69.605 -89.576,69.452 -89.014,69.48 -88.981,66.895 -102.001,66.921 -102.002,60.0 -110.0,60.0 -110.0,53.609 -109.843,53.553 -109.691,53.612 -109.508,53.425 -109.125,53.335 -108.851,53.065 -108.929,52.852 -109.258,52.923 -109.4,52.72 -110.0,52.707 -109.999,48.993 -104.048,48.993 -104.046,47.967 -103.844,47.854 -103.698,47.608 -103.49,47.532 -103.377,47.619 -103.082,47.603 -103.019,47.695 -102.508,47.53 -102.275,47.623 -101.821,47.495 -101.436,47.564 -101.37,47.525 -101.344,47.291 -101.087,47.297 -100.881,47.041 -100.936,46.983 -100.778,46.687 -100.568,46.634 -100.59,46.43 -100.918,46.414 -101.207,46.162 -101.474,46.059 -101.394,45.942 -100.386,45.942 -100.309,45.708 -100.482,45.552 -100.483,45.473 -100.342,45.473 -100.274,45.381 -100.26,45.247 -100.423,44.994 -100.419,44.843 -100.548,44.76 -100.724,44.808 -100.621,44.72 -100.64,44.584 -100.526,44.547 -100.539,44.444 -100.408,44.457 -100.362,44.355 -100.518,44.168 -101.047,44.169 -101.064,43.842 -101.229,43.785 -101.228,43.0 -100.835,43.0 -100.842,41.74 -101.406,41.743 -101.407,41.395 -101.27,41.395 -101.25,41.004 -101.248,40.698 -101.345,40.698 -101.324,40.0 -102.051,40.0 -102.05,39.568 -101.389,39.568 -101.392,39.135 -101.478,39.135 -101.485,38.7 -101.567,38.7 -101.527,37.736 -102.042,37.739 -102.04,37.0 -103.001,37.0 -103.066,32.002 -104.918,32.001 -104.917,30.664 -104.983,30.621 -104.682,30.193 -104.68,29.942 -104.444,29.589 -104.057,29.339 -103.313,29.025 -103.963,27.919 -103.627,26.644 -104.155,26.768 -104.557,26.341 -104.833,26.487 -105.026,26.46 -105.117,26.552 -105.327,26.46 -106.027,26.839 -106.158,26.742 -106.196,26.445 -106.432,26.362 -106.378,26.132 -106.512,26.022 -106.536,25.792 -106.74,25.623 -106.97,25.61 -107.083,25.465 -107.126,25.19 -107.036,24.92 -106.756,24.704 -106.561,24.336 -106.405,24.29 -106.196,24.39 -105.948,24.073 -105.862,24.064 -105.897,23.714 -105.726,23.487 -105.678,23.282 -105.515,23.146 -105.392,23.15 -105.389,23.033 -105.179,23.032 -104.945,22.916 -104.889,22.79 -104.989,22.692 -104.997,22.544 -104.774,22.676 -104.533,22.427 -104.335,22.475 -104.399,22.085 -104.098,21.785 -104.21,21.519 -103.945,21.375 -104.04,21.22 -104.224,21.169 -104.286,20.708 -104.778,21.021 -105.095,20.918 -105.267,20.699 -105.796,20.657 -105.898,20.374 -105.707,19.926 -105.113,19.174 -104.086,18.708 -103.58,18.156 -102.777,17.868 -101.977,17.75 -101.742,17.496 -101.143,17.089 -100.138,16.748 -99.763,16.525 -98.844,16.326 -98.625,16.128 -98.123,15.962 -97.867,15.787 -97.517,15.742 -97.524,-25.0|-97.911,80.368 -97.517,80.509 -97.515,80.636|-99.589,-25.0 -111.0,-25.001 -111.0,-29.001 -101.0,-29.001|-97.526,-29.0 -97.548,-90.0|-112.503,-74.111 -112.501,8.5 -107.0,8.5 -107.0,11.5 -112.501,11.5 -112.501,24.049 -116.905,24.053 -116.898,28.558 -115.117,28.558 -114.219,28.0 -112.168,28.0 -114.714,31.533 -114.934,31.909 -115.04,32.277 -114.926,32.483 -114.809,32.511 -114.721,32.725 -114.536,32.738 -114.461,32.855 -114.502,33.019 -114.697,33.089 -114.727,33.412 -114.533,33.569 -114.516,33.964 -114.119,34.293 -114.369,34.472 -114.617,34.879 -114.639,35.124 -114.572,35.213 -114.741,36.014 -114.707,36.109 -114.555,36.161 -114.159,36.03 -114.043,36.21 -114.042,42.0 -117.017,42.0 -117.018,42.515 -118.215,42.522 -118.232,44.256 -117.972,44.443 -117.591,44.445 -117.486,44.388 -117.486,44.301 -117.202,44.316 -117.204,44.483 -116.864,44.866 -116.455,45.601 -116.543,45.762 -116.789,45.874 -116.628,46.07 -116.3,45.915 -116.294,45.469 -115.801,45.493 -115.503,45.409 -115.188,45.612 -114.736,45.445 -114.533,45.589 -114.55,45.784 -114.389,45.882 -114.503,46.16 -114.433,46.191 -114.325,46.665 -114.761,46.716 -115.333,47.264 -115.724,47.442 -115.639,47.479 -115.733,47.556 -115.676,47.605 -115.719,47.7 -116.049,48.004 -116.048,48.993 -116.842,49.0 -117.002,49.086 -116.949,49.211 -116.666,49.286 -116.912,49.666 -116.861,49.828 -116.669,49.847 -116.491,50.055 -116.473,50.192 -116.663,50.466 -116.61,50.674 -117.097,50.983 -117.401,51.447 -117.496,51.489 -117.669,51.418 -117.966,51.536 -117.96,51.727 -118.174,51.816 -118.192,51.953 -118.614,52.102 -118.662,52.179 -118.525,52.322 -118.211,52.367 -118.259,52.445 -118.207,52.482 -118.348,52.616 -118.306,52.678 -118.421,52.84 -118.624,52.887 -118.672,53.034 -118.777,53.053 -118.757,53.122 -118.963,53.233 -119.029,53.135 -119.263,53.198 -119.393,53.365 -119.742,53.4 -119.931,53.605 -119.737,53.642 -120.048,53.815 -120.197,54.124 -120.536,54.16 -120.827,54.481 -121.422,54.558 -121.577,54.838 -121.856,54.897 -122.588,55.433 -122.755,55.379 -122.945,55.445 -122.993,55.611 -123.278,55.73 -123.468,55.98 -123.581,56.51 -123.79,56.777 -123.76,56.974 -123.326,57.14 -123.004,57.176 -122.576,57.089 -122.358,57.179 -122.011,57.06 -121.836,57.121 -121.71,57.299 -121.309,57.253 -121.053,57.313 -120.946,57.426 -120.5,57.467 -120.381,57.42 -120.335,57.254 -120.155,57.206 -120.0,57.265 -120.0,60.0 -124.026,60.02 -123.981,60.099 -124.196,60.33 -124.216,60.461 -124.416,60.479 -124.62,60.682 -124.479,60.788 -124.599,60.965 -124.806,60.968 -124.892,60.855 -125.364,60.782 -125.901,60.895 -126.014,60.804 -126.144,60.867 -126.288,60.78 -126.852,60.761 -126.936,61.059 -127.1,61.071 -127.007,61.188 -127.146,61.465 -127.807,61.611 -128.547,62.122 -128.779,62.057 -129.288,62.153 -129.202,62.211 -129.309,62.321 -129.216,62.378 -129.305,62.423 -129.172,62.479 -129.552,62.566 -129.517,62.673 -129.773,62.869 -129.614,63.072 -129.845,63.091 -129.905,63.197 -130.15,63.268 -129.823,63.478 -130.095,63.698 -130.318,63.703 -130.114,63.804 -130.863,64.042 -130.942,64.129 -130.873,64.191 -131.06,64.28 -131.003,64.325 -131.146,64.424 -131.384,64.468 -131.599,64.369 -131.819,64.378 -131.682,64.521 -132.054,64.696 -132.615,64.816 -132.481,64.88 -132.507,64.965 -132.334,65.031 -132.781,65.226 -132.554,65.284 -132.173,65.595 -132.569,65.844 -132.341,65.979 -132.625,66.029 -132.935,65.907 -132.994,65.923 -132.907,66.003 -132.955,66.03 -133.612,65.962 -133.608,66.05 -133.705,66.072 -133.567,66.154 -133.564,66.261 -133.819,66.31 -133.76,66.437 -133.629,66.445 -133.692,66.52 -133.592,66.569 -133.834,66.726 -133.77,66.809 -134.091,66.964 -133.831,67.003 -136.167,67.006 -136.237,67.178 -136.095,67.297 -136.201,67.408 -136.157,67.504 -136.445,67.726 -136.445,68.906|-112.503,-74.111 -112.503,-90.0|-136.513,69.295 -136.142,69.497 -136.192,69.596 -136.135,69.694 -135.813,69.826 -135.041,69.826 -134.332,69.936 -133.405,69.79 -132.136,69.996 -130.839,70.358 -129.785,70.476 -129.322,70.443 -128.842,70.253 -128.75,70.291 -128.969,70.535 -128.761,70.776 -128.214,70.868 -127.724,70.802|-127.514,70.734 -126.622,70.37 -126.199,70.049 -126.141,69.865 -125.967,69.78 -125.893,69.805 -125.708,70.209 -125.444,70.335 -124.912,70.38 -124.021,70.317 -123.726,70.987 -124.214,71.362 -124.524,71.539 -125.43,71.732 -126.433,71.815 -126.672,71.981 -126.316,72.317 -125.805,72.635 -125.718,72.732 -125.823,72.841 -125.796,72.927 -124.777,73.723 -125.525,74.288 -125.465,74.434 -124.964,74.548 -121.565,74.765 -121.393,75.533 -123.166,75.785 -123.897,76.062 -123.784,76.233 -123.404,76.437 -122.871,76.581 -122.237,76.635 -121.902,76.815 -121.341,76.905 -120.133,77.383 -119.618,77.507 -117.896,77.599 -116.853,77.755 -115.551,77.687 -116.112,77.971 -115.745,78.124 -114.418,78.326 -113.989,78.543 -112.505,78.746 -112.505,90.0|-97.515,90.0 -97.515,84.9|-82.504,83.653 -82.509,82.991 -84.027,82.67 -84.999,82.686 -84.999,66.257 -86.116,65.842 -88.995,62.523 -88.947,56.853 -90.017,56.192 -90.0,54.018 -89.013,54.03 -88.501,53.673 -88.501,53.364 -89.013,53.007 -89.013,52.781 -90.024,52.769 -89.988,52.008 -90.5,51.794 -90.786,51.508 -90.774,51.294 -90.512,51.02 -90.0,50.771 -90.0,49.545 -91.012,49.248 -91.0,48.51 -89.988,48.284 -90.035,48.061 -89.92,47.988 -89.499,47.995 -89.966,47.274 -89.864,46.593 -89.74,46.592 -89.741,46.505 -89.365,46.506 -89.365,46.333 -88.991,46.333 -88.991,46.42 -88.117,46.42 -88.117,46.247 -87.616,46.247 -87.617,45.986 -87.368,45.985 -87.326,45.899 -87.327,45.551 -87.115,45.451 -86.774,45.451 -86.264,45.226 -86.715,44.845 -87.142,43.657 -87.039,42.492 -87.221,41.76 -86.524,41.76 -86.5,41.521 -86.525,41.433 -86.93,41.245 -86.931,40.913 -87.1,40.838 -87.099,40.737 -87.526,40.737 -87.533,39.362 -87.615,39.32 -87.667,39.118 -87.536,38.958 -87.511,38.763 -87.653,38.497 -87.762,38.454 -87.1,38.534 -87.073,38.204 -86.791,38.205 -86.773,37.924 -86.624,37.854 -86.498,38.05 -86.152,37.799 -86.275,37.594 -86.113,37.566 -86.047,37.45 -85.584,37.467 -85.353,37.192 -85.165,37.311 -84.845,36.991 -84.678,36.98 -84.578,36.867 -84.785,36.603 -84.659,36.395 -84.914,36.208 -84.681,35.909 -85.108,35.571 -85.362,35.088 -85.474,34.983 -85.606,34.985 -85.201,32.935 -84.968,32.434 -84.992,32.337 -84.898,32.269 -85.031,32.17 -85.144,31.824 -85.042,31.535 -85.101,31.183 -84.858,30.697 -85.166,30.112 -85.145,30.018 -85.021,29.98 -85.031,29.799 -85.216,29.698 -85.22,29.437 -84.804,29.445 -84.257,29.707 -84.078,29.873 -83.836,29.746 -83.231,28.988 -82.961,28.898 -82.893,28.575 -83.085,27.953 -83.07,27.767 -82.504,26.687 -82.503,23.336 -82.698,23.247 -83.28,23.2 -84.131,22.914 -84.587,22.538 -84.701,22.197 -85.111,22.043 -85.172,21.847 -84.985,21.633 -84.695,21.641 -84.508,21.558 -83.936,21.728 -83.795,21.849 -83.665,21.761 -83.397,21.755 -83.395,21.512 -83.108,21.264 -82.884,21.235 -82.503,21.358 -82.503,18.534|-82.504,83.653 -82.51,90.0|-82.503,17.815 -82.502,15.394 -82.247,15.099 -82.349,14.91 -82.502,14.882 -82.359,14.586 -82.415,14.428 -82.357,14.218 -82.502,14.047 -82.502,9.642 -82.619,9.487 -82.829,9.603 -82.846,9.493 -82.942,9.456 -82.939,9.06 -82.719,8.922 -82.923,8.756 -82.848,8.465 -83.053,8.315 -82.886,8.102 -82.981,7.853 -82.738,7.888 -82.613,8.097 -82.502,7.948 -82.492,-90.0|-67.503,84.9 -67.503,83.187 -62.39,82.985 -61.841,82.878 -61.744,82.814 -61.761,82.731 -59.983,82.554 -59.634,82.433 -59.538,82.303 -62.167,81.867 -64.183,81.301 -66.267,80.835 -67.117,80.75 -68.333,80.417|-67.503,84.9 -67.503,90.0|-59.538,82.303 -54.902,82.568 -52.558,82.588 -52.543,90.0|-68.71,80.18 -69.331,79.651 -72.999,78.802 -73.766,78.417 -74.065,78.139 -72.976,77.798 -72.265,77.684 -73.35,77.544 -73.524,77.441 -73.357,77.288 -72.432,77.102 -72.066,76.861 -70.927,76.6 -70.866,76.488 -70.339,76.249 -68.941,75.911 -67.502,75.794 -67.502,70.449 -66.659,70.032 -66.513,69.734 -66.658,69.585 -66.282,69.45 -66.059,69.259 -66.119,69.103 -66.369,68.973 -67.207,68.92 -67.069,68.699 -66.319,68.609 -65.372,68.237 -64.883,68.263 -64.393,68.165 -64.136,67.97 -63.555,67.8 -63.197,67.551 -62.179,67.378 -61.353,67.093 -60.741,66.658 -60.999,66.271 -61.478,66.131 -61.46,65.956 -61.724,65.821 -61.614,65.679 -61.775,65.494 -62.033,65.411 -62.792,65.373 -62.89,65.01 -63.23,64.733 -63.679,64.694 -64.452,64.881 -64.625,64.555 -64.605,64.38 -64.711,64.287 -64.249,64.139 -63.592,63.286 -63.659,63.166 -63.849,63.087 -64.292,63.072 -64.136,62.751 -63.912,62.542 -63.958,62.397 -64.373,62.188 -64.698,62.166 -64.669,62.046 -64.209,61.594 -64.284,61.388 -64.653,61.146 -64.642,60.9 -64.263,60.819 -64.167,60.666 -64.533,60.303 -64.845,60.264 -64.603,60.11 -64.904,60.048 -64.654,59.917 -64.814,59.819 -64.774,59.699 -64.885,59.664 -64.893,59.565 -64.702,59.447 -64.349,59.505 -64.503,59.43 -64.534,59.195 -64.292,59.007 -64.754,59.065 -64.876,58.925 -64.31,58.885 -64.157,58.751 -63.726,58.879 -63.484,58.759 -64.059,58.669 -64.078,58.552 -63.89,58.567 -63.82,58.474 -64.156,58.348 -64.429,58.097 -64.221,58.045 -64.054,57.768 -63.939,57.801 -63.696,57.659 -63.584,57.708 -63.765,57.564 -63.708,57.385 -63.869,57.25 -63.85,57.192 -63.82,57.275 -63.743,57.227 -63.876,57.059 -63.871,56.878 -63.997,56.855 -64.126,56.709 -63.877,56.439 -64.17,56.426 -64.091,56.263 -63.877,56.217 -64.011,56.156 -64.01,56.07 -63.862,56.123 -63.804,56.043 -63.445,56.023 -63.84,55.913 -63.696,55.777 -63.749,55.655 -63.669,55.624 -63.767,55.462 -63.33,55.389 -63.66,55.27 -63.41,55.252 -63.589,55.121 -63.605,54.902 -63.815,54.941 -63.904,54.782 -63.74,54.624 -64.052,54.607 -64.392,54.789 -64.768,54.738 -64.782,54.835 -65.103,54.957 -65.296,54.826 -65.473,54.842 -65.48,54.731 -65.681,54.715 -65.856,54.908 -66.254,54.998 -66.804,55.339 -66.689,55.202 -66.762,55.104 -66.661,54.984 -66.729,54.939 -66.607,54.804 -66.785,54.746 -67.297,55.006 -67.274,55.066 -67.435,55.064 -67.086,54.681 -67.261,54.571 -67.268,54.485 -67.498,54.595 -67.509,54.488 -67.75,54.426 -67.639,54.189 -67.808,54.034 -67.523,53.838 -67.595,53.783 -67.323,53.566 -66.89,53.415 -67.01,53.353 -66.996,53.081 -67.241,53.167 -67.385,53.105 -67.302,52.868 -67.165,52.82 -67.062,52.875 -67.041,52.775 -66.866,52.662 -66.852,52.731 -66.769,52.679 -66.769,52.765 -66.656,52.796 -66.625,52.937 -66.363,53.002 -66.288,52.847 -66.401,52.844 -66.288,52.61 -66.405,52.648 -66.35,52.359 -66.48,52.335 -66.35,52.132 -66.264,52.156 -66.284,52.308 -65.992,52.06 -65.655,52.108 -65.662,51.988 -65.5,52.098 -65.376,51.984 -65.339,51.819 -65.277,51.867 -64.957,51.723 -64.771,51.764 -64.53,51.592 -64.279,51.74 -64.362,51.967 -64.235,51.981 -64.252,52.115 -64.155,52.132 -64.221,52.266 -64.128,52.387 -64.166,52.676 -63.612,52.861 -63.596,52.771 -63.379,52.651 -63.876,52.608 -64.081,52.473 -63.973,52.354 -63.749,52.322 -63.64,52.051 -63.82,52.068 -63.774,52.014 -62.131,52.0 -61.834,51.624 -61.777,51.371 -61.666,51.311 -61.706,51.241 -61.524,51.075 -61.715,50.891 -61.616,50.731 -61.681,50.425 -61.585,50.315 -61.628,50.268 -61.56,50.233 -61.271,49.347 -60.914,48.0 -61.419,46.966 -62.277,46.922 -63.044,48.505 -64.601,48.275 -64.734,48.131 -65.266,47.925 -66.373,48.087 -67.357,47.842 -67.612,47.998 -68.116,48.002 -68.12,47.927 -68.373,47.925 -68.38,47.559 -68.576,47.425 -69.064,47.294 -68.89,47.191 -68.246,47.361 -67.814,47.082 -67.758,45.92 -67.807,45.713 -67.431,45.598 -67.471,45.266 -67.319,45.154 -67.154,45.173 -66.875,44.807 -67.05,44.557 -67.043,44.362 -67.279,44.187 -67.504,43.558 -67.504,20.241 -71.756,20.241 -71.692,19.486 -71.767,19.332 -71.635,19.158 -71.856,18.948 -71.719,18.884 -71.716,18.75 -71.832,18.623 -72.003,18.601 -71.907,18.438 -71.695,18.322 -71.769,18.202 -71.772,12.657 -71.425,12.638 -71.134,12.51 -70.93,12.193 -70.903,12.014 -71.104,11.785 -71.358,11.851 -71.971,11.662 -72.267,11.155 -72.438,11.137|-70.961,12.255 -70.141,12.365 -69.74,12.262 -68.955,11.759 -68.601,11.666 -67.99,11.666 -67.99,12.1 -67.734,12.275 -66.056,12.077 -64.561,12.106 -62.245,11.572 -61.73,11.175 -61.804,10.588 -61.863,10.588 -62.083,10.046 -61.109,9.866 -61.114,9.798 -60.827,9.7 -60.563,9.351 -60.667,8.818 -60.11,8.816 -59.816,8.288 -59.993,8.169 -60.03,8.043 -60.375,7.824 -60.526,7.813 -60.716,7.552 -60.602,7.33 -60.628,7.191 -60.548,7.126 -60.372,7.172 -60.296,7.071 -60.377,6.939 -60.7,6.767 -60.908,6.815 -60.934,6.732 -61.13,6.716 -61.212,6.561 -61.122,6.187 -61.397,5.946 -60.664,5.17 -60.613,4.901 -60.896,4.709 -60.977,4.535 -61.316,4.521 -61.293,4.448 -61.502,4.402 -61.567,4.249 -62.154,4.09 -62.428,4.183 -62.561,4.038 -62.744,4.034 -62.75,3.66 -62.889,3.561 -63.352,3.959 -63.511,3.855 -63.672,3.946 -64.038,3.883 -64.147,4.111 -64.59,4.119 -64.792,4.284 -64.813,4.211 -64.643,3.973 -64.203,3.595 -64.223,3.124 -63.998,2.715 -64.048,2.471 -63.365,2.413 -63.402,2.171 -63.783,1.975 -63.995,1.958 -64.093,1.623 -64.353,1.366 -64.409,1.508 -64.731,1.248 -64.839,1.271 -65.137,1.127 -65.203,0.924 -65.327,0.91 -65.498,0.659 -65.585,0.692 -65.518,0.887 -65.608,0.985 -66.134,0.731 -66.346,0.759 -66.88,1.233 -67.217,2.266 -67.19,2.394 -67.576,2.691 -67.627,2.813 -67.856,2.79 -67.839,2.886 -67.309,3.384 -67.5,3.718 -67.632,3.762 -67.875,4.533 -67.793,5.063 -67.835,5.339 -67.617,5.542 -67.625,5.785 -67.422,5.978 -67.491,6.115 -67.45,6.198 -67.827,6.313 -67.978,6.218 -68.635,6.136 -69.061,6.218 -69.246,6.081 -69.331,6.156 -69.444,6.122 -70.129,6.973 -70.319,6.938 -70.703,7.1 -71.184,6.963 -71.654,7.053 -71.881,6.987 -72.081,7.067 -72.206,7.382 -72.479,7.485 -72.491,7.938 -72.336,8.104 -72.393,8.355 -72.675,8.652 -72.791,9.114 -72.955,9.104 -73.01,9.295 -73.212,9.173 -73.391,9.173 -72.985,9.812 -72.915,10.433 -72.594,10.933|-72.439,11.137 -72.576,10.958|-66.864,1.213 -67.086,1.176 -67.117,1.71 -67.425,2.138 -67.929,1.741 -68.192,2.015 -68.28,1.829 -68.163,1.721 -69.542,1.773 -69.856,1.708 -69.852,1.059 -69.289,1.038 -69.152,0.868 -69.137,0.65 -69.297,0.618 -69.478,0.733 -70.054,0.588 -70.068,-0.16 -69.62,-0.525 -69.628,-0.733 -69.399,-1.183 -69.972,-4.291 -70.037,-4.341 -70.139,-4.26 -70.206,-4.343 -70.331,-4.143 -70.585,-4.194 -70.647,-4.116 -70.832,-4.179 -70.969,-4.385 -71.265,-4.375 -71.363,-4.459 -71.907,-4.518 -72.386,-4.794 -72.645,-5.061 -72.918,-5.132 -72.977,-5.652 -73.235,-6.078 -73.148,-6.476 -73.759,-6.887 -73.812,-7.103 -73.713,-7.305 -73.983,-7.356 -73.944,-7.449 -74.018,-7.543 -73.712,-7.788 -73.785,-7.94 -73.668,-8.014 -73.541,-8.359 -73.356,-8.48 -73.351,-8.598 -72.976,-8.985 -72.972,-9.134 -73.215,-9.409 -72.813,-9.411 -72.313,-9.532 -72.163,-9.877 -72.196,-10.006 -71.3,-9.993 -70.525,-9.431 -70.624,-9.566 -70.542,-9.708 -70.638,-9.852 -70.641,-11.011 -70.534,-10.938 -70.289,-11.065 -69.956,-10.919 -69.578,-10.952 -68.684,-12.502 -68.793,-12.62 -68.766,-12.71 -68.981,-12.868 -68.971,-13.501 -69.102,-13.667 -68.864,-14.191 -69.01,-14.246 -68.99,-14.379 -69.235,-14.574 -69.268,-14.751 -69.37,-14.801 -69.384,-14.982 -69.148,-15.233 -69.43,-15.626 -69.185,-16.195 -68.982,-16.21 -68.833,-16.329 -69.028,-16.454 -69.037,-16.67 -69.182,-16.729 -69.427,-17.087 -69.623,-17.186 -69.666,-17.288 -69.523,-17.369 -69.51,-17.507 -69.85,-17.692 -69.78,-17.963 -69.865,-18.145 -69.988,-18.264 -70.623,-18.451 -70.352,-19.985 -70.427,-20.731 -70.301,-21.438 -70.528,-22.738 -70.705,-22.913 -70.819,-23.179 -70.83,-23.44 -70.713,-23.746 -70.806,-24.705 -81.493,-24.705 -81.493,-37.419 -73.931,-37.419 -73.948,-37.703 -73.726,-38.119 -73.936,-38.112 -74.191,-38.263 -74.222,-38.377 -74.095,-38.56 -73.744,-38.695 -73.519,-39.414 -73.699,-39.703 -73.968,-39.911 -74.262,-41.009 -74.13,-41.55 -74.297,-41.707 -74.335,-42.006 -74.444,-42.175 -74.481,-42.788 -74.687,-43.306 -75.016,-43.384 -75.112,-43.504 -75.992,-46.616 -75.954,-49.271 -75.866,-49.39 -75.907,-49.78 -75.707,-50.097 -75.811,-50.719 -75.593,-50.943 -75.294,-51.028 -75.536,-51.279 -75.63,-51.64 -75.448,-51.813 -75.241,-52.274 -74.915,-52.465 -74.886,-52.572 -75.005,-52.654 -75.04,-52.85 -74.594,-53.209 -74.5,-53.435 -74.249,-53.538 -73.793,-53.901 -73.647,-54.238 -72.925,-54.324 -72.761,-54.53 -72.464,-54.634 -72.283,-54.855 -71.811,-54.938 -71.591,-55.104 -69.545,-55.675 -68.631,-55.674 -67.986,-56.041 -67.493,-56.082 -67.493,-66.503|-68.311,-66.503 -68.854,-66.725 -69.644,-67.368 -69.733,-67.554 -69.631,-67.698 -69.155,-67.949 -68.14,-67.917 -67.838,-67.98 -67.699,-68.399 -67.737,-68.626|-68.311,-66.503 -68.144,-66.503|-55.299,50.603 -55.545,50.511 -55.852,50.56 -56.016,50.345 -55.696,50.169 -55.198,50.048 -55.174,49.915 -55.27,49.738 -54.158,49.938 -53.9,49.889 -53.755,49.769 -53.692,49.587 -53.295,49.414 -53.184,49.287 -53.453,48.858 -52.863,48.831 -52.755,48.732 -52.695,48.578 -52.778,48.338 -52.622,48.219 -52.573,48.068 -52.628,47.964 -52.437,47.819 -52.347,47.492 -52.558,47.145 -52.668,46.748 -52.862,46.544 -53.087,46.442 -53.553,46.428 -54.356,46.672 -54.477,46.869 -54.405,47.202 -54.726,47.163 -54.892,46.927 -55.238,46.701 -55.91,46.662 -56.1,46.86 -56.105,47.1 -56.442,47.414 -56.875,47.339 -58.1,47.48 -59.137,47.367 -59.433,47.432 -59.58,47.559 -59.68,47.965 -59.378,48.232 -59.527,48.402 -59.523,48.563 -59.363,48.724 -58.814,48.986 -57.903,50.231 -57.673,50.781 -57.317,51.161 -57.102,51.25 -57.081,52.714 -57.504,53.061 -57.504,53.389 -56.748,53.966 -56.46,53.993 -55.811,53.738 -55.423,53.308 -55.51,52.992 -55.298,52.274 -54.977,51.953 -55.178,51.716 -55.108,51.573 -55.187,51.372 -55.383,51.157 -55.25,51.034 -55.186,50.723 -55.299,50.603|-52.536,47.906 -52.535,64.261 -52.716,64.972 -52.997,65.11 -53.079,65.328 -53.608,65.45 -53.78,65.785 -54.163,66.078 -54.22,66.359 -54.122,66.587 -53.941,66.728 -54.292,66.868 -54.51,67.109 -54.283,67.53 -54.245,67.851 -53.927,68.019 -54.024,68.15 -53.947,68.379 -53.506,68.768 -53.514,69.025 -54.569,69.187 -55.561,69.627 -55.598,69.718 -55.434,70.027 -55.44,70.244 -55.63,70.39 -55.638,70.54 -55.056,70.86 -54.545,71.01 -54.665,71.138 -55.879,71.261 -56.548,71.625 -56.47,71.928 -56.253,72.062 -56.37,72.18 -56.308,72.369 -56.356,72.456 -56.799,72.573 -56.932,72.719 -56.796,72.835 -56.404,72.942 -56.429,73.115 -56.266,73.243 -56.795,73.475 -56.85,73.614 -57.231,73.689 -57.549,73.895 -58.048,74.045 -58.021,74.288 -58.343,74.502 -57.934,74.686 -57.993,74.801 -58.861,74.955 -59.007,75.13 -59.49,75.291 -59.49,75.523 -60.333,75.644 -60.665,75.787 -62.273,76.015 -63.606,75.953 -66.649,79.354 -66.054,79.567 -66.214,79.769 -67.879,79.912 -68.695,80.162|-52.536,47.175 -52.537,5.365 -52.807,5.635 -53.37,5.767 -53.753,5.964 -54.717,6.19 -55.853,6.172 -56.089,6.062 -56.962,6.217 -57.064,6.063|-55.91,46.662 -56.151,46.554 -56.152,46.306 -56.405,46.306 -56.405,46.368 -56.899,46.609 -57.098,46.984 -56.495,47.366 -56.378,47.336|-55.91,46.662 -55.983,46.802|-7.512,84.9 -7.512,71.32 -7.298,71.172 -7.512,70.904 -7.513,66.761 -18.13,66.768 -18.489,66.646 -18.529,66.513 -18.373,66.388 -18.984,66.408 -19.679,66.259 -20.289,66.336 -20.925,66.14 -22.071,66.617 -22.527,66.674 -22.514,69.639 -21.887,69.845 -21.475,70.095 -21.506,70.226 -21.723,70.209|-7.512,84.9 -7.512,90.0|-22.527,66.674 -23.449,66.601 -23.715,66.394 -24.245,66.173 -24.339,65.996 -25.034,65.554 -24.97,65.397 -24.611,65.284|-22.514,69.639 -24.045,69.203 -25.224,68.726 -26.138,68.476 -30.3,67.861 -31.499,67.866 -31.772,67.694 -32.254,67.635 -32.667,67.479 -32.79,67.175 -33.287,66.874 -33.374,66.704 -34.305,66.213 -35.448,65.907 -36.031,65.653 -36.39,65.607 -36.707,65.377 -37.531,65.368 -37.544,65.17|-24.568,70.577 -24.392,72.515 -22.32,71.967|-21.519,72.337 -21.182,72.689 -21.243,72.811 -21.179,72.896 -20.636,72.992 -20.471,73.097 -20.472,73.212 -19.732,73.416 -19.66,73.527 -19.737,73.655 -19.538,73.792 -19.585,73.945 -19.472,74.038 -18.747,74.151 -18.248,74.412 -17.622,74.55 -17.521,74.728 -17.052,74.789 -16.57,74.995 -16.539,75.182 -17.326,75.524 -17.9,75.622 -18.604,75.621 -18.026,75.751|-18.02,75.753 -17.718,75.931 -17.836,76.514 -17.358,76.926 -17.373,77.197 -17.799,77.412 -17.005,77.549 -16.665,77.788 -16.723,77.897 -16.945,78.007 -17.856,78.122 -17.927,78.293 -17.298,78.53 -16.978,78.727 -16.976,78.838 -16.484,78.961 -16.332,79.112 -16.423,79.214 -16.846,79.339 -18.051,79.38 -18.209,79.459 -17.5,79.531|-17.368,79.55 -16.826,79.651 -16.094,80.026 -15.51,80.095 -14.669,80.329 -14.543,80.405 -14.587,80.499 -13.294,80.662 -12.878,80.83 -10.453,81.293 -10.012,81.481 -11.032,81.78 -13.233,81.989 -16.02,82.031 -17.169,81.927 -17.985,82.192 -18.607,82.289 -20.846,82.271 -19.986,82.474 -19.749,82.607 -19.938,82.719 -20.469,82.812 -22.507,83.024|-22.529,83.027 -22.529,90.0|-57.072,6.052 -57.328,5.308|-57.31,5.313 -57.299,5.311|-57.297,5.311 -57.273,5.223|-57.252,5.272 -57.234,5.144|-57.278,5.177 -57.295,5.021|-57.318,5.026 -57.491,4.992|-57.523,5.012 -57.613,4.992|-57.654,5.008 -57.801,4.924|-57.833,4.932 -57.931,4.796 -57.843,4.651 -58.073,4.151 -57.835,3.662 -57.649,3.517 -57.664,3.395 -57.556,3.347|-57.536,3.367 -57.478,3.341|-57.425,3.385 -57.369,3.366|-57.312,3.392 -57.268,3.133|-57.243,3.145 -57.214,3.024|-57.223,3.025 -57.177,2.82|-57.138,2.832 -57.138,2.774|-57.104,2.778 -57.05,2.638|-57.031,2.646 -56.995,2.506|-56.963,2.522 -56.711,2.03 -56.491,1.953 -56.576,1.906|-56.641,1.937 -56.69,1.913|-56.727,1.916 -56.799,1.874|-56.944,1.918 -56.982,1.915|-57.109,2.02 -57.243,1.95|-57.321,1.977 -57.64,1.697|-57.76,1.714 -57.928,1.643|-57.986,1.657 -58.074,1.509|-58.192,1.567 -58.225,1.556|-58.323,1.6 -58.52,1.439 -58.528,1.267|-58.561,1.286 -58.586,1.273|-58.686,1.282 -58.836,1.186|-58.972,1.31 -58.866,-0.322 -58.736,-0.447 -58.744,-0.652 -58.608,-0.772|-58.574,-0.765 -58.289,-1.13|-58.269,-1.129 -58.152,-1.237|-58.136,-1.237 -57.673,-1.584 -57.33,-1.729|-57.267,-1.714 -57.234,-1.768|-57.199,-1.764 -56.813,-2.037|-56.771,-2.032 -56.762,-2.167 -56.638,-2.222|-56.506,-2.162 -56.401,-2.271|-56.318,-2.237 -56.404,-2.304 -58.3,-6.497 -58.477,-6.723 -57.649,-8.215 -57.686,-8.446 -57.597,-8.745 -57.098,-9.058 -57.002,-9.245|-56.968,-9.239 -56.843,-9.273 -56.771,-9.398|-56.693,-9.376 -56.472,-9.474|-56.462,-9.467 -50.262,-9.844 -50.604,-10.657 -50.617,-11.061 -50.747,-11.471 -50.656,-11.6 -50.718,-11.739 -50.65,-11.89 -50.658,-12.605|-50.669,-12.6 -50.596,-12.807|-50.576,-12.803 -50.53,-12.841|-50.503,-12.84 -50.58,-13.247 -50.872,-13.716 -50.902,-14.118|-50.919,-14.116 -51.106,-14.888 -51.277,-15.018|-51.323,-14.959 -51.654,-15.19 -51.766,-15.537|-51.787,-15.528 -51.917,-15.812|-51.957,-15.799 -52.247,-15.905 -52.675,-16.291 -52.638,-16.529 -53.025,-16.868 -53.043,-17.038 -53.204,-17.266 -53.247,-17.622 -53.059,-18.017 -53.06,-18.314 -52.991,-18.387|-52.91,-18.346 -52.774,-18.412 -52.902,-18.665 -52.76,-18.71|-52.695,-18.71 -52.619,-18.722|-52.499,-18.705 -52.325,-18.816|-52.273,-18.813 -51.586,-19.138|-51.546,-19.136 -51.177,-19.287|-51.151,-19.284 -50.943,-19.549 -51.032,-19.725 -50.999,-20.102 -51.092,-20.263 -51.332,-20.362 -51.585,-20.596 -51.637,-20.877 -51.877,-21.144 -51.873,-21.343 -52.003,-21.485|-52.054,-21.478 -52.112,-21.55 -52.049,-21.666 -52.309,-21.925 -52.375,-22.099 -52.942,-22.461|-52.964,-22.457 -53.173,-22.702 -53.59,-22.902 -53.731,-23.296 -53.974,-23.444 -54.083,-23.949 -54.33,-24.118 -54.268,-24.358 -54.468,-25.037 -54.432,-25.149 -54.615,-25.433 -54.604,-25.654|-54.634,-25.652 -54.644,-26.197 -54.82,-26.664|-54.84,-26.654 -55.166,-26.957|-55.281,-26.934 -55.419,-26.98 -55.489,-27.1|-55.517,-27.098 -55.604,-27.167 -55.597,-27.328 -55.758,-27.442|-55.918,-27.328 -55.986,-27.332|-56.125,-27.299 -56.285,-27.39 -56.402,-27.586|-56.615,-27.447 -56.773,-27.506|-56.909,-27.419 -57.113,-27.49|-57.366,-27.403 -57.491,-27.416|-58.054,-27.259 -58.13,-27.269|-58.241,-27.257 -58.604,-27.312|-58.539,-27.038 -58.517,-27.059|-58.326,-26.805 -58.293,-26.811|-58.272,-26.764 -58.264,-26.764|-58.236,-26.65 -58.197,-26.657|-58.151,-26.183 -58.126,-26.198|-57.711,-25.653 -57.701,-25.653|-57.668,-25.613 -57.64,-25.616|-58.013,-25.043 -58.035,-25.045|-58.116,-25.013 -58.124,-25.013|-58.229,-24.941 -58.325,-24.995|-60.056,-24.003 -60.219,-24.027|-60.3,-24.017 -60.329,-24.018|-60.392,-23.987 -60.424,-23.988|-60.647,-23.891 -60.691,-23.893|-60.734,-23.872 -60.818,-23.874|-60.94,-23.815 -60.976,-23.823|-61.191,-23.556 -61.21,-23.557|-61.625,-23.283 -61.667,-23.283|-62.201,-22.627 -62.204,-22.627|-62.273,-22.513 -62.277,-22.513|-62.626,-22.255 -62.625,-22.255|-62.866,-21.993 -63.016,-22.001|-63.64,-21.997 -63.744,-22.049|-63.908,-21.997 -64.256,-22.541 -64.332,-22.863|-64.691,-22.173 -64.725,-22.183|-65.026,-22.097 -65.458,-22.101|-65.583,-22.087 -65.746,-22.114|-66.225,-21.788 -66.313,-22.076|-66.319,-22.076 -66.644,-22.212|-66.7,-22.201 -66.791,-22.428 -66.997,-22.525|-67.019,-22.524 -67.199,-22.822 -67.019,-23.001 -67.345,-24.001 -68.25,-24.385 -68.346,-24.499|-68.381,-24.492 -68.456,-24.627|-68.486,-24.6 -68.583,-24.809 -68.373,-25.103 -68.425,-25.149|-68.463,-25.145 -68.615,-25.474 -68.414,-26.144 -68.581,-26.303 -68.601,-26.457 -68.311,-26.898 -68.341,-27.045|-68.369,-27.044 -68.612,-27.165|-68.765,-27.105 -69.023,-27.46 -69.178,-27.924 -69.425,-28.211|-69.478,-28.189 -69.658,-28.398 -69.759,-28.673 -69.809,-29.099 -70.046,-29.297 -69.921,-29.806 -69.96,-30.092|-69.923,-30.088 -69.854,-30.199 -70.033,-30.396|-70.15,-30.355 -70.325,-30.801 -70.282,-31.039|-70.322,-31.034 -70.424,-31.153|-70.47,-31.091 -70.595,-31.568 -70.395,-31.877|-70.362,-31.877 -70.25,-31.942 -70.311,-32.047|-70.374,-32.031 -70.327,-32.28 -70.166,-32.485 -70.161,-32.738 -70.006,-32.877 -70.117,-33.038 -70.01,-33.298|-69.909,-33.239 -69.792,-33.399 -69.884,-33.558 -69.903,-33.958|-69.886,-33.955 -69.834,-34.233 -69.915,-34.283|-69.99,-34.269 -70.322,-34.746 -70.392,-35.167 -70.584,-35.26 -70.434,-35.357 -70.363,-35.815 -70.413,-35.908|-70.396,-35.906 -70.386,-36.046 -70.5,-36.163|-70.57,-36.14 -70.716,-36.266 -70.714,-36.403 -70.809,-36.433|-70.893,-36.401 -70.974,-36.485|-71.013,-36.478 -71.076,-36.695|-71.13,-36.677 -71.202,-36.848 -71.167,-36.975|-71.204,-36.972 -71.095,-37.103 -71.211,-37.293 -71.123,-37.466 -71.19,-37.706 -71.013,-38.071 -70.979,-38.425 -70.84,-38.564 -70.971,-38.75|-71.015,-38.746 -71.421,-38.935 -71.417,-39.318 -71.538,-39.615|-71.558,-39.613 -71.604,-39.619|-71.69,-39.568 -71.716,-39.747 -71.622,-39.91 -71.689,-40.098|-71.771,-40.077 -71.829,-40.21 -71.734,-40.298|-71.707,-40.282 -71.734,-40.421|-71.787,-40.412 -71.961,-40.72 -71.857,-40.938 -71.909,-41.368 -71.859,-41.567 -71.931,-41.653 -71.742,-42.084 -71.926,-42.176|-72.01,-42.125 -72.139,-42.288 -72.045,-42.481 -72.149,-42.557 -72.154,-42.999 -72.06,-43.105 -71.756,-43.172 -71.766,-43.306|-71.808,-43.3 -71.907,-43.322 -71.939,-43.456|-71.909,-43.45 -71.852,-43.542|-71.828,-43.542 -71.709,-43.672 -71.799,-43.78|-71.764,-43.77 -71.665,-43.94 -71.864,-44.108 -71.822,-44.403|-71.738,-44.393 -71.643,-44.402|-71.443,-44.402 -71.215,-44.428 -71.128,-44.53 -71.338,-44.801|-71.5,-44.743 -71.636,-44.78|-71.766,-44.755 -71.857,-44.791|-72.051,-44.755 -72.054,-44.907|-72.014,-44.905 -71.891,-44.947|-71.786,-44.928 -71.664,-44.979|-71.626,-44.975 -71.317,-45.299 -71.514,-45.408 -71.484,-45.483 -71.566,-45.524|-71.641,-45.52 -71.755,-45.549 -71.807,-45.724 -71.618,-45.97 -71.92,-46.152 -71.769,-46.244 -71.686,-46.538 -71.693,-46.69 -71.956,-46.814 -71.92,-46.998 -72.011,-47.062 -71.88,-47.142 -71.916,-47.234|-72.031,-47.198 -72.212,-47.42|-72.267,-47.414 -72.367,-47.451 -72.35,-47.602 -72.549,-47.915 -72.348,-48.07 -72.318,-48.35|-72.36,-48.343 -72.62,-48.51 -72.624,-48.82 -73.015,-48.99 -73.19,-49.214 -73.103,-49.267 -73.15,-49.304 -73.477,-49.317 -73.592,-49.53 -73.468,-49.787 -73.578,-49.932 -73.484,-50.009 -73.547,-50.114 -73.307,-50.3 -73.263,-50.573 -73.101,-50.771|-72.76,-50.617 -72.663,-50.668|-72.508,-50.602 -72.308,-50.649 -72.353,-50.743 -72.262,-50.875 -72.282,-51.007 -72.41,-51.106 -72.263,-51.231 -72.456,-51.553 -72.402,-51.58|-72.381,-51.58 -72.306,-51.691 -71.987,-51.845 -71.923,-51.99 -69.958,-52.007 -68.46,-52.3 -68.633,-52.639 -68.664,-54.913|-68.259,-54.877 -67.208,-54.919 -66.096,-55.25 -65.902,-55.146 -63.88,-55.001 -63.49,-54.792 -63.519,-54.631 -63.714,-54.532 -64.759,-54.559 -65.098,-54.453 -65.887,-54.417 -67.189,-53.848 -67.509,-53.596|-67.499,-49.966 -67.258,-49.095 -66.852,-48.796 -65.685,-48.238 -65.508,-48.04 -65.556,-47.769 -65.434,-47.331 -65.548,-47.066 -65.715,-46.94 -66.61,-46.827 -67.166,-46.445 -67.313,-46.169 -67.277,-46.042 -66.746,-45.411 -66.432,-45.393 -66.125,-45.205 -65.638,-45.242 -65.384,-45.146 -65.248,-44.914 -65.294,-44.758 -64.992,-44.522 -64.924,-44.015 -65.027,-43.766 -64.993,-43.671 -64.689,-43.359 -63.515,-42.975 -63.338,-42.783 -63.332,-42.259 -63.581,-41.929 -63.853,-41.884 -64.454,-42.038 -64.774,-41.974 -64.726,-41.511 -64.852,-41.061 -63.747,-41.372 -63.065,-41.354 -62.628,-41.233 -62.139,-41.011 -61.942,-40.735 -61.921,-40.561 -62.137,-40.32 -62.061,-40.06 -61.861,-39.893 -61.771,-39.465 -61.554,-39.241 -58.989,-38.896 -58.085,-38.637 -57.413,-38.304 -57.288,-38.163 -57.233,-37.911 -56.453,-37.027 -56.41,-36.624 -56.539,-36.186 -56.713,-36.096 -56.932,-36.122 -57.125,-35.9 -56.879,-35.51 -56.929,-35.27 -57.583,-34.675 -57.274,-34.682 -56.33,-35.12 -56.055,-35.121 -55.649,-34.992 -54.893,-35.178 -54.039,-34.861 -53.613,-34.551 -53.215,-33.911 -52.562,-33.377 -52.533,-77.019|-56.409,-64.037 -56.731,-63.999 -56.609,-63.837 -56.408,-63.806 -56.405,-63.146 -57.363,-63.146 -57.368,-64.418 -56.411,-64.418 -56.409,-64.037|-64.663,3.997 -64.663,3.997|-22.682,83.048 -23.163,83.095 -23.306,83.196 -24.354,83.433 -27.883,83.706 -32.517,83.836 -37.548,83.747|-24.369,65.279 -24.219,65.231 -24.224,65.098 -24.482,65.004 -24.551,64.894 -24.248,64.596 -23.889,64.52 -22.947,64.584 -22.593,64.331 -23.015,64.245 -23.213,64.0 -23.118,63.717 -22.848,63.614 -22.527,63.612 -22.54,40.191 -31.747,40.191 -31.747,36.499 -22.539,36.499 -22.536,18.395 -27.513,18.395 -27.513,13.401 -22.535,13.401 -22.514,-90.0|-22.527,63.612 -21.2,63.645 -20.779,63.498 -20.605,63.253 -20.29,63.193 -19.836,63.317 -18.83,63.189 -7.515,63.22 -7.515,62.462 -7.664,62.33 -7.985,62.244 -8.089,62.083 -7.942,61.948 -7.515,61.869 -7.516,58.199 -8.827,58.015 -8.995,57.894 -9.004,57.804 -8.719,57.605 -7.822,57.444 -7.827,57.151 -7.937,56.921 -7.806,56.792 -7.516,56.732 -7.516,55.583 -8.467,55.342 -8.859,55.127 -8.934,54.918 -9.163,54.704 -9.036,54.503 -9.799,54.547 -10.174,54.491 -10.424,54.346 -10.617,53.934 -10.293,53.756 -10.543,53.604 -10.528,53.39 -10.384,53.242 -10.177,53.192 -10.1,53.018 -9.823,52.903 -10.223,52.683 -10.282,52.491 -10.692,52.337 -10.817,52.142 -10.743,51.813 -10.415,51.446 -9.908,51.241 -8.593,51.375 -7.86,51.641 -7.86,43.997 -8.519,43.729 -8.634,43.546 -9.153,43.469 -9.521,43.189 -9.571,42.896 -9.148,42.316 -9.136,41.637 -18.559,32.979 -18.534,27.053 -13.683,27.051 -13.767,26.871 -14.312,26.601 -14.647,26.334 -15.041,25.424 -15.116,24.83 -16.117,23.914 -16.235,23.702 -16.204,23.52 -16.424,23.18 -16.584,22.669 -17.005,22.253 -17.18,21.856 -17.302,20.744 -17.133,20.567 -16.891,20.622 -16.541,20.309 -16.539,19.998 -16.711,19.773 -16.681,19.553 -16.757,19.366 -16.656,19.143 -16.423,18.943 -16.253,18.062 -16.351,17.418 -16.675,16.687 -16.798,15.772 -17.26,15.117 -17.736,14.838 -17.636,14.532 -17.449,14.444 -17.322,14.476 -17.149,14.244 -16.875,13.618 -17.044,13.36 -17.014,12.41 -16.89,12.191 -16.591,12.011 -16.384,11.768 -16.58,11.671 -16.639,11.537 -16.357,10.903 -16.034,10.823 -15.811,10.862 -15.558,11.04 -15.17,10.638 -14.899,10.538 -14.592,10.058 -13.945,9.686 -13.895,9.388 -13.649,9.283 -13.531,9.112 -13.447,8.788 -13.488,8.394 -13.31,8.031 -13.159,7.964 -13.081,7.737 -13.156,7.542 -13.079,7.406 -11.862,6.929 -11.601,6.741 -11.466,6.529 -11.016,6.331 -10.901,6.118 -10.311,5.847 -9.164,4.83 -8.301,4.382 -7.506,4.138 -7.506,-5.828 -16.188,-5.828 -16.143,-9.363 -7.506,-9.363 -7.515,-35.659 -14.641,-35.659 -14.641,-41.714 -7.517,-41.714 -7.528,-70.574 -8.345,-70.688 -8.582,-70.817 -8.666,-71.031 -9.769,-70.727 -9.769,-71.952 -7.529,-71.952 -7.536,-90.0|-25.213,-75.639 -27.95,-76.02|-33.625,-77.032 -35.136,-77.342 -35.742,-77.644 -36.234,-77.754 -36.511,-77.967 -37.048,-78.188 -37.549,-78.177 -37.549,-74.9|-37.549,-54.934 -45.039,-54.934|-45.039,-52.088 -37.549,-52.088|-37.543,-12.256 -36.801,-10.98 -36.259,-10.646 -35.108,-9.272 -34.699,-8.26 -34.593,-7.641 -34.623,-6.958 -35.055,-5.461 -35.245,-5.103 -35.486,-4.946 -35.872,-4.855 -36.619,-4.885 -36.828,-4.751 -37.041,-4.727 -37.179,-4.553 -37.544,-4.375|-7.86,43.997 -7.601,44.007 -7.1,43.801 -6.398,43.796 -5.817,43.892 -5.546,43.785 -4.56,43.636 -3.563,43.747 -3.155,43.618 -2.75,43.68 -2.19,43.539 -1.801,43.629 -1.566,44.365 -1.435,45.533 -1.862,46.286 -2.025,46.357 -2.12,46.512 -2.541,46.534 -2.684,46.675 -2.649,46.829 -3.031,47.085 -3.512,47.226 -3.574,47.315 -3.523,47.499 -4.033,47.628 -4.47,47.606 -4.702,47.807 -4.968,47.908 -5.044,48.05 -4.998,48.205 -5.32,48.286 -5.452,48.455 -5.416,49.213 -3.582,49.552 -2.943,49.774 -2.808,49.963 -2.059,50.153 -0.501,50.124 0.776,50.389 1.123,50.643 1.356,50.949 1.907,51.212 2.386,51.283 3.097,51.551 3.752,52.124 4.064,52.274 4.243,52.521 4.387,53.132 4.729,53.436 5.154,53.61 5.992,53.683 7.499,53.977 7.499,57.804 6.971,57.783 6.443,57.878 5.251,58.479 5.058,58.706 5.134,58.931 4.856,59.006 4.729,59.16 4.778,59.472 4.653,59.787 4.752,60.024 4.528,60.219 4.528,60.409 4.351,60.584 4.422,60.792 4.207,61.024 4.251,61.147 4.521,61.358 4.539,61.505 4.397,61.636 4.366,61.886 4.73,62.322 5.278,62.548 5.797,62.638 6.283,62.834 6.574,63.076 7.312,63.283 7.354,63.504 7.517,63.585 7.517,84.9|-9.168,41.866 -8.887,41.866 -8.627,42.051 -8.222,42.154 -8.204,42.07 -8.095,42.041 -8.23,41.905 -8.18,41.811 -7.906,41.914 -7.897,41.858 -7.722,41.899 -7.443,41.806 -7.219,41.879 -7.145,41.988 -6.609,41.962 -6.524,41.867 -6.541,41.659 -6.206,41.57 -6.321,41.411 -6.647,41.268 -6.804,41.064 -6.942,41.016 -6.816,40.857 -6.857,40.442 -6.794,40.356 -7.043,40.181 -6.88,40.009 -7.021,39.694 -7.557,39.68 -7.313,39.457 -7.258,39.211 -6.973,39.014 -7.056,38.855 -7.27,38.738 -7.359,38.446 -7.103,38.174 -6.958,38.168 -7.024,38.023 -7.273,37.977 -7.53,37.567 -7.357,36.958 -7.02,36.972 -6.697,36.812 -6.673,36.631 -6.209,36.03 -5.648,35.926 -5.381,36.015 -5.051,35.958 -5.003,35.679 -4.556,35.397 -3.706,35.498 -3.357,35.418 -2.962,35.653 -2.765,35.577 -2.604,35.313 -2.217,35.319 -2.212,35.023 -1.769,34.741 -1.871,34.597 -1.703,34.48 -1.81,34.373 -1.67,34.079 -1.747,33.702 -1.617,33.554 -1.683,33.271 -1.499,33.06 -1.559,32.934 -1.423,32.742 -1.032,32.494 -1.244,32.357 -1.31,32.167 -1.196,32.146 -1.21,32.09 -2.516,32.132 -2.881,32.076 -3.016,31.828 -3.512,31.673 -3.832,31.687 -3.856,31.466 -3.744,31.392 -3.839,31.153 -3.731,31.176 -3.624,31.087 -3.646,30.96 -4.016,30.91 -4.445,30.639 -4.948,30.495 -5.149,30.191 -5.573,29.894 -6.494,29.821 -6.613,29.564 -7.141,29.623 -8.649,28.726 -8.682,27.285 -4.516,24.804 1.147,21.102 1.155,20.739 1.56,20.598 1.659,20.398 1.891,20.232 2.201,20.274 2.4,20.057 3.199,19.821 3.261,19.388 3.104,19.136 3.285,18.996 4.229,19.142 4.184,16.416 4.061,16.298 3.846,15.685 3.527,15.496 3.507,15.354 3.034,15.427 3.0,15.339 1.332,15.284 0.949,14.98 0.213,14.985 0.159,14.496 0.389,14.252 0.339,14.126 0.449,13.91 0.594,13.689 0.897,13.615 1.048,13.442 1.269,13.346 0.984,13.368 0.984,13.032 1.564,12.632 1.844,12.606 1.972,12.724 2.109,12.706 2.245,12.424 2.052,12.342 2.39,11.897 2.287,11.665 2.011,11.427 1.602,11.389 1.44,11.474 1.33,11.289 1.156,11.286 1.158,11.166 1.062,11.142 1.118,11.032 0.977,11.078 0.781,10.693 0.769,10.367 1.331,9.997 1.326,9.522 1.601,9.05 1.626,6.997 1.532,6.992 1.566,6.678 1.744,6.426 1.862,6.064 3.883,6.221 4.395,6.123 4.774,5.795 5.148,5.252 5.388,4.599 5.843,4.163 6.176,4.078 7.539,4.249 7.527,1.87 7.662,1.656 7.528,1.385 7.539,-0.685 2.656,-0.671 2.656,-3.957 7.539,-3.957 7.539,-53.699 2.5,-53.699 2.5,-55.199 7.539,-55.199 7.539,-69.967 8.378,-69.995 9.188,-69.86 9.875,-69.927 10.329,-69.814 10.834,-69.801 11.323,-69.865 11.614,-70.062 12.166,-69.881 12.888,-69.838 12.89,-71.878 7.539,-71.871 7.539,-89.572|-7.528,-70.574 -7.529,-71.952|-127.515,70.734 -127.515,90.0|-174.417,-15.0 -174.411,-12.475 -178.051,-7.667|-178.051,-2.509 -172.484,-2.509|157.508,43.793 157.508,12.0 153.997,12.0 153.997,-0.018 157.518,-0.023 157.518,-3.59 160.048,-3.59 160.059,-4.774 158.235,-4.871 156.036,-6.55 155.923,-6.847 155.599,-6.926 155.112,-7.247 154.586,-8.135 157.161,-11.374 157.518,-12.235 157.518,-90.0|157.508,43.793 157.508,49.982 154.019,47.688 148.596,44.284 145.914,43.22 145.64,43.026 145.378,43.008 145.11,42.839 144.774,42.759 144.184,42.798 143.605,42.333 143.531,42.009 143.35,41.78 143.116,41.783 142.515,42.061 142.515,40.394|142.502,-66.773 142.502,-38.602 141.879,-38.445 141.624,-38.588 141.331,-38.557 140.979,-38.242 140.957,-38.056 141.0,-31.975 141.643,-31.975 141.643,-31.441 141.0,-31.441 141.0,-26.0 138.0,-26.0 137.997,-16.407|142.502,-66.773 142.098,-66.65 140.138,-66.57 139.664,-66.462 139.664,-67.738 142.502,-67.738 142.502,-90.0|140.979,-38.242 140.609,-38.218 140.269,-38.045 139.678,-37.439 139.468,-36.968 139.655,-36.759 139.608,-36.572 139.265,-36.028 138.839,-35.736 138.337,-35.829 138.165,-36.054 137.819,-36.036 137.484,-36.246 136.576,-36.183 135.32,-34.86 134.958,-34.707 134.306,-33.869 134.189,-33.322 133.88,-32.986 133.867,-32.728 133.694,-32.64 133.659,-32.473 133.076,-32.356 132.684,-32.123 132.517,-32.196 132.153,-32.19 131.182,-31.659 130.822,-31.776 129.939,-31.76 128.997,-31.872|137.998,-16.268 138.311,-16.529 138.923,-16.681 139.029,-16.442 139.205,-16.287 139.579,-16.195 139.852,-16.28 139.943,-16.416 139.923,-16.59 139.59,-16.808 139.779,-17.059 139.659,-17.28 140.119,-17.515 140.445,-17.438 140.668,-17.279 140.765,-16.922 141.02,-16.586 141.42,-15.083 141.314,-14.484 141.391,-14.185 141.26,-13.858 141.437,-13.267 141.384,-12.931 141.494,-12.739 141.385,-12.513 141.77,-11.759 141.932,-11.175 141.908,-10.632 142.096,-10.408 141.945,-10.277 141.891,-10.106 142.059,-9.773 142.059,-9.457 141.365,-9.373 141.116,-9.436 140.977,-9.366 140.977,-6.897 140.849,-6.703 140.977,-6.335 140.974,-2.269 142.511,0.24 142.511,4.0 135.997,4.0 135.997,17.06 142.513,17.061|145.914,43.22 145.841,43.417 145.688,43.545 145.539,43.512 145.242,43.783 145.597,44.25 145.455,44.487 145.255,44.499 144.704,44.086 144.557,44.092 144.364,44.254 143.569,44.439 142.968,44.847 142.515,45.308 142.515,45.623 141.492,45.847 141.108,45.845 141.005,46.308 141.615,46.646 141.824,47.077 141.725,47.585 141.935,48.062 141.898,48.298 141.619,48.763 141.772,49.02 141.905,49.573 141.927,50.115 141.805,50.572 141.894,50.917 142.033,51.097 141.818,51.415 141.474,51.634 141.225,51.474 141.177,51.304 141.02,51.162 140.989,50.903 140.824,50.707 140.854,50.286 141.003,50.058 140.82,49.883 140.865,49.536 140.606,49.171 140.597,48.912 140.433,48.704 140.388,48.399 139.491,47.728 139.174,47.237 138.78,46.963 138.566,46.498 137.886,45.722 137.034,45.11 136.354,44.401 136.067,44.258 135.617,43.666 135.27,43.367 134.058,42.741 133.235,42.524 132.612,42.649 132.268,42.582 132.061,42.824 131.68,42.704 131.573,42.503 131.259,42.386 131.057,42.404 130.981,42.297 130.7,42.295 130.531,42.531|154.019,47.688 146.997,54.449 146.997,59.401 147.128,59.502 147.141,59.849 147.004,59.947 146.776,59.906 146.645,59.99 146.676,60.102 146.454,60.132 146.374,60.271 145.793,60.198 145.594,60.307 145.637,60.383 145.51,60.464 146.06,60.737 146.443,60.69 146.486,60.933 146.731,61.004 146.666,61.061 146.747,61.115 146.682,61.304 146.768,61.403 146.615,61.434 146.583,61.636 146.355,61.827 145.959,62.005 145.722,62.06 145.484,61.956 145.168,61.965 144.719,62.082 145.174,62.276 145.124,62.49 145.482,62.553 145.326,62.754 145.366,62.91 145.252,63.19 145.451,63.528 145.641,63.667 145.556,63.828 146.109,63.942 146.27,64.055 145.704,64.38 144.867,64.561 144.29,65.087 143.961,65.037 143.404,65.201 143.1,65.113 142.973,65.353 142.821,65.404 142.264,65.201 141.872,65.48 141.72,65.505 141.391,65.315 141.252,65.315 141.036,65.505 140.129,65.635 140.37,65.819 140.019,65.929 139.834,65.809 139.53,65.758 138.834,65.733 138.72,65.606 138.023,65.302 137.64,65.239|157.508,49.982 165.586,50.03 168.774,52.204|157.508,76.656 151.471,73.289 146.874,73.259 146.874,72.999 131.872,72.999|157.508,76.656 157.507,84.9|157.508,76.656 151.48,73.289 146.884,73.259 146.874,72.999|157.508,76.656 157.517,84.9|132.542,70.335 132.843,70.341|133.028,69.865 133.145,69.882|133.343,69.745 133.533,69.745|133.472,69.651 133.31,69.657|133.171,69.562 133.041,69.563|132.693,69.123 132.519,69.138|131.658,67.658 131.388,67.676|132.892,64.296 133.001,64.302|133.387,64.252 133.63,64.315 133.719,64.657 133.934,65.037 134.149,65.075|134.463,64.923 135.048,64.961 135.314,65.087 135.593,65.378 136.042,65.529|137.063,65.227 137.354,65.365|138.979,65.77 139.168,65.746|139.384,65.77 139.533,65.759|140.019,65.929 140.083,66.021 139.612,66.241 140.429,66.441 140.49,66.549 139.469,66.839 139.303,67.023 138.887,67.105 138.839,67.166 139.027,67.359 138.762,67.515 139.513,67.541 140.046,67.746 140.569,67.832 141.177,67.758 140.945,67.941 140.932,68.009 141.088,68.133 140.943,68.265 141.063,68.399 141.465,68.46 141.84,68.652 141.52,68.908 141.505,69.148 141.703,69.22 142.551,69.201 142.724,69.279 142.302,69.528 142.394,69.562 142.01,69.578 142.119,69.695 142.087,69.744 142.245,69.835 141.414,69.826 141.202,69.957 140.819,69.945 140.863,70.188 141.74,70.617 141.907,70.829 142.612,71.113 142.533,71.381 142.635,71.591 143.06,71.753 143.208,72.0 144.106,72.278 144.506,72.2 145.054,72.305 146.803,72.325 146.875,72.336 146.874,72.58 148.61,72.509 150.284,72.242 150.741,71.942 150.622,71.732 152.039,71.46 152.815,71.041 155.795,71.303 157.626,71.282 158.768,71.161 159.742,70.96 160.004,71.08 160.447,71.144 161.165,71.022 161.796,71.031 162.263,70.885 162.834,70.835 163.111,70.68 162.959,70.517 162.482,70.438 161.068,70.642 160.607,70.558 160.726,70.248 160.463,69.942 161.216,69.826 164.075,69.98 164.779,69.811 166.759,69.738 167.489,70.071 168.148,70.226 169.875,70.02 169.835,70.18 170.301,70.338 172.571,70.184 172.535,90.0|140.329,65.561 139.78,65.359 139.402,64.918 140.334,64.591 140.402,64.489 140.292,64.432 140.22,64.231 140.676,64.092 140.479,63.795 140.642,63.587 139.795,63.299 139.648,63.011 139.681,62.837 139.886,62.623 140.11,62.595 140.347,62.388 140.287,62.063 139.994,61.978 139.953,61.833 139.548,61.482 139.098,61.448 138.92,61.317 138.735,61.343 138.644,61.269 138.703,61.193 138.292,61.11 138.346,61.0 138.183,60.889 138.438,60.68 138.243,60.493 138.329,60.391 138.202,60.242 138.273,59.955 138.174,59.831 138.267,59.721 138.035,59.686 138.0,59.797 137.616,59.74 137.447,59.636 137.466,59.555 136.759,59.355 135.757,59.529 135.416,59.383 135.187,59.116 134.855,59.127 134.725,59.211 134.522,59.147 134.047,59.256 133.625,59.232 133.543,59.294 132.843,59.107 132.808,58.88 132.618,58.892|132.598,58.889 132.521,58.785 132.567,58.646 132.372,58.524 132.417,58.482 132.124,58.487 132.195,58.243 132.023,58.195 132.009,58.115 132.12,58.047 131.715,58.173 131.464,58.16 132.048,57.661 131.971,57.583 131.693,57.561 131.736,57.509 131.585,57.426 131.599,57.296 131.506,57.246 131.261,57.305 131.102,57.231 131.193,57.131 131.482,57.076 131.439,57.042 131.751,56.843 131.8,56.722 131.674,56.654 131.702,56.459 131.503,56.55 131.392,56.419 131.307,56.497 131.162,56.451 130.866,55.827 130.923,55.679 131.096,55.616 132.531,55.679 132.663,55.561 132.629,55.5 132.946,55.375 132.682,55.368 132.627,55.213 132.355,55.191 132.385,55.064 132.062,55.045 131.961,54.991 131.977,54.893 131.2,54.613 131.106,54.316 130.742,54.281 130.507,54.12 130.394,53.915 130.921,53.768 131.097,53.813 131.421,53.751 131.533,53.314 131.446,53.219 131.853,53.234 131.894,53.128 132.1,53.222 133.153,53.291 133.221,53.429 133.573,53.546 134.011,53.433 134.432,53.521 134.555,53.621 134.916,53.427 134.814,53.341 134.956,53.254 134.859,53.184 134.867,53.076 134.659,52.939 134.631,52.801 134.712,52.761 134.658,52.724 134.784,52.655 134.644,52.559 134.635,52.427 133.875,52.52 133.321,52.682 133.24,52.628 133.246,52.45 133.436,52.281 133.34,52.204 132.829,52.178 132.579,52.074 132.517,51.953 132.404,51.963 132.427,51.864 132.279,51.793 131.41,51.681 131.497,51.353 131.33,51.376 131.06,51.243 130.926,51.027 130.782,50.993 130.84,50.876 130.645,50.657 130.728,50.598 130.758,50.665 130.933,50.666 131.011,50.568 130.87,50.475 130.92,50.393 131.12,50.431 131.173,50.334 131.297,50.365 131.442,50.186 131.295,49.982 131.497,49.91 131.485,49.741 131.355,49.704 131.5,49.611 131.499,49.422 131.396,49.244 131.164,49.241 130.983,48.972 130.829,48.983 130.627,48.875|130.541,48.854 130.44,48.897|130.25,48.865 129.927,49.026 129.67,49.279|129.62,49.274 129.404,49.431|129.341,49.341 129.218,49.391|129.116,49.349 128.854,49.481|128.787,49.466 128.798,49.573 128.672,49.611|128.629,49.575 128.552,49.588|128.321,49.545 128.268,49.559|128.199,49.539 127.968,49.603|127.908,49.58 127.509,49.822 127.488,50.026 127.592,50.209 127.332,50.328 127.36,50.415 127.29,50.466 127.36,50.605 126.933,51.064 126.955,51.33|126.847,51.252 126.815,51.325 126.91,51.391 126.678,51.577 126.727,51.709 126.44,51.998 126.557,52.131 126.318,52.2 126.44,52.275 126.317,52.316 126.352,52.377 126.247,52.466|126.218,52.465 126.07,52.595|126.028,52.567 125.974,52.632 126.07,52.68 126.067,52.783|125.985,52.765 125.838,52.907|125.669,52.878 125.735,52.982 125.621,53.062|125.522,53.043 125.074,53.212|124.871,53.108 124.802,53.155|124.748,53.148 124.385,53.246 124.21,53.383|124.122,53.353 123.615,53.563|123.542,53.514 123.515,53.562|123.482,53.518 123.278,53.569|122.402,53.451 122.317,53.496|122.082,53.43 121.89,53.431|121.407,53.317 121.358,53.324|121.153,53.275 121.055,53.29|120.176,52.584 120.454,52.639|120.625,51.905 120.579,51.908|120.512,51.876 120.503,51.877|120.154,51.664 120.123,51.667|119.803,51.213 119.773,51.218|119.199,50.413 119.169,50.414|119.189,50.355 119.214,50.357|119.252,50.343 119.315,50.352|118.991,49.979 118.924,49.992|118.714,49.95 118.671,49.962|118.242,49.729 118.23,49.729|117.837,49.509 117.796,49.519|117.769,49.511 117.059,49.673 116.576,49.922 116.136,50.014|115.684,49.878 115.579,49.894|115.509,49.887 115.45,49.891|115.389,49.891 114.998,50.144 114.66,50.251|114.474,50.234 114.287,50.277|113.817,50.077 113.774,50.082|112.702,49.491 112.474,49.534|111.455,49.343 111.363,49.368|110.688,49.135 110.372,49.242|110.182,49.162 109.729,49.266|109.517,49.256 109.451,49.306|109.412,49.303 109.161,49.347|109.034,49.328 108.931,49.349|108.859,49.341 108.752,49.341|108.609,49.324 108.003,49.663|107.964,49.661 107.957,49.923 107.84,49.947|107.809,49.944 107.745,49.968 107.77,50.147 107.99,50.335 108.676,50.495 108.067,50.754 108.25,50.844 108.336,51.046 108.57,51.111 108.354,51.267 108.592,51.506 108.942,51.441 109.074,51.507 109.367,51.353 110.049,51.616 110.677,51.505 111.055,51.794 111.595,51.926 112.07,52.28 112.405,52.208 112.545,52.347 112.931,52.337 113.266,52.476 113.581,52.455 114.103,52.705 114.238,52.826 114.228,52.955 114.313,52.972 114.325,53.068 114.129,53.076 114.198,53.193 113.983,53.236 113.946,53.352 113.843,53.382 113.889,53.535 113.815,53.649 114.958,54.019 115.629,54.442 116.723,54.565 116.928,54.826 116.893,54.977 116.783,55.144 116.469,55.258 116.393,55.402 115.945,55.414 115.913,55.675 115.845,55.705 115.897,55.948 115.763,56.076 115.838,56.179 115.688,56.327 115.694,56.439 115.801,56.466 115.681,56.525 115.688,56.595 115.434,56.69 115.587,56.747 115.589,56.902 115.711,56.964 116.122,56.813 116.362,56.847 116.797,56.725 117.131,56.804 117.328,56.943 117.411,56.827 117.571,56.851 117.685,57.014 117.601,57.15 117.795,57.293 117.432,57.255 117.444,57.329 117.366,57.328 117.254,57.514 117.287,57.613 117.142,57.641 117.173,57.737 117.086,57.804 117.409,57.906 117.408,58.127 117.587,58.18 117.476,58.309 117.684,58.398 118.158,58.386 118.661,58.175 119.108,58.223 119.069,58.357 119.133,58.461 118.776,58.604 118.893,58.805 118.786,58.9 118.85,59.009 118.707,59.064 118.689,59.192 118.846,59.291 118.749,59.413 118.283,59.609 118.058,59.583 117.883,59.442 117.758,59.539 117.598,59.472 117.234,59.531 117.087,59.591 117.199,59.655 117.226,59.821 117.064,59.913 117.296,60.019 117.054,60.035 116.977,60.154 116.599,60.355 115.709,60.525 115.238,60.447 114.825,60.187 114.697,60.219 114.543,60.108 114.57,60.001 114.175,59.754 113.592,59.565 113.605,59.499 113.424,59.383 113.461,59.262 113.264,59.157 112.569,59.067 112.616,58.962 112.503,58.87 112.452,59.125 112.631,59.311 112.293,59.301 112.333,59.417 112.271,59.5 111.942,59.274 111.637,59.208 111.47,59.267 111.175,59.188 110.697,59.257 110.531,59.059 110.278,58.984 109.822,58.981 109.642,59.062 109.51,59.289 109.261,59.321 109.348,59.41 109.268,59.461 109.523,59.636 109.501,59.759 109.764,60.027 109.694,60.115 109.732,60.225 110.116,60.587 110.049,60.672 110.267,60.697 110.235,60.825 110.458,60.988 110.506,61.138 110.19,61.155 110.081,61.27 109.792,61.325 109.87,61.533 109.62,61.718 109.598,61.87 110.0,62.164 109.936,62.239 109.997,62.288 109.902,62.414 109.487,62.411 109.267,62.524 109.647,62.826 109.472,62.932 109.452,63.223 109.365,63.354 109.042,63.552 108.125,63.58 108.265,63.673 108.298,63.811 108.648,63.787 108.767,63.868 108.688,63.914 108.732,63.984 108.495,64.116 108.534,64.235 108.468,64.282 108.141,64.261|107.745,49.968 107.306,50.01|108.219,64.25 108.321,64.039 108.253,63.992|107.968,64.17 107.57,64.299|107.343,64.248 106.878,64.414|106.765,64.413 106.747,64.419|106.748,64.416 106.605,64.513|106.171,64.401 106.028,64.514|105.942,64.488 105.892,64.49|105.834,64.479 105.729,64.668|105.831,64.644 105.91,64.821|105.959,64.81 106.008,64.823 105.947,64.889 106.026,64.905|106.195,64.85 105.979,65.022 106.426,65.215|106.498,65.205 106.434,65.298 106.625,65.393|106.741,65.378 106.762,65.378|106.799,65.37 106.959,65.502 106.421,65.671 106.484,65.964 106.331,66.154|106.237,66.15 106.121,66.192 106.102,66.373 106.323,66.479 106.149,66.808|106.036,66.788 106.058,66.896 105.807,66.947|105.714,66.937 105.541,67.023 105.969,67.063 106.056,67.167 106.505,67.285|106.656,67.244 106.803,67.348 106.876,67.84 106.892,68.855 106.141,69.404 106.456,69.571|106.605,69.517 107.812,69.685|107.893,69.678 108.291,69.857|108.599,69.837 108.871,69.84|109.13,69.768 109.361,69.838 109.509,70.028 109.353,70.073 109.283,70.212 109.536,70.264 109.603,70.378 109.838,70.405|109.883,70.402 110.001,70.417|110.063,70.412 110.143,70.421|110.24,70.419 110.073,70.555|110.127,70.553 110.104,70.632 110.596,70.803|110.633,70.8 110.727,70.814|110.8,70.801 111.336,70.855 112.077,71.061|112.218,71.0 112.401,71.065|112.454,71.064 112.696,71.217 112.617,71.288|112.502,71.267 112.001,71.408 111.997,72.133 111.765,72.144 111.537,72.319|111.418,72.315 111.058,72.381 111.296,72.503 110.99,72.575|110.93,72.571 110.68,72.662 110.61,72.786 110.696,72.826 110.628,72.895 110.838,72.945 110.755,73.0 110.902,73.051 110.771,73.171 110.398,73.194 110.594,73.264 110.537,73.317 110.159,73.395 110.539,73.406 110.856,73.568|110.989,73.565 111.125,73.63 110.909,73.692 110.879,73.768 111.639,73.935 111.684,74.07 111.341,74.278 111.386,74.427 112.652,74.77 114.501,75.0 114.501,78.0 120.501,78.0 127.528,79.999 142.519,79.999 142.519,90.0|127.528,79.999 127.533,80.0|172.508,50.672 172.5,20.86 160.573,20.86 160.559,8.05 163.989,8.05 163.997,-2.354 172.502,-2.356 172.501,-32.249 165.066,-43.913 165.048,-54.52|172.519,-54.52 172.507,-77.586 170.225,-77.502 170.068,-77.386 169.634,-77.282 167.887,-77.165 167.638,-77.073 167.791,-76.961 167.709,-76.871 166.942,-76.746 166.151,-76.841 166.046,-76.92 166.09,-77.027 165.626,-77.187 165.571,-77.281 165.682,-77.37 165.313,-77.543 165.743,-77.826 165.396,-77.831 164.613,-77.592 164.678,-77.506 164.632,-77.38 163.679,-76.895 163.761,-76.767 163.53,-76.574 163.655,-76.426 163.434,-76.147 163.454,-75.992 163.636,-75.836 163.541,-75.729 163.694,-75.545 163.177,-75.328 163.4,-75.086 164.419,-75.0 164.634,-74.921 164.78,-74.763 165.472,-74.819 165.989,-74.734 166.118,-74.632 166.126,-74.477 165.673,-74.187 166.104,-74.041|130.532,42.531 130.585,42.599 130.475,42.679|130.438,42.675 130.408,42.735 130.65,42.829|130.735,42.825 130.795,42.869|130.993,42.849 131.04,42.898|131.074,42.897 131.283,43.393 131.162,43.533 131.265,44.054 131.067,44.682 130.931,44.825 131.11,44.92|131.159,44.902 131.351,44.968|131.42,44.959 131.668,45.21|131.711,45.209 131.853,45.338|132.954,45.025 133.123,45.131 133.181,45.494 133.478,45.628 133.444,45.71 133.552,45.888|133.58,45.875 133.628,45.938|133.65,45.928 133.688,46.142 133.807,46.217|133.831,46.197 133.897,46.327|133.875,46.32 133.935,46.391 133.847,46.471 134.016,46.665 134.07,46.981 134.228,47.118 134.185,47.328 134.415,47.439|134.472,47.429 134.774,47.711 134.56,48.01 134.719,48.263|134.701,48.262 134.543,48.357|134.49,48.339 134.387,48.381|133.937,48.273 133.878,48.275|133.797,48.251 133.739,48.251|133.464,48.09 133.38,48.106|133.324,48.1 133.224,48.126|132.79,47.933 132.706,47.96|132.477,47.707 132.333,47.737|132.118,47.69 132.026,47.698|131.914,47.668 131.837,47.685|131.781,47.679 131.703,47.696|131.604,47.662 131.419,47.743|131.085,47.675 130.943,47.718 130.908,47.884 130.676,48.064 130.825,48.294 130.717,48.499|130.64,48.477 130.531,48.616 130.651,48.876|53.893,26.293 54.269,26.354 54.287,25.864 54.439,25.705 54.607,25.698 54.775,25.881 54.701,26.098 54.797,26.286 55.097,26.416 55.296,26.337 55.69,26.443 55.932,26.417 56.223,26.629 56.505,26.673 56.659,26.893 56.821,26.713 56.961,25.989 57.136,25.652 58.106,25.345 58.684,25.362 59.011,25.194 59.416,25.237 60.271,25.125 61.758,24.827 62.43,24.903 62.674,25.051 63.546,25.0 63.782,25.159 64.645,24.958 64.945,25.094 66.298,25.254 66.469,25.13 66.457,24.73 66.928,24.56 67.131,24.008 67.319,23.739 67.513,23.624|53.893,26.293 53.382,26.577 53.085,26.631 52.946,26.75 52.905,26.928 52.511,27.166 52.52,27.07|61.567,24.888 61.66,25.769 61.755,25.82 61.833,26.225 62.124,26.374 62.265,26.361 62.292,26.501 62.419,26.562 62.754,26.644 63.141,26.625 63.19,26.846 63.262,26.872 63.231,27.066 63.32,27.117 63.177,27.258 62.892,27.214 62.742,27.267 62.815,27.495 62.762,28.246 62.576,28.229 62.363,28.419 61.893,28.543 61.567,28.871 61.337,29.374 60.844,29.858 61.802,30.847 61.826,31.015 61.687,31.373 60.822,31.495 60.775,32.027 60.83,32.249 60.563,33.058 60.568,33.151 60.921,33.514 60.512,33.638 60.493,34.139 60.644,34.307 60.891,34.319 60.7,34.516 60.948,34.638 61.066,34.815 61.147,35.102 61.108,35.278 61.187,35.3 61.29,35.548 61.241,35.894 61.13,35.971 61.225,36.124 61.147,36.357 61.166,36.636 60.342,36.637 60.019,37.026 59.462,37.208 59.312,37.53 58.801,37.695 58.358,37.633 58.207,37.679 58.157,37.788 57.352,37.968 57.175,38.278 57.038,38.187 56.437,38.255 56.214,38.069 55.447,38.084 54.857,37.761 54.788,37.525 54.654,37.439 54.206,37.325 53.663,37.349 51.555,39.101 50.943,41.54 50.633,41.943 49.888,42.56 50.0,42.75 49.335,43.283 49.0,43.32 49.0,44.067 49.6,44.067 49.6,44.333 49.088,44.333 49.175,45.098 50.017,45.985 49.702,46.187 49.505,46.192 48.918,46.474 48.539,46.568 48.455,46.661 48.557,46.762 48.764,46.683 49.006,46.769 48.525,47.41 48.174,47.713 47.412,47.836 47.36,47.683 47.124,47.808 47.159,47.872 47.044,47.986 47.192,48.072 47.104,48.101 47.099,48.265 46.478,48.411 46.754,48.914 47.021,49.097 47.029,49.202 46.775,49.333 46.923,49.861 47.329,50.073 47.265,50.186 47.306,50.295 47.599,50.453 47.993,50.182 48.239,49.865 48.418,49.812 48.862,49.993 48.673,50.58 48.568,50.637 48.83,50.596 49.369,50.827 49.424,50.882 49.347,50.964 49.437,51.112 49.779,51.102 50.325,51.304 50.36,51.413 50.527,51.47 50.582,51.635 50.764,51.579 50.744,51.742 51.415,52.103 51.413,52.35 51.563,52.447 51.471,52.527 51.54,52.677 51.727,52.664 51.728,52.87 52.158,53.103 52.059,53.139 52.193,53.375 52.08,53.514 52.254,53.654 52.413,53.927 52.376,53.981 52.485,54.059 52.271,54.118 52.349,54.217 52.204,54.299 52.539,54.377 53.001,54.271 53.053,54.337 53.108,54.247 52.942,54.204 53.073,54.07 53.186,54.094 53.385,53.974 53.471,54.046 53.349,54.391 53.417,54.56 53.606,54.714 53.643,54.9 53.499,54.891 53.147,55.147 53.591,55.212 54.23,55.686 53.966,55.782 53.986,55.851 53.632,55.907 53.838,56.039 54.006,56.029 54.371,56.299 54.329,56.443 54.041,56.593 54.084,56.664 53.845,56.638 53.822,56.8 54.046,56.753 54.099,56.966 54.4,57.043 54.277,57.104 54.319,57.286 54.119,57.309 54.264,57.464 54.181,57.466 54.176,57.556 53.99,57.573 54.156,57.706 54.099,57.972 53.81,58.228 53.886,58.319 53.705,58.595 53.922,58.783 53.725,58.926 53.877,59.093 53.403,59.15 53.206,59.364 53.423,59.684 53.592,59.709 53.703,60.011 53.457,60.205 52.298,60.242 52.324,60.432 52.139,60.473 52.134,60.547 51.777,60.601 51.89,60.876 52.355,60.844 52.431,60.978 52.79,60.949 52.877,61.094 53.372,61.029 53.354,60.893 53.804,60.85 53.854,60.98 54.98,60.864 55.062,61.009 55.199,61.01 55.288,61.121 55.716,61.088 55.83,61.249 56.287,61.209 56.391,61.42 56.676,61.522 58.811,61.509 59.349,61.682 59.338,61.845 59.485,61.993 59.405,62.14 59.644,62.51 59.511,62.548 59.399,62.718 59.477,62.907 59.285,62.965 59.223,63.072 59.573,63.927 59.77,64.0 59.858,64.141 59.588,64.233 59.606,64.454 59.482,64.487 59.704,64.668 59.655,64.783 60.147,65.065 60.42,65.053 60.645,64.891 60.808,65.044 60.979,65.048 61.241,65.192 61.331,65.282 61.254,65.319 61.871,65.699 62.851,65.873 62.803,65.932 62.884,65.98 62.821,66.013 62.862,66.075 63.105,66.25 63.296,66.239 63.242,66.328 63.415,66.48 65.105,66.895 65.078,67.042 65.216,67.076 65.19,67.145 65.662,67.311 65.702,67.389 66.103,67.48 66.036,67.575 65.796,67.568 65.852,67.655 66.206,67.693 66.02,67.798 66.09,67.93 65.437,67.92 65.29,68.012 65.277,68.236 65.654,68.556 65.408,68.661 65.315,68.803 64.528,68.899 64.581,68.946 64.527,69.023 65.038,69.271 65.04,71.013 70.03,75.091 70.05,81.998 67.537,81.998 67.537,90.0|67.5
/* the parsed time zone borders, each a flat [ lon, lat, ... ] list */
final List<List<double>> worldTzBorders = [
  for (final ring in worldTzBordersStr.split('|'))
    [
      for (final pair in ring.split(' '))
        if (pair.isNotEmpty)
          () {
            final c = pair.split(',');
            return double.parse(c[0]);
          }()
    ],
];

/* the disputed border overlays of the web: each a polyline of
   [ longitude, latitude ] pairs */
const disputedOverlays = <String, List<List<double>>> {
  'crimee': [[33.4, 46.0], [33.7, 46.2], [34.4, 46.0], [34.7, 46.0], [34.9, 45.8], [35.0, 45.7]],
  'cachemire': [[75.3, 32.3], [74.5, 32.8], [74.1, 33.4], [73.7, 34.3], [74.2, 34.7], [75.8, 34.5]],
  'berm': [[-8.8, 27.7], [-8.8, 27.1], [-9.4, 27.1], [-9.7, 26.9], [-10.2, 26.9], [-10.5, 27.0], [-11.4, 26.9], [-11.7, 26.1], [-12.0, 26.0], [-12.5, 24.8], [-13.9, 23.7], [-14.2, 22.3], [-14.6, 21.9], [-14.8, 21.5]],
  'kosovo': [[20.3, 42.8], [20.5, 42.9], [20.6, 43.2], [20.8, 43.3], [21.0, 43.1], [21.1, 43.1], [21.3, 42.9], [21.4, 42.9], [21.6, 42.7], [21.8, 42.7], [21.7, 42.4], [21.5, 42.3], [21.6, 42.2]],
  'chypre': [[32.7, 35.1], [32.9, 35.1], [33.2, 35.2], [33.4, 35.2], [33.5, 35.1], [33.5, 35.0], [33.7, 35.0], [33.9, 35.1], [34.0, 35.1]],
  'golan': [[35.7, 32.7], [35.8, 32.9], [35.8, 33.3]],
  'arunachal': [[91.7, 27.8], [92.5, 27.9], [93.4, 28.6], [94.6, 29.3], [95.4, 29.0], [96.1, 29.5], [96.6, 28.8], [96.2, 28.4], [97.3, 28.3]],
  'essequibo': [[-59.8, 8.4], [-60.6, 7.8], [-60.6, 7.4], [-60.3, 7.0], [-60.5, 6.9], [-61.2, 6.7], [-61.1, 6.2], [-61.4, 6.0], [-60.7, 5.2]],
  'senkaku': [[123.57, 25.75], [123.54, 25.86], [123.46, 25.94], [123.35, 25.97], [123.24, 25.94], [123.16, 25.86], [123.13, 25.75], [123.16, 25.64], [123.24, 25.56], [123.35, 25.53], [123.46, 25.56], [123.54, 25.64], [123.57, 25.75]],
};
