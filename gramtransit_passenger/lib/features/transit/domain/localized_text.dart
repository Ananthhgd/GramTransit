final class LocalizedText {
  final String english;
  final String? kannada;
  final String? malayalam;

  LocalizedText({required this.english, this.kannada, this.malayalam}) {
    if (english.trim().isEmpty) {
      throw ArgumentError('LocalizedText must have a non-empty english value.');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalizedText &&
          runtimeType == other.runtimeType &&
          english == other.english &&
          kannada == other.kannada &&
          malayalam == other.malayalam;

  @override
  int get hashCode => Object.hash(english, kannada, malayalam);

  @override
  String toString() => english;
}
