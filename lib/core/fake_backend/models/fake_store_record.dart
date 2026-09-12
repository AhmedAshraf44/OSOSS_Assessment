class FakeStoreRecord {
  const FakeStoreRecord({required this.id, required this.name});

  final int id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
