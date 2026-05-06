class Review {
  int? id;
  int? userId;
  String? userName;
  String? userEmail;
  int rating; // 1 a 5
  String? comment;
  DateTime? createdAt;

  Review({
    this.id,
    this.userId,
    this.userName,
    this.userEmail,
    this.rating = 5,
    this.comment,
    this.createdAt,
  });

  Review.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        userId = json['user_id'],
        userName = json['user_name'],
        userEmail = json['user_email'],
        rating = json['rating'] ?? 5,
        comment = json['comment'],
        createdAt = json['created_at'] != null
            ? (() {
                try {
                  return DateTime.parse(json['created_at']);
                } catch (e) {
                  return DateTime.now();
                }
              })()
            : DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

