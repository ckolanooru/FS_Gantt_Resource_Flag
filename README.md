# FS Gantt Resource Flag (AKLC)
Resource custom actions that load a resource's appointments (Today / Gantt dates / Specific date) into the appointment list, so the dispatcher can Select All > standard Flag. No custom fields.

| Component | Type | Console action |
|---|---|---|
| FS_GanttResourceFlagList | Apex (shared logic) | - |
| FS_GanttResourceFlagToday | Apex (global) | Flag Tasks - Today |
| FS_GanttResourceFlagGanttDates | Apex (global) | Flag Tasks - Gantt Dates |
| FS_GanttResourceFlagDate + FS_GanttResourceFlagDateCtrl | Visualforce + Apex | Flag Tasks - Specific Date |
| FS_GanttResourceFlagTest | Test | - |

Deploy:
sf project deploy validate --manifest manifest\package.xml --target-org aklcdev --test-level RunSpecifiedTests --tests FS_GanttResourceFlagTest
