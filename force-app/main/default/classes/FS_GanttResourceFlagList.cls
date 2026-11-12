/**
 * Loads all appointments of a Gantt resource for a date window into the Dispatcher Console
 * appointment list (standard FSL__CreateFilterEvent__e temporary list), so the dispatcher can
 * Select All -> Flag using the STANDARD Dispatcher Console flag.
 * No custom fields / objects. The standard flag itself is client-side only and cannot be set from Apex.
 */
public with sharing class FS_GanttResourceFlagList {

    public static final Integer MAX_IDS = 300;  // temporary list limit
    public static final Set<String> EXCLUDED_CATEGORIES = new Set<String>{ 'Canceled', 'Completed', 'CannotComplete' };

    public static String load(Id resourceId, Datetime startDt, Datetime endDt) {
        if (resourceId == null || startDt == null || endDt == null || startDt >= endDt) {
            return 'No resource or valid date window received.';
        }
        List<Id> ids = new List<Id>();
        for (AssignedResource ar : queryAssignments(resourceId, startDt, endDt)) {
            if (EXCLUDED_CATEGORIES.contains(String.valueOf(ar.ServiceAppointment.StatusCategory))) { continue; }
            if (ids.size() == MAX_IDS) { break; }
            ids.add(ar.ServiceAppointmentId);
        }

        String label = rangeLabel(startDt, endDt);
        String who = [SELECT Name FROM ServiceResource WHERE Id = :resourceId LIMIT 1].Name;
        if (ids.isEmpty()) { return 'No appointments found for ' + who + ' (' + label + ').'; }

        FSL__CreateFilterEvent__e ev = new FSL__CreateFilterEvent__e(
            FSL__ServiceApptIds__c        = JSON.serialize(ids),
            FSL__FilterName__c            = ('To Flag - ' + who + ' - ' + label).left(80),
            FSL__Description__c           = 'Select all and click Flag',
            FSL__FilterCategory__c        = 'GENERAL',
            FSL__LoadFilterImmediately__c = true
        );
        Database.SaveResult sr = EventBus.publish(ev);
        if (!sr.isSuccess()) { return 'Could not load list: ' + sr.getErrors()[0].getMessage(); }
        return ids.size() + ' appointment(s) for ' + who + ' (' + label + ') loaded in the appointment list - Select All > Flag.';
    }

    // Test seam: lets tests supply rows without inserting Service Appointments (org validation rules)
    @TestVisible private static List<AssignedResource> mockAssignments;

    private static List<AssignedResource> queryAssignments(Id resourceId, Datetime startDt, Datetime endDt) {
        if (Test.isRunningTest() && mockAssignments != null) { return mockAssignments; }
        return [SELECT ServiceAppointmentId, ServiceAppointment.StatusCategory
                FROM AssignedResource
                WHERE ServiceResourceId = :resourceId
                  AND ServiceAppointment.SchedStartTime < :endDt
                  AND ServiceAppointment.SchedEndTime   > :startDt
                ORDER BY ServiceAppointment.SchedStartTime
                LIMIT 1000];
    }

    public static Datetime[] dayWindow(Date d) {
        return new Datetime[]{ Datetime.newInstance(d, Time.newInstance(0, 0, 0, 0)),
                               Datetime.newInstance(d.addDays(1), Time.newInstance(0, 0, 0, 0)) };
    }

    public static String rangeLabel(Datetime s, Datetime e) {
        String a = s.format('d MMM yyyy');
        String b = e.addSeconds(-1).format('d MMM yyyy');
        return a == b ? a : a + ' - ' + b;
    }
}
