import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getEngagementSummary from '@salesforce/apex/EngagementController.getEngagementSummary';
import createFollowUpTask from '@salesforce/apex/EngagementController.createFollowUpTask';

// Importamos los campos necesarios para el objeto Engagement (opcional si solo usamos Apex)
import ENG_NAME_FIELD from '@salesforce/schema/Engagement__c.Name';

export default class EngagementSummary extends LightningElement {
    @api recordId;
    
    // Propiedades para los datos
    summaryData;
    error;

    // Obtener datos del record actual (para el título/contexto)
    @wire(getRecord, { recordId: '$recordId', fields: [ENG_NAME_FIELD] })
    engagement;

    // Obtener resumen profesional desde Apex
    @wire(getEngagementSummary, { engagementId: '$recordId' })
    wiredSummary({ error, data }) {
        if (data) {
            this.summaryData = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.summaryData = undefined;
            console.error('Error loading summary:', error);
        }
    }

    // Getters para legibilidad en el HTML
    get totalAmount() {
        return this.summaryData ? this.summaryData.totalAmount : 0;
    }

    get completedTasksCount() {
        return this.summaryData ? this.summaryData.completedTasks : 0;
    }

    get upcomingEventsCount() {
        return this.summaryData ? this.summaryData.upcomingEvents : 0;
    }

    // Crear Tarea de Seguimiento vía Apex
    handleFollowUp() {
        const subject = `Follow-up on ${this.engagementName}`;

        createFollowUpTask({ engagementId: this.recordId, subject: subject })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Follow-up task created for tomorrow',
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                console.error('Apex Error:', error);
                let message = 'Unknown error';
                if (error.body && error.body.message) {
                    message = error.body.message;
                }
                
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: message,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            });
    }
}