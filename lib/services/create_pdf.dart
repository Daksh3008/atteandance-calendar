import 'package:attendance_calendar/database/database.dart';
import 'package:attendance_calendar/view/widgets/snackbar.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

Future<void> createPDF(
    {data,
    image,
    startDate,
    endDate,
    RxList<Attendance> present,
    RxList<Attendance> absent,
    RxList<Attendance> halfday}) async {
  try {
    await EasyLoading.show(
        maskType: EasyLoadingMaskType.black, dismissOnTap: false);

    ///LOAD IMAGE
    final pdf = pw.Document();
    String imgDir = image.toString().substring(7, image.toString().length - 1);
    final pic = pw.MemoryImage(
      File(imgDir).readAsBytesSync(),
    );

    ///LOAD IMAGE ENDS

    ///FORMAT DATA
    var start = DateFormat('EEE, dd MMM yyyy').format(DateTime.parse(startDate.toString()));
    var end = DateFormat('EEE, dd MMM yyyy').format(DateTime.parse(endDate.toString()));
    String repDuration = 'REPORT FOR : ' + start + ' to ' + end;

    ///FORMAT DATA ENDS

    pdf.addPage(
      pw.Page(build: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Text('Attendance Report',
                style: pw.TextStyle(
                  fontSize: 40,
                )),
            pw.Divider(thickness: 4),
            pw.SizedBox(height: 10),
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              children: [
                pw.Text(repDuration,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold))
              ],
            ),
            pw.Divider(),
            pw.Expanded(
                child: pw.Center(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 60),
                  pw.Center(
                      child: pw.Table.fromTextArray(
                          context: context,
                          cellAlignments: {
                            0: pw.Alignment.center,
                            1: pw.Alignment.center,
                            2: pw.Alignment.center,
                          },
                          cellStyle: const pw.TextStyle(
                            color: PdfColors.black,
                            fontSize: 40,
                          ),
                          headerStyle: pw.TextStyle(
                            color: PdfColors.black,
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          data: <List<String>>[
                            <String>['Present Days', 'Absent Days', 'Half Days'],
                            <String>[
                              '${present.length}',
                              '${absent.length}',
                              '${halfday.length}'
                            ],
                          ])),
                  pw.SizedBox(height: 40),
                  pw.Expanded(
                    child: pw.Center(child: pw.Image(pic)),
                  ),
                ],
              ),
            )),
            pw.SizedBox(height: 10),
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              children: [pw.Text("Attendance Calendar by SourceOrigin")],
            ),
          ],
        );
      }),
    );

    if (await Permission.storage.request().isGranted) {
      // Either the permission was already granted before or the user just granted it.
      bool exists =
          await Directory('/sdcard/Documents/Attendance Calendar').exists();

      if (!exists)
        new Directory('/sdcard/Documents/Attendance Calendar').createSync();

      var fileTime = DateFormat('yyyyMMddkkmm').format(DateTime.now());
      String t =
          '/sdcard/Documents/Attendance Calendar/Report_' + fileTime + '.pdf';
      File file = File(t);
      await file.writeAsBytes(await pdf.save());
      await File(imgDir).delete();
      successSnackbar(msg: 'create.pdf.pdf.saved.successfully');
      await EasyLoading.dismiss();
      OpenFile.open(t, type: "application/pdf", uti: "com.adobe.pdf");
    }
    EasyLoading.dismiss();
  } catch (e) {
    EasyLoading.dismiss();
    errorSnackbar(msg: e.toString());
  }
}

