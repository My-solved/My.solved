import 'package:html/dom.dart';

class Contest {
  final String venue;
  final String name;
  final String? url;
  final DateTime startTime;
  final DateTime endTime;

  const Contest({
    required this.venue,
    required this.name,
    required this.url,
    required this.startTime,
    required this.endTime,
  });

  factory Contest.fromElement(Element element) {
    String? url;
    try {
      url = element
          .getElementsByTagName('td')[1]
          .getElementsByTagName('a')[0]
          .attributes['href'];
    } catch (e) {
      url = null;
    }
    List<String> startTimeList = element
        .getElementsByTagName('td')[2]
        .text
        .toString()
        .replaceAll('년', '')
        .replaceAll('월', '')
        .replaceAll('일', '')
        .split(' ');
    DateTime startTime = DateTime.parse(
            "${startTimeList[0].padLeft(4, "0")}-${startTimeList[1].padLeft(2, "0")}-${startTimeList[2].padLeft(2, "0")}T${startTimeList[3].padLeft(2, "0")}:00+09:00")
        .toLocal();
    List<String> endTimeList = element
        .getElementsByTagName('td')[3]
        .text
        .toString()
        .replaceAll('년', '')
        .replaceAll('월', '')
        .replaceAll('일', '')
        .split(' ');
    DateTime endTime = DateTime.parse(
            "${endTimeList[0].padLeft(4, "0")}-${endTimeList[1].padLeft(2, "0")}-${endTimeList[2].padLeft(2, "0")}T${endTimeList[3].padLeft(2, "0")}:00+09:00")
        .toLocal();

    return Contest(
      venue: element.getElementsByTagName('td')[0].text,
      name: element.getElementsByTagName('td')[1].text,
      url: url,
      startTime: startTime,
      endTime: endTime,
    );
  }
}
