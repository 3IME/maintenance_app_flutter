// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ArticleAdapter extends TypeAdapter<Article> {
  @override
  final int typeId = 6;

  @override
  Article read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Article(
      category: fields[0] as String,
      codeArticle: fields[1] as String,
      stockInitial: fields[2] as int,
      stockMini: fields[3] as int,
      stockMaxi: fields[4] as int,
      pointCommande: fields[5] as int,
      prixUnitaire: fields[6] as double,
      commentaire: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Article obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.category)
      ..writeByte(1)
      ..write(obj.codeArticle)
      ..writeByte(2)
      ..write(obj.stockInitial)
      ..writeByte(3)
      ..write(obj.stockMini)
      ..writeByte(4)
      ..write(obj.stockMaxi)
      ..writeByte(5)
      ..write(obj.pointCommande)
      ..writeByte(6)
      ..write(obj.prixUnitaire)
      ..writeByte(7)
      ..write(obj.commentaire);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArticleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
