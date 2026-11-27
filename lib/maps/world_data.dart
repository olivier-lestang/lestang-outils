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
