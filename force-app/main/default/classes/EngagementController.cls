public with sharing class EngagementController {
    public class Summary {
        @AuraEnabled public Decimal totalAmount {get; set;}
        @AuraEnabled public Integer completedTasks {get; set;}
        @AuraEnabled public Integer upcomingEvents {get; set;}
        
        public Summary() {
            this.totalAmount = 0;
            this.completedTasks = 0;
            this.upcomingEvents = 0;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Summary getEngagementSummary(Id engagementId) {
        Summary sum = new Summary();
        
        // Sumar Amount de Oportunidades relacionadas
        // Asumimos que hay un campo de búsqueda en Opportunity llamado Engagement__c 
        // o que Engagement__c tiene un lookup (para la demo manejaremos el lookup en Engagement si existe o el total de hijos)
        AggregateResult[] groupedResults = [SELECT SUM(Amount) total FROM Opportunity WHERE Engagement__c = :engagementId];
        if (groupedResults.size() > 0 && groupedResults[0].get('total') != null) {
            sum.totalAmount = (Decimal)groupedResults[0].get('total');
        }
        
        // Contar Tareas completadas
        sum.completedTasks = [SELECT count() FROM Task WHERE WhatId = :engagementId AND Status = 'Completed'];
        
        // Contar Eventos futuros
        sum.upcomingEvents = [SELECT count() FROM Event WHERE WhatId = :engagementId AND StartDateTime >= :DateTime.now()];
        
        return sum;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getActivityCounts(Id engagementId) {
        Integer completedTasks = [SELECT count() FROM Task WHERE WhatId = :engagementId AND Status = 'Completed'];
        Integer upcomingEvents = [SELECT count() FROM Event WHERE WhatId = :engagementId AND StartDateTime >= :DateTime.now()];
        
        return new Map<String, Integer>{
            'completedTasks' => completedTasks,
            'upcomingEvents' => upcomingEvents
        };
    }

    @AuraEnabled
    public static void createFollowUpTask(Id engagementId, String subject) {
        try {
            Task newTask = new Task(
                Subject = subject,
                Status = 'Not Started',
                Priority = 'Normal',
                ActivityDate = Date.today().addDays(1),
                WhatId = engagementId
            );
            insert newTask;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating Task: ' + e.getMessage());
        }
    }
}