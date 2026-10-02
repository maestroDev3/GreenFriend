import '../domain/tips.dart';

/// Curated care tips bundled with the app (English and German), general
/// ones and ones for genera of the plant database.
final List<CareTip> bundledTips = List.unmodifiable([
  CareTip(
    id: 'check-soil',
    texts: const {
      'en': 'Check before you water: push a finger 2–3 cm into the soil. If it still feels moist, wait a few days.',
      'de': 'Erst fühlen, dann gießen: Steck einen Finger 2–3 cm tief in die Erde. Ist sie noch feucht, warte ein paar Tage.',
    },
  ),
  CareTip(
    id: 'room-temperature-water',
    texts: const {
      'en': 'Use water at room temperature – cold water can shock the roots of tropical plants.',
      'de': 'Gieß mit zimmerwarmem Wasser – kaltes Wasser schockt die Wurzeln tropischer Pflanzen.',
    },
  ),
  CareTip(
    id: 'drainage',
    texts: const {
      'en': 'Pots need drainage holes. Standing water in the outer pot is the most common cause of root rot.',
      'de': 'Töpfe brauchen ein Abzugsloch. Stehendes Wasser im Übertopf ist die häufigste Ursache für Wurzelfäule.',
    },
  ),
  CareTip(
    id: 'water-thoroughly',
    texts: const {
      'en': 'Water thoroughly until water runs out at the bottom, then empty the saucer after 15 minutes.',
      'de': 'Gieß durchdringend, bis unten Wasser herausläuft, und leer den Untersetzer nach 15 Minuten aus.',
    },
  ),
  CareTip(
    id: 'winter-slow',
    texts: const {
      'en': 'Most houseplants grow slowly in winter: water less and skip the fertilizer until spring.',
      'de': 'Die meisten Zimmerpflanzen wachsen im Winter kaum: weniger gießen und bis zum Frühjahr nicht düngen.',
    },
  ),
  CareTip(
    id: 'dust',
    texts: const {
      'en': 'Dust on leaves blocks light. Wipe large leaves with a damp cloth or give the plant a lukewarm shower.',
      'de': 'Staub auf den Blättern schluckt Licht. Wisch große Blätter feucht ab oder gönn der Pflanze eine lauwarme Dusche.',
    },
  ),
  CareTip(
    id: 'yellow-leaves',
    texts: const {
      'en': 'Yellow lower leaves often mean too much water; crispy brown edges often mean too little water or dry air.',
      'de': 'Gelbe untere Blätter deuten oft auf zu viel Wasser hin, trockene braune Ränder auf zu wenig Wasser oder trockene Luft.',
    },
  ),
  CareTip(
    id: 'turn-plants',
    texts: const {
      'en': 'Turn your plants a little every week or two, so they grow evenly instead of leaning towards the window.',
      'de': 'Dreh deine Pflanzen alle ein, zwei Wochen ein Stück, damit sie gleichmäßig wachsen und sich nicht zum Fenster neigen.',
    },
  ),
  CareTip(
    id: 'radiators',
    texts: const {
      'en': 'Keep plants away from radiators and cold draughts – sudden temperature changes stress them.',
      'de': 'Halte Pflanzen von Heizkörpern und kalter Zugluft fern – plötzliche Temperaturwechsel stressen sie.',
    },
  ),
  CareTip(
    id: 'repot-spring',
    texts: const {
      'en': 'Repot in spring and choose a pot only 2–3 cm wider than the old one.',
      'de': 'Topf im Frühjahr um und nimm einen Topf, der nur 2–3 cm größer ist als der alte.',
    },
  ),
  CareTip(
    id: 'fertilize-moist',
    texts: const {
      'en':
          'Only fertilize moist soil – fertilizer on dry roots can burn them.',
      'de': 'Dünge nur feuchte Erde – Dünger auf trockenen Wurzeln kann sie verbrennen.',
    },
  ),
  CareTip(
    id: 'group-plants',
    texts: const {
      'en': 'Group plants that love humidity – together they raise the humidity around each other.',
      'de': 'Stell Pflanzen, die hohe Luftfeuchtigkeit mögen, zusammen – gemeinsam erhöhen sie die Feuchtigkeit.',
    },
  ),
  CareTip(
    id: 'leggy-growth',
    texts: const {
      'en': 'Long, thin shoots with big gaps between the leaves mean the plant needs more light.',
      'de': 'Lange, dünne Triebe mit großen Abständen zwischen den Blättern zeigen: Die Pflanze braucht mehr Licht.',
    },
  ),
  CareTip(
    id: 'check-pests',
    texts: const {
      'en': 'Look under the leaves now and then – pests like spider mites are easiest to fight when caught early.',
      'de': 'Schau ab und zu unter die Blätter – Schädlinge wie Spinnmilben lassen sich früh erkannt am leichtesten bekämpfen.',
    },
  ),
  CareTip(
    id: 'fungus-gnats',
    texts: const {
      'en': 'Fungus gnats love wet soil. Let the top layer dry out between waterings to get rid of them.',
      'de': 'Trauermücken lieben nasse Erde. Lass die oberste Schicht zwischen dem Gießen abtrocknen, dann verschwinden sie.',
    },
  ),
  CareTip(
    id: 'quarantine',
    texts: const {
      'en': 'Keep new plants away from the others for two weeks to make sure they bring no pests.',
      'de': 'Stell neue Pflanzen zwei Wochen lang getrennt auf, damit sie keine Schädlinge einschleppen.',
    },
  ),
  CareTip(
    id: 'midday-sun',
    texts: const {
      'en': 'Direct midday sun through glass can scorch leaves – a sheer curtain softens it.',
      'de': 'Direkte Mittagssonne hinter Glas kann Blätter verbrennen – eine helle Gardine mildert sie ab.',
    },
  ),
  CareTip(
    id: 'cold-windowsill',
    texts: const {
      'en': 'Window sills can get very cold on winter nights – move sensitive plants a little further into the room.',
      'de': 'Fensterbänke werden in Winternächten sehr kalt – rück empfindliche Pflanzen ein Stück ins Zimmer.',
    },
  ),
  CareTip(
    id: 'tidy-up',
    texts: const {
      'en': 'Remove dead leaves and faded flowers – it keeps plants tidy and prevents rot.',
      'de': 'Entferne welke Blätter und Blüten – das hält die Pflanze ordentlich und beugt Fäulnis vor.',
    },
  ),
  CareTip(
    id: 'soak-not-sip',
    texts: const {
      'en':
          'Most plants prefer a good soak less often to a few sips every day.',
      'de': 'Die meisten Pflanzen mögen lieber seltener, dafür kräftig gegossen werden als täglich ein paar Schlucke.',
    },
  ),
  CareTip(
    id: 'flush-salts',
    texts: const {
      'en': 'Brown leaf tips can come from salts in tap water – flush the soil with plenty of water now and then.',
      'de': 'Braune Blattspitzen können von Salzen im Leitungswasser kommen – spül die Erde ab und zu mit viel Wasser durch.',
    },
  ),
  CareTip(
    id: 'holiday',
    texts: const {
      'en': 'Before a holiday, water well and move plants away from the window; watering spikes help on longer trips.',
      'de': 'Vor dem Urlaub gut gießen und die Pflanzen vom Fenster wegrücken; bei längeren Reisen helfen Bewässerungskegel.',
    },
  ),
  CareTip(
    id: 'root-rot',
    texts: const {
      'en': 'A plant that wilts although the soil is moist may have root rot – healthy roots are firm and light.',
      'de': 'Welkt eine Pflanze trotz feuchter Erde, kann Wurzelfäule dahinterstecken – gesunde Wurzeln sind fest und hell.',
    },
  ),
  CareTip(
    id: 'terracotta',
    texts: const {
      'en': 'Terracotta pots dry out faster than plastic ones – great for succulents, less so for thirsty plants.',
      'de': 'Tontöpfe trocknen schneller aus als Plastiktöpfe – ideal für Sukkulenten, weniger für durstige Pflanzen.',
    },
  ),
  CareTip(
    id: 'monstera-leaves',
    texts: const {
      'en': 'Wipe the big leaves of your Monstera with a damp cloth now and then and give its aerial roots a moss pole to climb.',
      'de': 'Wisch die großen Blätter deiner Monstera ab und zu feucht ab und gib ihren Luftwurzeln einen Moosstab zum Klettern.',
    },
    genus: 'Monstera',
  ),
  CareTip(
    id: 'ficus-stay',
    texts: const {
      'en': 'A Ficus hates being moved: a new spot or a draught often makes it drop leaves. Find a bright place and keep it there.',
      'de': 'Ein Ficus mag keinen Umzug: Ein neuer Platz oder Zugluft lässt ihn oft Blätter verlieren. Such einen hellen Ort und bleib dabei.',
    },
    genus: 'Ficus',
  ),
  CareTip(
    id: 'dracaena-water',
    texts: const {
      'en': 'Dracaenas are sensitive to salts in tap water – brown leaf tips are a sign. Rainwater or filtered water helps.',
      'de': 'Drachenbäume reagieren empfindlich auf Salze im Leitungswasser – braune Blattspitzen sind ein Zeichen. Regenwasser oder gefiltertes Wasser hilft.',
    },
    genus: 'Dracaena',
  ),
  CareTip(
    id: 'orchid-dip',
    texts: const {
      'en': 'Water your orchid by soaking the pot for ten minutes, then let it drain well – never leave water in the outer pot.',
      'de': 'Gieß deine Orchidee, indem du den Topf zehn Minuten tauchst und gut abtropfen lässt – nie Wasser im Übertopf stehen lassen.',
    },
    genus: 'Phalaenopsis',
  ),
  CareTip(
    id: 'peace-lily-droop',
    texts: const {
      'en': 'A peace lily droops visibly when it is thirsty and perks up within hours after watering – a handy reminder.',
      'de': 'Ein Einblatt lässt die Blätter hängen, wenn es Durst hat, und richtet sich nach dem Gießen in wenigen Stunden wieder auf.',
    },
    genus: 'Spathiphyllum',
  ),
  CareTip(
    id: 'zz-dry',
    texts: const {
      'en': 'The ZZ plant stores water in its thick stems. Water only when the soil is completely dry – too much water is its biggest danger.',
      'de': 'Die Zamioculcas speichert Wasser in ihren dicken Stielen. Gieß erst, wenn die Erde ganz trocken ist – zu viel Wasser ist ihre größte Gefahr.',
    },
    genus: 'Zamioculcas',
  ),
  CareTip(
    id: 'pothos-trim',
    texts: const {
      'en': 'Your pothos gets bushier when you trim long vines – the cuttings root easily in a glass of water.',
      'de': 'Deine Efeutute wird buschiger, wenn du lange Triebe kürzt – die Stecklinge bewurzeln sich leicht im Wasserglas.',
    },
    genus: 'Epipremnum',
  ),
  CareTip(
    id: 'aloe-dry',
    texts: const {
      'en': 'Aloe needs very little water: soak it, then wait until the soil is fully dry. In winter, once a month is often enough.',
      'de': 'Aloe braucht sehr wenig Wasser: kräftig gießen, dann warten, bis die Erde ganz trocken ist. Im Winter reicht oft einmal im Monat.',
    },
    genus: 'Aloe',
  ),
  CareTip(
    id: 'calathea-humidity',
    texts: const {
      'en': 'Calatheas love humidity and soft water; curled or crispy leaves mean the air or the water is too dry or too hard.',
      'de': 'Calatheas lieben hohe Luftfeuchtigkeit und weiches Wasser; eingerollte oder trockene Blätter heißen: Luft zu trocken oder Wasser zu hart.',
    },
    genus: 'Goeppertia',
  ),
  CareTip(
    id: 'maranta-night',
    texts: const {
      'en': 'Prayer plants fold up their leaves at night – that is normal. Keep the soil slightly moist and out of direct sun.',
      'de': 'Pfeilwurz faltet nachts die Blätter zusammen – das ist normal. Halte die Erde leicht feucht und die Pflanze aus der direkten Sonne.',
    },
    genus: 'Maranta',
  ),
  CareTip(
    id: 'pilea-turn',
    texts: const {
      'en': 'Turn your Pilea a quarter turn every week so it grows straight instead of leaning towards the light.',
      'de': 'Dreh deine Ufopflanze jede Woche eine Vierteldrehung, damit sie gerade wächst und sich nicht zum Licht neigt.',
    },
    genus: 'Pilea',
  ),
  CareTip(
    id: 'basil-pinch',
    texts: const {
      'en': 'Pinch basil just above a pair of leaves – it branches out and stays bushy. Remove flower buds to keep the leaves tasty.',
      'de': 'Knips Basilikum direkt über einem Blattpaar ab – so verzweigt es sich und bleibt buschig. Blütenansätze entfernen, dann bleiben die Blätter aromatisch.',
    },
    genus: 'Ocimum',
  ),
  CareTip(
    id: 'lavender-cut',
    texts: const {
      'en': 'Lavender loves sun and dry feet. Cut it back by a third after flowering, but never into the old wood.',
      'de': 'Lavendel liebt Sonne und trockene Füße. Schneid ihn nach der Blüte um ein Drittel zurück, aber nie ins alte Holz.',
    },
    genus: 'Lavandula',
  ),
  CareTip(
    id: 'olive-winter',
    texts: const {
      'en': 'Olive trees need full sun in summer and a bright, cool place in winter (about 5–10 °C).',
      'de': 'Olivenbäume brauchen im Sommer volle Sonne und im Winter einen hellen, kühlen Platz (etwa 5–10 °C).',
    },
    genus: 'Olea',
  ),
  CareTip(
    id: 'geranium-deadhead',
    texts: const {
      'en': 'Remove faded geranium flowers regularly – the plant then puts its energy into new blooms instead of seeds.',
      'de': 'Entferne verblühte Geranienblüten regelmäßig – dann steckt die Pflanze ihre Kraft in neue Blüten statt in Samen.',
    },
    genus: 'Pelargonium',
  ),
  CareTip(
    id: 'citrus-feed',
    texts: const {
      'en': 'Citrus plants need regular feeding in summer and dislike wet feet. Yellow leaves with green veins hint at iron deficiency.',
      'de': 'Zitruspflanzen brauchen im Sommer regelmäßig Dünger und mögen keine nassen Füße. Gelbe Blätter mit grünen Adern deuten auf Eisenmangel hin.',
    },
    genus: 'Citrus',
  ),
  CareTip(
    id: 'christmas-cactus-buds',
    texts: const {
      'en': 'A Christmas cactus sets buds when autumn nights get cool and long – once buds appear, do not move it.',
      'de': 'Ein Weihnachtskaktus bildet Knospen, wenn die Herbstnächte kühl und lang werden – sobald Knospen da sind, nicht mehr umstellen.',
    },
    genus: 'Schlumbergera',
  ),
  CareTip(
    id: 'jade-dry',
    texts: const {
      'en': 'Jade plants are succulents: water thoroughly, then let the soil dry out. Red leaf edges show it gets plenty of sun.',
      'de': 'Der Geldbaum ist eine Sukkulente: kräftig gießen, dann die Erde abtrocknen lassen. Rote Blattränder zeigen, dass er viel Sonne bekommt.',
    },
    genus: 'Crassula',
  ),
  CareTip(
    id: 'juniper-outdoors',
    texts: const {
      'en': 'A juniper bonsai belongs outdoors all year – indoors it slowly declines. Protect its roots from hard frost.',
      'de': 'Ein Wacholder-Bonsai gehört das ganze Jahr nach draußen – drinnen geht er langsam ein. Schütz die Wurzeln vor starkem Frost.',
    },
    genus: 'Juniperus',
  ),
  CareTip(
    id: 'strelitzia-light',
    texts: const {
      'en': 'A bird of paradise needs lots of light and space; it often flowers only once it is a few years old and a little pot-bound.',
      'de': 'Eine Paradiesvogelblume braucht viel Licht und Platz; oft blüht sie erst, wenn sie ein paar Jahre alt ist und der Topf etwas eng wird.',
    },
    genus: 'Strelitzia',
  ),
  CareTip(
    id: 'mint-pot',
    texts: const {
      'en': 'Mint spreads fast – give it its own pot and cut it back regularly for fresh, tender shoots.',
      'de': 'Minze wuchert schnell – gib ihr einen eigenen Topf und schneid sie regelmäßig zurück, dann treibt sie frisch und zart aus.',
    },
    genus: 'Mentha',
  ),
  CareTip(
    id: 'fern-moist',
    texts: const {
      'en': 'Boston ferns need even moisture and humidity; never let the root ball dry out completely.',
      'de': 'Schwertfarne brauchen gleichmäßige Feuchtigkeit und Luftfeuchte; lass den Wurzelballen nie ganz austrocknen.',
    },
    genus: 'Nephrolepis',
  ),
  CareTip(
    id: 'hoya-spurs',
    texts: const {
      'en': 'Do not cut off the leafless spurs of a wax plant – new flowers appear on the same spurs every year.',
      'de': 'Schneid die blattlosen Kurztriebe der Wachsblume nicht ab – an ihnen erscheinen jedes Jahr neue Blüten.',
    },
    genus: 'Hoya',
  ),
  CareTip(
    id: 'kalanchoe-rebloom',
    texts: const {
      'en': 'A Kalanchoe flowers again after about six weeks of short days with less than ten hours of light.',
      'de': 'Eine Kalanchoe blüht wieder, wenn sie etwa sechs Wochen lang kurze Tage mit weniger als zehn Stunden Licht bekommt.',
    },
    genus: 'Kalanchoe',
  ),
]);

/// The bundled tips as a [TipCatalog].
class BundledTipCatalog implements TipCatalog {
  @override
  List<CareTip> get all => bundledTips;
}
