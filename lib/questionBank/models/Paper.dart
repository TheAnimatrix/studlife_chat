
class DownloadPaper
{
  String id,fileName;
  bool downloaded;

  DownloadPaper({this.id,this.fileName,this.downloaded});

  @override
  String toString() {
    // TODO: implement toString
    return "$id $fileName";
  }
}