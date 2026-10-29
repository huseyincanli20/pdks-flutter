class CafeteriaMenu {
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
}
