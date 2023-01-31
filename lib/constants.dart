import 'package:intl/intl.dart';

const DARK_MODE = 'dark_mode';
const LOCAL_AUTH = 'local_auth';
const DAILY_BACKUP = 'daily_backyp';
const IS_FIRST_TIME = 'first_launch';

final DateFormat dateFormat = DateFormat('d-MM-yyyy');
final DateFormat dateFormat2 = DateFormat('EEE, dd MMM yyyy, h:mm a');

const ATTENDANCE_TYPE = {"present": 1, "absent": 2, "half": 3};
const ATTENDANCE_NAME = ["", "Present", "Absent", "Half"];

const slackURL = 'https://hooks.slack.com/services/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';
