import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;

Widget titleHeader() {
  return CupertinoPageScaffold(
    child: Text(
      '문제',
      style: TextStyle(fontSize: 12, color: Color(0xff767676)),
    ),
  );
}

Widget titleContent(
    AsyncSnapshot<dom.Document> snapshot, BuildContext context) {
  return CupertinoPageScaffold(
    child: Container(
      padding: EdgeInsets.only(top: 10),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).barBackgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        padding: EdgeInsets.only(top: 10, right: 20, left: 20, bottom: 10),
        width: MediaQuery.of(context).size.width,
        child: Text(
          snapshot.data?.getElementById('problem_title')?.text ?? '',
          style: TextStyle(fontSize: 17),
        ),
      ),
    ),
  );
}

Widget descriptionHeader() {
  return CupertinoPageScaffold(
    child: Container(
      padding: EdgeInsets.only(top: 20),
      child: Text(
        '설명',
        style: TextStyle(fontSize: 12, color: Color(0xff767676)),
      ),
    ),
  );
}

Widget descriptionContent(
    AsyncSnapshot<dom.Document> snapshot, BuildContext context) {
  return CupertinoPageScaffold(
    child: Container(
      padding: EdgeInsets.only(top: 10),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).barBackgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        padding: EdgeInsets.only(top: 10, right: 10, left: 10, bottom: 10),
        width: MediaQuery.of(context).size.width,
        child: Html(
          data: snapshot.data?.getElementById('problem_description')?.innerHtml ??
              '',
          style: {
            "body": Style(
              fontSize: FontSize(14),
            ),
          },
        ),
        // child: Text(
        //   snapshot.data?.getElementById('problem_description')?.text ?? '',
        //   style: TextStyle(fontSize: 14),
        // ),
      ),
    ),
  );
}

Widget inputHeader() {
  return CupertinoPageScaffold(
    child: Container(
      padding: EdgeInsets.only(top: 20),
      child: Text(
        '입력',
        style: TextStyle(fontSize: 12, color: Color(0xff767676)),
      ),
    ),
  );
}

Widget inputContent(
    AsyncSnapshot<dom.Document> snapshot, BuildContext context) {
  return CupertinoPageScaffold(
    child: Container(
      padding: EdgeInsets.only(top: 10),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).barBackgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        padding: EdgeInsets.only(top: 10, right: 20, left: 20, bottom: 10),
        width: MediaQuery.of(context).size.width,
        child: Text(
          snapshot.data?.getElementById('problem_input')?.text ?? '',
          style: TextStyle(fontSize: 14),
        ),
      ),
    ),
  );
}

Widget outputHeader() {
  return CupertinoPageScaffold(
    child: Container(
      padding: EdgeInsets.only(top: 20),
      child: Text(
        '출력',
        style: TextStyle(fontSize: 12, color: Color(0xff767676)),
      ),
    ),
  );
}

Widget outputContent(
    AsyncSnapshot<dom.Document> snapshot, BuildContext context) {
  return CupertinoPageScaffold(
    child: Container(
      padding: EdgeInsets.only(top: 10),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).barBackgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        padding: EdgeInsets.only(top: 10, right: 20, left: 20, bottom: 10),
        width: MediaQuery.of(context).size.width,
        child: Text(
          snapshot.data?.getElementById('problem_output')?.text ?? '',
          style: TextStyle(fontSize: 14),
        ),
      ),
    ),
  );
}

Widget sampleInputHeader() {
  return CupertinoPageScaffold(
    child: Container(
      padding: EdgeInsets.only(top: 20),
      child: Text(
        '입력 예시',
        style: TextStyle(fontSize: 12, color: Color(0xff767676)),
      ),
    ),
  );
}

Widget sampleInputContent(
    AsyncSnapshot<dom.Document> snapshot, BuildContext context) {
  return CupertinoPageScaffold(
    child: Container(
      padding: EdgeInsets.only(top: 10),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).barBackgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        padding: EdgeInsets.only(top: 10, right: 20, left: 20, bottom: 10),
        width: MediaQuery.of(context).size.width,
        child: Text(
          snapshot.data?.getElementById('sample-input-1')?.text ?? '',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'monospace',
          ),
        ),
      ),
    ),
  );
}

Widget sampleOutputHeader() {
  return CupertinoPageScaffold(
    child: Container(
      padding: EdgeInsets.only(top: 20),
      child: Text(
        '출력 예시',
        style: TextStyle(fontSize: 12, color: Color(0xff767676)),
      ),
    ),
  );
}

Widget sampleOutputContent(
    AsyncSnapshot<dom.Document> snapshot, BuildContext context) {
  return CupertinoPageScaffold(
    child: Container(
      padding: EdgeInsets.only(top: 10),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoTheme.of(context).barBackgroundColor,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        padding: EdgeInsets.only(top: 10, right: 20, left: 20, bottom: 10),
        width: MediaQuery.of(context).size.width,
        child: Text(
          snapshot.data?.getElementById('sample-output-1')?.text ?? '',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'monospace',
          ),
        ),
      ),
    ),
  );
}