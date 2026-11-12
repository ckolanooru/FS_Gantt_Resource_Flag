/** Gantt resource custom action: list today's appointments of the resource for flagging */
global with sharing class FS_GanttResourceFlagToday implements FSL.CustomGanttServiceResourceAction {
    global String action(Id resourceId, Id stmId, Datetime ganttStartDate, Datetime ganttEndDate, Map<String, Object> additionalParameters) {
        Datetime[] w = FS_GanttResourceFlagList.dayWindow(Date.today());
        return FS_GanttResourceFlagList.load(resourceId, w[0], w[1]);
    }
}
