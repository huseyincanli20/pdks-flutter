class CafeteriaMenu {
  final String companyId;
  final DateTime date;
  final String soup;
  final String mainDish;
  final String sideDish;
  final String dessertOrSalad;
  final String drink;
  final int totalCalories;
  final String? vegetarianAlternative;
  final String? chefNote;
  final String updatedBy;
  final DateTime updatedAt;

  CafeteriaMenu({
    this.companyId = 'cmp_acme',
    required this.date,
    required this.soup,
    required this.mainDish,
    required this.sideDish,
    required this.dessertOrSalad,
    this.drink = 'Ayran / Su',
    this.totalCalories = 820,
    this.vegetarianAlternative,
    this.chefNote,
    this.updatedBy = 'Hasan Usta (Mutfak Şefi)',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  CafeteriaMenu copyWith({
    String? companyId,
    DateTime? date,
    String? soup,
    String? mainDish,
    String? sideDish,
    String? dessertOrSalad,
    String? drink,
    int? totalCalories,
    String? vegetarianAlternative,
    String? chefNote,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return CafeteriaMenu(
      companyId: companyId ?? this.companyId,
      date: date ?? this.date,
      soup: soup ?? this.soup,
      mainDish: mainDish ?? this.mainDish,
      sideDish: sideDish ?? this.sideDish,
      dessertOrSalad: dessertOrSalad ?? this.dessertOrSalad,
      drink: drink ?? this.drink,
      totalCalories: totalCalories ?? this.totalCalories,
      vegetarianAlternative: vegetarianAlternative ?? this.vegetarianAlternative,
      chefNote: chefNote ?? this.chefNote,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isCompleted => soup.trim().isNotEmpty && mainDish.trim().isNotEmpty;

  bool isSameDay(DateTime other) =>
      date.year == other.year && date.month == other.month && date.day == other.day;

  Map<String, dynamic> toJson() => {
    'companyId': companyId,
    'date': date.toIso8601String(),
    'soup': soup,
    'mainDish': mainDish,
    'sideDish': sideDish,
    'dessertOrSalad': dessertOrSalad,
    'drink': drink,
    'totalCalories': totalCalories,
    'vegetarianAlternative': vegetarianAlternative,
    'chefNote': chefNote,
    'updatedBy': updatedBy,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory CafeteriaMenu.fromJson(Map<String, dynamic> json) => CafeteriaMenu(
    companyId: json['companyId'] as String? ?? 'cmp_acme',
    date: DateTime.parse(json['date'] as String),
    soup: json['soup'] as String? ?? '',
    mainDish: json['mainDish'] as String? ?? '',
    sideDish: json['sideDish'] as String? ?? '',
    dessertOrSalad: json['dessertOrSalad'] as String? ?? '',
    drink: json['drink'] as String? ?? 'Ayran / Su',
    totalCalories: json['totalCalories'] as int? ?? 800,
    vegetarianAlternative: json['vegetarianAlternative'] as String?,
    chefNote: json['chefNote'] as String?,
    updatedBy: json['updatedBy'] as String? ?? 'Hasan Usta (Mutfak Şefi)',
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
  );
}
