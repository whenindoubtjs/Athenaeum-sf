import { LightningElement } from 'lwc';
import fetchOrgVersion from '@salesforce/apex/OrgVersionController.fetchOrgVersion';

export default class OrgReleaseVersion extends LightningElement {
    orgVersion;             // The API version number (e.g., "57.0") to be displayed in the UI
    orgVersionLabel;        // The API version label (e.g., "Spring '24") to be displayed in the UI alongside the version number
    isLoading = true;       // Boolean to track whether the data is still being fetched, used to conditionally render a loading spinner in the UI
    errorMessage;           // String to hold any error messages that occur during the fetch process, which can be displayed in the UI if needed

    // Lifecycle hook that runs when the component is inserted into the DOM. It calls the Apex method to fetch the org version information, and handles 
    // the promise returned by the Apex method to set the component's state accordingly (orgVersion, orgVersionLabel, isLoading, errorMessage).
    connectedCallback() {
        fetchOrgVersion()
            .then(result => {
                this.orgVersion = result.version;
                this.orgVersionLabel = result.label;
            })
            .catch(error => {
                this.errorMessage = error.body?.message ?? 'An unexpected error occurred.';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}