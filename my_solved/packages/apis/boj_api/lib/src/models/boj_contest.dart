import 'package:html/dom.dart';

class Contest {
  final String? venue;
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
    DateTime startTime = DateTime.fromMillisecondsSinceEpoch(
            int.parse(element
                    .getElementsByTagName('td')[2]
                    .getElementsByTagName('span')[0]
                    .attributes['data-timestamp']!) *
                1000,
            isUtc: true)
        .toLocal();

    DateTime endTime = DateTime.fromMillisecondsSinceEpoch(
            int.parse(element
                    .getElementsByTagName('td')[3]
                    .getElementsByTagName('span')[0]
                    .attributes['data-timestamp']!) *
                1000,
            isUtc: true)
        .toLocal();

    return Contest(
      venue: element.getElementsByTagName('td')[0].text,
      name: element.getElementsByTagName('td')[1].text,
      url: element
          .getElementsByTagName('td')[1]
          .getElementsByTagName('a')[0]
          .attributes['href'],
      startTime: startTime,
      endTime: endTime,
    );
  }
}
