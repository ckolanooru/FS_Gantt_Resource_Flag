/** Gantt resource custom action: list the resource's appointments in the current Gantt date range for flagging */
global with sharing class FS_GanttResourceFlagGanttDates implements FSL.CustomGanttServiceResourceAction {
    global String action(Id resourceId, Id stmId, Datetime ganttStartDate, Datetime ganttEndDate, Map<String, Object> additionalParameters) {
        return FS_GanttResourceFlagList.load(resourceId, ganttStartDate, ganttEndDate);
    }
}
