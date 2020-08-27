class PaperHistoryItem {
  String paperName;

  String dateCreated;

  String ownerEmail;

  PaperHistoryItem({this.paperName, this.dateCreated, this.ownerEmail});

  @override
  String toString() {
    return '$paperName $dateCreated $ownerEmail';
  }

  PaperHistoryItem.fromJson(Map<String, dynamic> json)
      : paperName = json['paperName'],
        dateCreated = json['dateCreated'],
        ownerEmail = json['ownerEmail'];

  Map<String, dynamic> toJson() => {
        'paperName': paperName,
        'dateCreated': dateCreated,
        'ownerEmail': ownerEmail
      };
}
