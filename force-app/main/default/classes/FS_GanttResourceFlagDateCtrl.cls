/** Controller for VF custom action "Flag Tasks - Specific Date" (resource Id read from any URL parameter). */
public with sharing class FS_GanttResourceFlagDateCtrl {
    public Date selectedDate { get; set; }
    public Id resourceId { get; private set; }

    public FS_GanttResourceFlagDateCtrl() {
        selectedDate = Date.today();
        String prefix = ServiceResource.SObjectType.getDescribe().getKeyPrefix();
        for (String v : ApexPages.currentPage().getParameters().values()) {
            if (v != null && (v.length() == 15 || v.length() == 18) && v.startsWith(prefix)) {
                try { resourceId = Id.valueOf(v); } catch (Exception e) { }
            }
        }
    }

    public PageReference run() {
        if (resourceId == null || selectedDate == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Select a date (open this action from a Gantt resource).'));
            return null;
        }
        Datetime[] w = FS_GanttResourceFlagList.dayWindow(selectedDate);
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, FS_GanttResourceFlagList.load(resourceId, w[0], w[1])));
        return null;
    }
}
