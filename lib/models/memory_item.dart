
class MemoryItem {

  final String category;
  final String content;
  final String importance;
  final DateTime createdAt;


  MemoryItem({

    required this.category,

    required this.content,

    required this.importance,

    required this.createdAt,

  });



  Map<String, dynamic> toJson() {

    return {

      "category": category,

      "content": content,

      "importance": importance,

      "createdAt":
          createdAt.toIso8601String(),

    };

  }





  factory MemoryItem.fromJson(
    Map<String, dynamic> json,
  ) {

    return MemoryItem(

      category:
          json["category"] ?? "general",


      content:
          json["content"] ?? "",


      importance:
          json["importance"] ?? "normal",


      createdAt:

          DateTime.tryParse(
            json["createdAt"] ?? "",
          ) ??

          DateTime.now(),

    );

  }

}