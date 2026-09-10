import 'package:inventory_count_app/core/error/exceptions.dart';
import 'package:inventory_count_app/features/stores/domain/entities/store.dart';

class StoreModel {
  const StoreModel({required this.id, required this.name});

  final int id;
  final String name;

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    try {
      return StoreModel(
        id: json['id'] as int,
        name: json['name'] as String,
      );
    } on TypeError {
      throw const MalformedResponseException();
    }
  }

  Store toEntity() => Store(id: id, name: name);
}