// Future<Uint8List> generateReport(PdfPageFormat pageFormat) async {
//   const tableHeaders = ['Category', 'Budget', 'Expense', 'Result'];
//
//   const dataTable = [
//     ['Phone', 80, 95, -15],
//     ['Internet', 250, 230, 20],
//     ['Electricity', 300, 375, -75],
//     ['Movies', 85, 80, 5],
//     ['Food', 300, 350, -50],
//     ['Fuel', 650, 550, 100],
//     ['Insurance', 250, 310, -60],
//   ];
//
//   final baseColor = PdfColors.cyan;
//
//   // Create a PDF document.
//   final document = pw.Document();
//
//   // Add page to the PDF
//   document.addPage(
//     pw.Page(
//       pageFormat: pageFormat,
//       theme: pw.ThemeData.withFont(
//         base: pw.Font.ttf(await rootBundle.load('assets/open-sans.ttf')),
//         bold: pw.Font.ttf(await rootBundle.load('assets/open-sans-bold.ttf')),
//       ),
//       build: (context) {
//         final chart1 = pw.Chart(
//           left: pw.Container(
//             alignment: pw.Alignment.topCenter,
//             margin: const pw.EdgeInsets.only(right: 5, top: 10),
//             child: pw.Transform.rotateBox(
//               angle: pi / 2,
//               child: pw.Text('Amount'),
//             ),
//           ),
//           overlay: pw.ChartLegend(
//             position: const pw.Alignment(-.7, 1),
//             decoration: pw.BoxDecoration(
//               color: PdfColors.white,
//               border: pw.Border.all(
//                 color: PdfColors.black,
//                 width: .5,
//               ),
//             ),
//           ),
//           grid: pw.CartesianGrid(
//             xAxis: pw.FixedAxis.fromStrings(
//               List<String>.generate(
//                   dataTable.length, (index) => dataTable[index][0]),
//               marginStart: 30,
//               marginEnd: 30,
//               ticks: true,
//             ),
//             yAxis: pw.FixedAxis(
//               [0, 100, 200, 300, 400, 500, 600, 700],
//               format: (v) => '\$$v',
//               divisions: true,
//             ),
//           ),
//           datasets: [
//             pw.BarDataSet(
//               color: PdfColors.blue100,
//               legend: tableHeaders[2],
//               width: 15,
//               offset: -10,
//               borderColor: baseColor,
//               data: List<pw.LineChartValue>.generate(
//                 dataTable.length,
//                 (i) {
//                   final num v = dataTable[i][2];
//                   return pw.LineChartValue(i.toDouble(), v.toDouble());
//                 },
//               ),
//             ),
//             pw.BarDataSet(
//               color: PdfColors.amber100,
//               legend: tableHeaders[1],
//               width: 15,
//               offset: 10,
//               borderColor: PdfColors.amber,
//               data: List<pw.LineChartValue>.generate(
//                 dataTable.length,
//                 (i) {
//                   final num v = dataTable[i][1];
//                   return pw.LineChartValue(i.toDouble(), v.toDouble());
//                 },
//               ),
//             ),
//           ],
//         );
//
//         final chart2 = pw.Chart(
//           grid: pw.CartesianGrid(
//             xAxis: pw.FixedAxis([0, 1, 2, 3, 4, 5, 6]),
//             yAxis: pw.FixedAxis(
//               [0, 200, 400, 600],
//               divisions: true,
//             ),
//           ),
//           datasets: [
//             pw.LineDataSet(
//               drawSurface: true,
//               isCurved: true,
//               drawPoints: false,
//               color: baseColor,
//               data: List<pw.LineChartValue>.generate(
//                 dataTable.length,
//                 (i) {
//                   final num v = dataTable[i][2];
//                   return pw.LineChartValue(i.toDouble(), v.toDouble());
//                 },
//               ),
//             ),
//           ],
//         );
//
//         final table = pw.Table.fromTextArray(
//           border: null,
//           headers: tableHeaders,
//           data: dataTable,
//           headerStyle: pw.TextStyle(
//             color: PdfColors.white,
//             fontWeight: pw.FontWeight.bold,
//           ),
//           headerDecoration: pw.BoxDecoration(
//             color: baseColor,
//           ),
//           rowDecoration: pw.BoxDecoration(
//             border: pw.Border(
//               bottom: pw.BorderSide(
//                 color: baseColor,
//                 width: .5,
//               ),
//             ),
//           ),
//         );
//
//         return pw.Column(
//           children: [
//             pw.Text('Budget Report',
//                 style: pw.TextStyle(
//                   color: baseColor,
//                   fontSize: 40,
//                 )),
//             pw.Divider(thickness: 4),
//             pw.Expanded(flex: 3, child: chart1),
//             pw.Divider(),
//             pw.Expanded(
//               flex: 2,
//               child: pw.Row(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Expanded(child: chart2),
//                   pw.SizedBox(width: 10),
//                   pw.Expanded(child: table),
//                 ],
//               ),
//             ),
//             pw.SizedBox(height: 10),
//             pw.Row(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Expanded(
//                     child: pw.Column(children: [
//                   pw.Container(
//                     alignment: pw.Alignment.centerLeft,
//                     padding: const pw.EdgeInsets.only(bottom: 10),
//                     child: pw.Text(
//                       'Expense By Sub-Categories',
//                       style: pw.TextStyle(
//                         color: baseColor,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//                   pw.Text(
//                     'Total expenses are broken into different categories for closer look into where the money was spent.',
//                     textAlign: pw.TextAlign.justify,
//                   )
//                 ])),
//                 pw.SizedBox(width: 10),
//                 pw.Expanded(
//                   child: pw.Column(
//                     children: [
//                       pw.Container(
//                         alignment: pw.Alignment.centerLeft,
//                         padding: const pw.EdgeInsets.only(bottom: 10),
//                         child: pw.Text(
//                           'Spent vs. Saved',
//                           style: pw.TextStyle(
//                             color: baseColor,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ),
//                       pw.Text(
//                         'Budget was originally \$1915. A total of \$1990 was spent on the month of January which exceeded the overall budget by \$75',
//                         textAlign: pw.TextAlign.justify,
//                       )
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         );
//       },
//     ),
//   );
//
//   // Return the PDF file content
//   return document.save();
// }
