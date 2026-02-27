import 'dart:math';

class NameGenerator {
  final Random rng;

  NameGenerator(this.rng);

  /// Cache para evitar nomes duplicados no mundo
  static final Set<String> _usedFullNames = {};

  static const List<String> firstNames = [
    'Akira','Elena','Marcus','Yuki','Sofia','Ravi','Luna','Kai','Aria','Davi',
    'Mia','Chen','Nora','Leo','Zara','Omar','Iris','Hugo','Maya','Erik',
    'Lina','Atlas','Vera','Theo','Jade','Ren','Cleo','Ivan','Rosa','Finn',
    'Abel','Diana','Samir','Hana','Viktor','Mei','Dante','Suri','Boris','Kira',
    'Rafael','Anya','Noah','Ayla','Lucas','Mila','Ezra','Yara','Anton','Leila',
    'Caio','Freya','Niko','Bianca','Tariq','Ivy','Jonas','Amara','Pavel','Zoe',
    'Mateo','Helena','Igor','Nina','Saul','Esme','Bruno','Aisha','Oscar','Keiko',
    'Thiago','Elis','Victor','Naomi','Felix','Ariel','Gustav','Lila','Ronan',
    'Malik','Alma','Soren','Priya','Julian','Isla','Kenji','Laura','Ethan',
    'Aya','Tomás','Selena','Andrei','Fatima','Oliver','Carmen','Jasper',
  ];

  static const List<String> lastNames = [
    'Silva','Santos','Costa','Ferreira','Ribeiro','Almeida',
    'Nakamura','Tanaka','Yamamoto','Hayashi',
    'Chen','Zhang','Liu',
    'Kim','Park','Choi',
    'Ivanov','Petrov','Volkov',
    'Johansson','Andersen','Bergman',
    'Rossi','Bianchi','Conti',
    'Patel','Singh','Mehta',
    'Nguyen','Tran',
    'Torres','Rivera','Gomez',
    'Dubois','Moreau',
  ];

  /// Gera nome completo único
  String generateUniqueFullName() {
    for (int i = 0; i < 20; i++) {
      final first = _pick(firstNames);
      final last = _pick(lastNames);
      final full = '$first $last';

      if (_usedFullNames.add(full)) {
        return full;
      }
    }

    // fallback extremo (mundo gigante)
    final forced =
        '${_pick(firstNames)} ${_pick(lastNames)}-${rng.nextInt(9999)}';
    _usedFullNames.add(forced);
    return forced;
  }

  /// Gera nome para criança herdando sobrenome
  String generateChildName({
    required String parentAName,
    required String parentBName,
  }) {
    final first = _pick(firstNames);
    final lastA = parentAName.split(' ').last;
    final lastB = parentBName.split(' ').last;

    // 70% herda do parentA, 30% do parentB
    final last = rng.nextDouble() < 0.7 ? lastA : lastB;
    final full = '$first $last';

    if (_usedFullNames.add(full)) return full;

    return '$first $last-${rng.nextInt(99)}';
  }

  /// Gera apenas primeiro nome (criaturas, bebês, etc)
  String generateFirstName() => _pick(firstNames);

  static String _pick(List<String> list) =>
      list[Random().nextInt(list.length)];
}