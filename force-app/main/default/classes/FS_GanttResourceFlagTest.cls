/**
 * Tests use an in-memory test seam (FS_GanttResourceFlagList.mockAssignments) instead of inserting
 * Service Appointments, so org validation rules (e.g. inspection booking confirmation) do not block tests.
 */
@IsTest
private class FS_GanttResourceFlagTest {

    @TestSetup
    static void setup() {
        insert new ServiceResource(Name = 'GF Resource', RelatedRecordId = UserInfo.getUserId(), ResourceType = 'T', IsActive = true);
    }

    private static Id res() { return [SELECT Id FROM ServiceResource WHERE Name = 'GF Resource' LIMIT 1].Id; }

    private static Id fakeId(Schema.SObjectType t, Integer n) {
        return Id.valueOf(t.getDescribe().getKeyPrefix() + String.valueOf(n).leftPad(12, '0'));
    }

    /** Builds AssignedResource rows with the read-only StatusCategory populated */
    private static List<AssignedResource> rows(List<String> statusCategories) {
        List<Map<String, Object>> raw = new List<Map<String, Object>>();
        Integer i = 1;
        for (String sc : statusCategories) {
            Id saId = fakeId(ServiceAppointment.SObjectType, i);
            raw.add(new Map<String, Object>{
                'attributes' => new Map<String, Object>{ 'type' => 'AssignedResource' },
                'Id' => fakeId(AssignedResource.SObjectType, i),
                'ServiceAppointmentId' => saId,
                'ServiceAppointment' => new Map<String, Object>{
                    'attributes' => new Map<String, Object>{ 'type' => 'ServiceAppointment' },
                    'Id' => saId,
                    'StatusCategory' => sc
                }
            });
            i++;
        }
        return (List<AssignedResource>) JSON.deserialize(JSON.serialize(raw), List<AssignedResource>.class);
    }

    @IsTest
    static void today() {
        FS_GanttResourceFlagList.mockAssignments = rows(new List<String>{ 'Scheduled', 'Dispatched', 'Canceled' });
        String m = new FS_GanttResourceFlagToday().action(res(), null, null, null, null);
        Assert.isTrue(m.startsWith('2 appointment'), m);
    }

    @IsTest
    static void ganttDates() {
        Datetime s = Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
        FS_GanttResourceFlagList.mockAssignments = rows(new List<String>{ 'Scheduled', 'Scheduled', 'InProgress', 'Completed' });
        String m = new FS_GanttResourceFlagGanttDates().action(res(), null, s, s.addDays(14), null);
        Assert.isTrue(m.startsWith('3 appointment'), m);

        Assert.isTrue(new FS_GanttResourceFlagGanttDates().action(res(), null, null, null, null).startsWith('No resource'));

        FS_GanttResourceFlagList.mockAssignments = null;   // real query path, no data
        Assert.isTrue(new FS_GanttResourceFlagGanttDates().action(res(), null, s, s.addDays(1), null).startsWith('No appointments'));
    }

    @IsTest
    static void specificDate() {
        FS_GanttResourceFlagList.mockAssignments = rows(new List<String>{ 'Scheduled' });
        PageReference pr = Page.FS_GanttResourceFlagDate;
        pr.getParameters().put('id', res());
        Test.setCurrentPage(pr);
        FS_GanttResourceFlagDateCtrl c = new FS_GanttResourceFlagDateCtrl();
        c.selectedDate = Date.today().addDays(3);
        c.run();
        Assert.isTrue(ApexPages.hasMessages(ApexPages.Severity.CONFIRM));

        Test.setCurrentPage(Page.FS_GanttResourceFlagDate);
        FS_GanttResourceFlagDateCtrl c2 = new FS_GanttResourceFlagDateCtrl();
        c2.run();
        Assert.isTrue(ApexPages.hasMessages(ApexPages.Severity.ERROR));
    }

    @IsTest
    static void maxLimit() {
        List<String> many = new List<String>();
        for (Integer i = 0; i < FS_GanttResourceFlagList.MAX_IDS + 5; i++) { many.add('Scheduled'); }
        FS_GanttResourceFlagList.mockAssignments = rows(many);
        Datetime[] w = FS_GanttResourceFlagList.dayWindow(Date.today());
        String m = FS_GanttResourceFlagList.load(res(), w[0], w[1]);
        Assert.isTrue(m.startsWith(FS_GanttResourceFlagList.MAX_IDS + ' appointment'), m);
    }
}
