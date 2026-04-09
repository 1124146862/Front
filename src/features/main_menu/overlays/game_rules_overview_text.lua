local OverviewTexts = {
    ["en-US"] = {
        title = "Game Overview",
        intro = "Here is a one-page overview of Guandan. Drag or use the mouse wheel to scroll.",
        sections = {
            {
                title = "Teamwork And Progression",
                items = {
                    "4 players, with fixed partners across the table.",
                    "Two standard decks, including 4 jokers.",
                    "The goal is to empty your hand and help your team advance.",
                    "Level mode runs from 2 up to A; the current level changes which cards are special.",
                },
            },
            {
                title = "The Wild Cards",
                items = {
                    "Each deal has two wild cards; classic single-round play fixes the level at 2.",
                    "Cards of the current level rank are strong, second only to jokers.",
                    "The two hearts of the level act as super wild cards and can replace any non-joker to build straights or bombs.",
                },
            },
            {
                title = "Combinations",
                items = {
                    "Single, pair, or triple.",
                    "Full house: three of a kind + a pair.",
                    "Straight: exactly 5 consecutive singles.",
                    "Double triple run: two consecutive triples.",
                    "Consecutive pairs: three consecutive pairs.",
                },
            },
            {
                title = "Bombs",
                items = {
                    "Ultimate bomb: four jokers.",
                    "Super bomb: six, seven, or eight of a kind.",
                    "Straight flush: five in a row, same suit; beats normal bombs of five cards or fewer.",
                    "Normal bomb: four or five of a kind.",
                },
            },
            {
                title = "Winning And Tribute",
                items = {
                    "Ranks are decided by finish order.",
                    "In level mode, the team advances 1 to 3 levels based on the final order.",
                    "Tribute: the last finisher, or both losing players, gives their highest card to the winners, who return any card.",
                    "Counter-tribute: if the losing side has two big jokers, tribute is canceled.",
                },
            },
        },
        hint = "Drag or use the mouse wheel to scroll.",
    },
    ["zh-CN"] = {
        title = "游戏介绍",
        intro = "以下是掼蛋的一页式介绍，拖动或使用鼠标滚轮即可滚动阅读。",
        sections = {
            {
                title = "团队合作与升级",
                items = {
                    "4 名玩家对坐，固定搭档一起行动。",
                    "使用 2 副标准牌，包含 4 张王。",
                    "目标是尽快打完手牌，帮助队友升级。",
                    "升级模式从 2 到 A，当前级别会决定哪些牌具有特殊效果。",
                },
            },
            {
                title = "万能牌机制",
                items = {
                    "每局都会产生两张万能牌；经典单局玩法会把打级固定在 2。",
                    "当前级别的数字牌属于大牌，仅次于王。",
                    "当前级别的两张红桃是超万能牌，可以替代除王以外的任意牌来组成顺子或炸弹。",
                },
            },
            {
                title = "常规牌型",
                items = {
                    "单张 / 对子 / 三张。",
                    "满堂红：三张相同 + 一对。",
                    "顺子：必须正好 5 张连续单牌。",
                    "钢板：两组连续的三张。",
                    "连对：三对连续的对子。",
                },
            },
            {
                title = "炸弹",
                items = {
                    "终极炸弹：4 张王一起打出。",
                    "超级炸弹：6 / 7 / 8 张同点牌。",
                    "同花顺：5 张同花连续牌，可压 5 张及以下的普通炸弹。",
                    "普通炸弹：4 张或 5 张同点牌。",
                },
            },
            {
                title = "胜负与进贡",
                items = {
                    "结算顺序决定名次。",
                    "升级模式下，队伍会根据名次前进 1 到 3 级。",
                    "进贡：最后一名，或输家双方，把自己最大的牌交给赢家，赢家再返还任意一张。",
                    "抗贡：如果输家一方持有两张大王，本局会跳过进贡与还贡。",
                },
            },
        },
        hint = "拖动或使用鼠标滚轮浏览内容。",
    },
    ["zh-TW"] = {
        title = "遊戲介紹",
        intro = "以下是掼蛋的一頁式介紹，拖曳或使用滑鼠滾輪即可捲動閱讀。",
        sections = {
            {
                title = "團隊合作與升級",
                items = {
                    "4 名玩家對坐，固定搭檔一起行動。",
                    "使用 2 副標準牌，包含 4 張王。",
                    "目標是盡快打完手牌，幫助隊友升級。",
                    "升級模式從 2 到 A，目前級別會決定哪些牌具有特殊效果。",
                },
            },
            {
                title = "萬用牌機制",
                items = {
                    "每局都會產生兩張萬用牌；經典單局玩法會把打級固定在 2。",
                    "目前級別的數字牌屬於大牌，僅次於王。",
                    "目前級別的兩張紅心是超萬用牌，可以替代除王以外的任意牌來組成順子或炸彈。",
                },
            },
            {
                title = "常規牌型",
                items = {
                    "單張 / 對子 / 三張。",
                    "滿堂紅：三張相同 + 一對。",
                    "順子：必須正好 5 張連續單牌。",
                    "鋼板：兩組連續的三張。",
                    "連對：三對連續的對子。",
                },
            },
            {
                title = "炸彈",
                items = {
                    "終極炸彈：4 張王一起打出。",
                    "超級炸彈：6 / 7 / 8 張同點牌。",
                    "同花順：5 張同花連續牌，可壓 5 張及以下的普通炸彈。",
                    "普通炸彈：4 張或 5 張同點牌。",
                },
            },
            {
                title = "勝負與進貢",
                items = {
                    "結算順序決定名次。",
                    "升級模式下，隊伍會根據名次前進 1 到 3 級。",
                    "進貢：最後一名，或輸家雙方，把自己最大的牌交給贏家，贏家再返還任意一張。",
                    "抗貢：如果輸家一方持有兩張大王，本局會跳過進貢與還貢。",
                },
            },
        },
        hint = "拖曳或使用滑鼠滾輪瀏覽內容。",
    },
    ["ja-JP"] = {
        title = "ゲーム紹介",
        intro = "ここでは掼蛋の概要を1ページで紹介します。ドラッグするかマウスホイールでスクロールできます。",
        sections = {
            {
                title = "チーム戦と昇級",
                items = {
                    "4人対戦で、向かい合う相手が固定のチームになります。",
                    "標準デッキ2組、ジョーカーは4枚です。",
                    "手札を早く出し切り、味方の昇級を助けるのが目的です。",
                    "昇級モードでは2からAまで進み、現在の級で特別なカードが決まります。",
                },
            },
            {
                title = "ワイルドカード",
                items = {
                    "各局には2枚のワイルドカードがあります。クラシックの単局では級が2に固定されます。",
                    "現在の級の数字札は強札で、ジョーカーの次に強い扱いです。",
                    "現在の級のハート2枚はスーパー・ワイルドになり、ジョーカー以外の任意の札の代わりとして順子や爆弾を作れます。",
                },
            },
            {
                title = "基本の役",
                items = {
                    "シングル、ペア、スリーカード。",
                    "フルハウス: スリーカード + ペア。",
                    "ストレート: 連続する5枚ちょうど。",
                    "ダブルスリー: 連続する3枚が2組。",
                    "連続ペア: 連続するペアが3組。",
                },
            },
            {
                title = "爆弾",
                items = {
                    "最強爆弾: ジョーカー4枚。",
                    "スーパー爆弾: 6枚、7枚、8枚の同ランク。",
                    "ストレートフラッシュ: 同スートの連番5枚。通常爆弾のうち5枚以下を上回ります。",
                    "通常爆弾: 4枚または5枚の同ランク。",
                },
            },
            {
                title = "勝敗と献貢",
                items = {
                    "順位は上がり切った順で決まります。",
                    "昇級モードでは、最終順位に応じてチームが1〜3級進みます。",
                    "献貢: 最後に上がった人、または負け側2人が自分の最大札を勝者に渡し、勝者は任意の札を返します。",
                    "抗貢: 負け側が大ジョーカー2枚を持っている場合、献貢と返貢は行われません。",
                },
            },
        },
        hint = "ドラッグするかマウスホイールでスクロールしてください。",
    },
    ["ko-KR"] = {
        title = "게임 소개",
        intro = "여기서는 관단의 핵심 내용을 한 페이지로 소개합니다. 드래그하거나 마우스 휠로 스크롤하세요.",
        sections = {
            {
                title = "팀플레이와 승급",
                items = {
                    "4명이 대결하며, 마주 보는 상대가 고정된 팀이 됩니다.",
                    "표준 덱 2벌을 사용하며 조커는 4장입니다.",
                    "목표는 손패를 빨리 비우고 팀의 승급을 돕는 것입니다.",
                    "승급 모드에서는 2부터 A까지 진행되며, 현재 레벨이 특별한 카드의 기준이 됩니다.",
                },
            },
            {
                title = "와일드 카드",
                items = {
                    "매 판마다 와일드 카드가 2장 생기며, 클래식 단판에서는 레벨이 2로 고정됩니다.",
                    "현재 레벨의 숫자 카드는 강한 카드이며 조커 다음으로 높습니다.",
                    "현재 레벨의 하트 2장은 슈퍼 와일드가 되어 조커를 제외한 어떤 카드의 자리도 대신해 스트레이트나 봄을 만들 수 있습니다.",
                },
            },
            {
                title = "기본 조합",
                items = {
                    "싱글, 페어, 트리플.",
                    "풀하우스: 쓰리카드 + 페어.",
                    "스트레이트: 연속된 5장 정확히.",
                    "더블 트리플: 연속된 트리플 2세트.",
                    "연속 페어: 연속된 페어 3세트.",
                },
            },
            {
                title = "봄",
                items = {
                    "최강 봄: 조커 4장.",
                    "슈퍼 봄: 같은 숫자 6장, 7장, 8장.",
                    "스트레이트 플러시: 같은 무늬의 연속 5장으로, 5장 이하의 일반 봄을 이깁니다.",
                    "일반 봄: 같은 숫자 4장 또는 5장.",
                },
            },
            {
                title = "승패와 공물",
                items = {
                    "순위는 먼저 나간 순서로 정해집니다.",
                    "승급 모드에서는 최종 순위에 따라 팀이 1~3단계 전진합니다.",
                    "공물: 마지막으로 나간 사람, 또는 지는 쪽 둘이 가장 큰 카드를 승자에게 주고 승자는 아무 카드나 돌려줍니다.",
                    "항공: 지는 쪽이 큰 조커 2장을 가지고 있으면 공물과 반환이 생략됩니다.",
                },
            },
        },
        hint = "드래그하거나 마우스 휠로 스크롤하세요.",
    },
    ["de-DE"] = {
        title = "Spielübersicht",
        intro = "Hier ist eine einseitige Übersicht zu Guandan. Ziehen oder das Mausrad benutzen, um zu scrollen.",
        sections = {
            {
                title = "Teamspiel Und Aufstieg",
                items = {
                    "Vier Spieler, mit festen Partnern gegenüber am Tisch.",
                    "Zwei Standarddecks mit insgesamt 4 Jokern.",
                    "Ziel ist es, die Hand leer zu spielen und das Team voranzubringen.",
                    "Im Level-Modus geht es von 2 bis A; das aktuelle Level bestimmt, welche Karten besonders sind.",
                },
            },
            {
                title = "Die Wildcards",
                items = {
                    "Jede Runde hat zwei Wildcards; im klassischen Einzelmodus ist das Level auf 2 festgelegt.",
                    "Karten des aktuellen Levels sind stark und nur von Jokern übertroffen.",
                    "Die beiden Herzen des Levels sind Super-Wildcards und können jede Nicht-Joker-Karte ersetzen, um Straßen oder Bomben zu bilden.",
                },
            },
            {
                title = "Kombinationen",
                items = {
                    "Einzelkarte, Paar oder Drilling.",
                    "Full House: Drilling + Paar.",
                    "Straße: genau 5 aufeinanderfolgende Einzelkarten.",
                    "Doppel-Drilling: zwei aufeinanderfolgende Drillinge.",
                    "Folgepaare: drei aufeinanderfolgende Paare.",
                },
            },
            {
                title = "Bomben",
                items = {
                    "Ultimative Bombe: vier Joker.",
                    "Superbombe: sechs, sieben oder acht Karten gleichen Rangs.",
                    "Straight Flush: fünf Karten in Folge, gleiche Farbe; schlägt normale Bomben mit fünf oder weniger Karten.",
                    "Normale Bombe: vier oder fünf Karten gleichen Rangs.",
                },
            },
            {
                title = "Sieg Und Tribut",
                items = {
                    "Die Reihenfolge entscheidet über die Platzierung.",
                    "Im Level-Modus rückt das Team je nach Endplatzierung um 1 bis 3 Level vor.",
                    "Tribut: der letzte Spieler oder beide Verlierer geben ihre höchste Karte an die Gewinner, die dafür irgendeine Karte zurückgeben.",
                    "Gegentribut: Hat die Verliererseite zwei große Joker, wird Tribut übersprungen.",
                },
            },
        },
        hint = "Ziehen oder das Mausrad benutzen, um zu scrollen.",
    },
    ["fr-FR"] = {
        title = "Présentation du jeu",
        intro = "Voici un aperçu de Guandan sur une seule page. Faites glisser ou utilisez la molette pour faire défiler.",
        sections = {
            {
                title = "Équipe Et Progression",
                items = {
                    "4 joueurs, avec des partenaires fixes en face de la table.",
                    "Deux jeux standards, avec 4 jokers.",
                    "Le but est de vider sa main et d'aider son équipe à progresser.",
                    "Le mode niveau va de 2 à A ; le niveau courant détermine quelles cartes sont spéciales.",
                },
            },
            {
                title = "Les Cartes Spéciales",
                items = {
                    "Chaque donne contient deux cartes spéciales ; en mode classique, le niveau est fixé à 2.",
                    "Les cartes du niveau courant sont fortes, juste en dessous des jokers.",
                    "Les deux cœurs du niveau sont des super cartes spéciales et peuvent remplacer n'importe quelle carte hors joker pour faire des suites ou des bombes.",
                },
            },
            {
                title = "Combinaisons",
                items = {
                    "Carte seule, paire ou brelan.",
                    "Full : brelan + paire.",
                    "Suite : exactement 5 cartes consécutives.",
                    "Double brelan : deux brelans consécutifs.",
                    "Paires consécutives : trois paires consécutives.",
                },
            },
            {
                title = "Bombes",
                items = {
                    "Bombe ultime : quatre jokers.",
                    "Super bombe : six, sept ou huit cartes de même rang.",
                    "Quinte flush : cinq cartes d'affilée, même couleur ; bat les bombes normales de cinq cartes ou moins.",
                    "Bombe normale : quatre ou cinq cartes de même rang.",
                },
            },
            {
                title = "Victoire Et Tribut",
                items = {
                    "Le classement dépend de l'ordre de sortie.",
                    "En mode niveau, l'équipe avance de 1 à 3 niveaux selon le classement final.",
                    "Tribut : le dernier sortant, ou les deux perdants, donnent leur plus forte carte aux gagnants, qui rendent ensuite n'importe quelle carte.",
                    "Contre-tribut : si le camp perdant possède deux grands jokers, le tribut est annulé.",
                },
            },
        },
        hint = "Faites glisser ou utilisez la molette pour faire défiler.",
    },
    ["es-ES"] = {
        title = "Introducción al juego",
        intro = "Aquí tienes una vista general de Guandan en una sola página. Arrastra o usa la rueda del ratón para desplazarte.",
        sections = {
            {
                title = "Equipo Y Progreso",
                items = {
                    "4 jugadores, con parejas fijas frente a la mesa.",
                    "Dos barajas estándar, con 4 comodines.",
                    "El objetivo es vaciar la mano y ayudar al equipo a avanzar.",
                    "El modo de nivel va de 2 a A; el nivel actual determina qué cartas son especiales.",
                },
            },
            {
                title = "Las Cartas Especiales",
                items = {
                    "Cada mano tiene dos cartas especiales; en el modo clásico de una sola ronda el nivel queda fijo en 2.",
                    "Las cartas del nivel actual son fuertes, solo por debajo de los comodines.",
                    "Los dos corazones del nivel son super especiales y pueden reemplazar cualquier carta que no sea comodín para formar escaleras o bombas.",
                },
            },
            {
                title = "Combinaciones",
                items = {
                    "Carta sola, pareja o trío.",
                    "Full house: trío + pareja.",
                    "Escalera: exactamente 5 cartas consecutivas.",
                    "Doble trío: dos tríos consecutivos.",
                    "Parejas consecutivas: tres parejas consecutivas.",
                },
            },
            {
                title = "Bombas",
                items = {
                    "Bomba máxima: cuatro comodines.",
                    "Superbomba: seis, siete u ocho cartas del mismo valor.",
                    "Escalera de color: cinco cartas seguidas del mismo palo; supera bombas normales de cinco cartas o menos.",
                    "Bomba normal: cuatro o cinco cartas del mismo valor.",
                },
            },
            {
                title = "Victoria Y Tributo",
                items = {
                    "La clasificación depende del orden en que se vacía la mano.",
                    "En modo de nivel, el equipo avanza de 1 a 3 niveles según el orden final.",
                    "Tributo: el último en terminar, o los dos perdedores, entregan su carta más alta a los ganadores, que luego devuelven cualquier carta.",
                    "Contra-tributo: si el lado perdedor tiene dos comodines grandes, se omite el tributo.",
                },
            },
        },
        hint = "Arrastra o usa la rueda del ratón para desplazarte.",
    },
    ["ru-RU"] = {
        title = "Обзор игры",
        intro = "Ниже дан краткий обзор Guandan на одной странице. Перетаскивайте или прокручивайте колесом мыши.",
        sections = {
            {
                title = "Команда И Повышение",
                items = {
                    "4 игрока, с固定ными партнёрами напротив за столом.",
                    "Две стандартные колоды, включая 4 джокера.",
                    "Цель - как можно быстрее избавиться от карт и помочь команде повысить уровень.",
                    "В режиме уровней игра идёт от 2 до A; текущий уровень определяет особые карты.",
                },
            },
            {
                title = "Дикие Карты",
                items = {
                    "В каждой сдаче есть две дикие карты; в классическом одиночном режиме уровень фиксирован на 2.",
                    "Карты текущего уровня сильные и уступают только джокерам.",
                    "Две червовые карты текущего уровня становятся супердикими и могут заменить любую карту, кроме джокера, чтобы собрать стрит или бомбу.",
                },
            },
            {
                title = "Комбинации",
                items = {
                    "Одиночная, пара или тройка.",
                    "Фулл-хаус: тройка + пара.",
                    "Стрит: ровно 5 подряд идущих одиночных карт.",
                    "Двойная тройка: две подряд идущие тройки.",
                    "Последовательные пары: три пары подряд.",
                },
            },
            {
                title = "Бомбы",
                items = {
                    "Лучшая бомба: 4 джокера.",
                    "Супербомба: 6, 7 или 8 карт одного ранга.",
                    "Стрит-флеш: 5 карт подряд одной масти; бьёт обычные бомбы из пяти карт и меньше.",
                    "Обычная бомба: 4 или 5 карт одного ранга.",
                },
            },
            {
                title = "Победа И Дань",
                items = {
                    "Места определяются по порядку выхода из игры.",
                    "В режиме уровней команда продвигается на 1-3 уровня в зависимости от итогового порядка.",
                    "Дань: последний, либо оба проигравших, передают свою старшую карту победителям, а те возвращают любую карту.",
                    "Анти-дань: если у проигравшей стороны есть два больших джокера, дань отменяется.",
                },
            },
        },
        hint = "Перетаскивайте или используйте колесо мыши для прокрутки.",
    },
    ["pt-BR"] = {
        title = "Introdução ao jogo",
        intro = "Aqui está uma visão geral de Guandan em uma única página. Arraste ou use a roda do mouse para rolar.",
        sections = {
            {
                title = "Equipe E Progressão",
                items = {
                    "4 jogadores, com parceiros fixos em lados opostos da mesa.",
                    "Dois baralhos padrão, incluindo 4 coringas.",
                    "O objetivo é esvaziar a mão e ajudar sua equipe a avançar.",
                    "O modo de nível vai de 2 até A; o nível atual define quais cartas são especiais.",
                },
            },
            {
                title = "Cartas Especiais",
                items = {
                    "Cada rodada tem duas cartas especiais; no modo clássico de partida única o nível fica fixo em 2.",
                    "As cartas do nível atual são fortes, ficando atrás apenas dos coringas.",
                    "Os dois copas do nível viram super especiais e podem substituir qualquer carta que não seja coringa para montar sequências ou bombas.",
                },
            },
            {
                title = "Combinações",
                items = {
                    "Carta única, dupla ou trio.",
                    "Full house: trio + dupla.",
                    "Sequência: exatamente 5 cartas consecutivas.",
                    "Duplo trio: dois trios consecutivos.",
                    "Pares consecutivos: três pares consecutivos.",
                },
            },
            {
                title = "Bombas",
                items = {
                    "Bomba máxima: quatro coringas.",
                    "Super bomba: seis, sete ou oito cartas do mesmo valor.",
                    "Straight flush: cinco cartas em sequência do mesmo naipe; vence bombas normais de cinco cartas ou menos.",
                    "Bomba normal: quatro ou cinco cartas do mesmo valor.",
                },
            },
            {
                title = "Vitória E Tributo",
                items = {
                    "A classificação é decidida pela ordem de saída.",
                    "No modo de nível, a equipe avança de 1 a 3 níveis conforme a ordem final.",
                    "Tributo: o último a terminar, ou os dois perdedores, entregam sua carta mais alta aos vencedores, que depois devolvem qualquer carta.",
                    "Contra-tributo: se o lado perdedor tiver dois coringas grandes, o tributo é cancelado.",
                },
            },
        },
        hint = "Arraste ou use a roda do mouse para rolar.",
    },
    ["it-IT"] = {
        title = "Introduzione al gioco",
        intro = "Ecco una panoramica di Guandan in una sola pagina. Trascina o usa la rotellina del mouse per scorrere.",
        sections = {
            {
                title = "Squadra E Progressione",
                items = {
                    "4 giocatori, con partner fissi davanti al tavolo.",
                    "Due mazzi standard, con 4 jolly.",
                    "L'obiettivo è svuotare la mano e aiutare la squadra a salire di livello.",
                    "La modalità livello va dal 2 all'Asso; il livello corrente determina quali carte sono speciali.",
                },
            },
            {
                title = "Le Carte Speciali",
                items = {
                    "Ogni mano ha due carte speciali; nella modalità classica a partita singola il livello è fissato a 2.",
                    "Le carte del livello corrente sono forti, subito sotto i jolly.",
                    "I due cuori del livello diventano super speciali e possono sostituire qualsiasi carta non jolly per creare scale o bombe.",
                },
            },
            {
                title = "Combinazioni",
                items = {
                    "Carta singola, coppia o tris.",
                    "Full house: tris + coppia.",
                    "Scala: esattamente 5 carte consecutive.",
                    "Doppio tris: due tris consecutivi.",
                    "Coppie consecutive: tre coppie consecutive.",
                },
            },
            {
                title = "Bombe",
                items = {
                    "Bomba massima: quattro jolly.",
                    "Super bomba: sei, sette o otto carte dello stesso valore.",
                    "Scala colore: cinque carte consecutive dello stesso seme; batte le bombe normali di cinque carte o meno.",
                    "Bomba normale: quattro o cinque carte dello stesso valore.",
                },
            },
            {
                title = "Vittoria E Tributo",
                items = {
                    "L'ordine di uscita determina la classifica.",
                    "Nella modalità livello, la squadra avanza da 1 a 3 livelli in base all'ordine finale.",
                    "Tributo: l'ultimo a finire, o entrambi i perdenti, consegnano la loro carta più alta ai vincitori, che poi restituiscono qualsiasi carta.",
                    "Contro-tributo: se il lato perdente ha due jolly grandi, il tributo viene annullato.",
                },
            },
        },
        hint = "Trascina o usa la rotellina del mouse per scorrere.",
    },
    ["pl-PL"] = {
        title = "Wprowadzenie do gry",
        intro = "Oto jednostronicowy opis Guandan. Przeciągnij lub użyj kółka myszy, aby przewijać.",
        sections = {
            {
                title = "Drużyna I Awans",
                items = {
                    "4 graczy, z ustalonymi partnerami po drugiej stronie stołu.",
                    "Dwie standardowe talie, w tym 4 jokery.",
                    "Celem jest jak najszybsze pozbycie się kart i pomoc drużynie w awansie.",
                    "W trybie poziomów gra toczy się od 2 do A; bieżący poziom określa karty specjalne.",
                },
            },
            {
                title = "Karty Specjalne",
                items = {
                    "Każde rozdanie ma dwie karty specjalne; w klasycznej grze jednorundowej poziom jest stały i wynosi 2.",
                    "Karty bieżącego poziomu są mocne, ustępując tylko jokerom.",
                    "Dwa kiery bieżącego poziomu są super specjalne i mogą zastąpić dowolną kartę inną niż joker, aby zbudować strit lub bombę.",
                },
            },
            {
                title = "Układy",
                items = {
                    "Pojedyncza karta, para lub trójka.",
                    "Ful: trójka + para.",
                    "Strit: dokładnie 5 kolejnych pojedynczych kart.",
                    "Podwójna trójka: dwie kolejne trójki.",
                    "Kolejne pary: trzy kolejne pary.",
                },
            },
            {
                title = "Bomby",
                items = {
                    "Najmocniejsza bomba: cztery jokery.",
                    "Super bomba: sześć, siedem lub osiem kart tego samego rankingu.",
                    "Poker: pięć kart pod rząd w tym samym kolorze; bije zwykłe bomby liczące pięć kart lub mniej.",
                    "Zwykła bomba: cztery lub pięć kart tego samego rankingu.",
                },
            },
            {
                title = "Wygrana I Danina",
                items = {
                    "O kolejności decyduje kolejność wyjścia z gry.",
                    "W trybie poziomów drużyna awansuje o 1 do 3 poziomów zależnie od końcowej kolejności.",
                    "Danina: ostatni gracz, albo obaj przegrani, oddają najwyższą kartę zwycięzcom, a zwycięzcy zwracają dowolną kartę.",
                    "Anty-danina: jeśli przegrana strona ma dwa duże jokery, danina jest pomijana.",
                },
            },
        },
        hint = "Przeciągnij lub użyj kółka myszy, aby przewijać.",
    },
}

local FALLBACKS = {
    ["zh"] = "zh-CN",
    ["zh-cn"] = "zh-CN",
    ["zh-tw"] = "zh-TW",
    ["zh-hk"] = "zh-TW",
    ["zh-mo"] = "zh-TW",
    ["en"] = "en-US",
    ["ja"] = "ja-JP",
    ["ko"] = "ko-KR",
    ["de"] = "de-DE",
    ["fr"] = "fr-FR",
    ["es"] = "es-ES",
    ["ru"] = "ru-RU",
    ["pt"] = "pt-BR",
    ["it"] = "it-IT",
    ["pl"] = "pl-PL",
}

local function normalizeLocale(locale)
    local code = tostring(locale or ""):gsub("_", "-")
    if OverviewTexts[code] then
        return code
    end

    local lower = code:lower()
    if FALLBACKS[lower] then
        return FALLBACKS[lower]
    end

    if lower:sub(1, 2) == "zh" then
        return "zh-CN"
    end

    return "en-US"
end

local function getOverviewPage(locale)
    return OverviewTexts[normalizeLocale(locale)] or OverviewTexts["en-US"]
end

return {
    get = getOverviewPage,
}
