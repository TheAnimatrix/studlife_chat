

class DownloadHistory
{
  String id;

  String fileName;

  DownloadHistory({this.id,this.fileName});

  DownloadHistory.fromJson(Map<String,dynamic> json)
          : id = json['id'],
          fileName = json['fileName'];

    Map<String, dynamic> toJson() =>
    {
      'id': id,
      'fileName': fileName,
    };
}