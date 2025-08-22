/**
 * Portal Form Utilities
 * 
 * JavaScript utilities for enhanced user experience, validation,
 * and interaction with portal forms.
 */

class PortalFormUtils {
    constructor(formElement, metadata) {
        this.form = formElement;
        this.metadata = metadata;
        this.formData = {};
        this.validationErrors = {};
        this.touched = {};
        
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.setupConditionalFields();
        this.setupValidation();
        this.setupAutoSave();
        this.loadDefaults();
    }

    /**
     * Set up event listeners for form interactions
     */
    setupEventListeners() {
        // Form submission
        this.form.addEventListener('submit', (e) => {
            e.preventDefault();
            this.handleSubmit();
        });

        // Field changes
        this.form.addEventListener('input', (e) => {
            this.handleFieldChange(e.target);
        });

        this.form.addEventListener('change', (e) => {
            this.handleFieldChange(e.target);
        });

        // Collapse/expand sections
        this.form.querySelectorAll('.collapse-toggle').forEach(toggle => {
            toggle.addEventListener('click', (e) => {
                this.toggleSection(e.target.closest('.form-section'));
            });
        });

        // Dynamic list/map editors
        this.setupDynamicEditors();

        // JSON validation
        this.setupJsonValidation();
    }

    /**
     * Set up conditional field display logic
     */
    setupConditionalFields() {
        const conditionalFields = this.form.querySelectorAll('[data-conditional]');
        
        conditionalFields.forEach(field => {
            const conditional = JSON.parse(field.dataset.conditional);
            const triggerField = this.form.querySelector(`[name="${conditional.field}"]`);
            
            if (triggerField) {
                const updateVisibility = () => {
                    const isVisible = this.evaluateCondition(conditional, triggerField);
                    field.classList.toggle('hidden', !isVisible);
                    
                    // Clear validation errors for hidden fields
                    if (!isVisible) {
                        this.clearFieldValidation(field.querySelector('[name]'));
                    }
                };

                triggerField.addEventListener('change', updateVisibility);
                triggerField.addEventListener('input', updateVisibility);
                
                // Initial check
                updateVisibility();
            }
        });
    }

    /**
     * Evaluate conditional display logic
     */
    evaluateCondition(conditional, triggerField) {
        const fieldValue = this.getFieldValue(triggerField);
        const { operator, value } = conditional;

        switch (operator) {
            case 'equals':
                return fieldValue === value;
            case 'not_equals':
                return fieldValue !== value;
            case 'contains':
                return Array.isArray(fieldValue) ? fieldValue.includes(value) : 
                       String(fieldValue).includes(String(value));
            case 'not_contains':
                return Array.isArray(fieldValue) ? !fieldValue.includes(value) : 
                       !String(fieldValue).includes(String(value));
            default:
                return true;
        }
    }

    /**
     * Set up real-time validation
     */
    setupValidation() {
        const fields = this.form.querySelectorAll('[data-validation]');
        
        fields.forEach(field => {
            const validation = JSON.parse(field.dataset.validation || '{}');
            
            // Debounced validation
            let validationTimeout;
            const validateField = () => {
                clearTimeout(validationTimeout);
                validationTimeout = setTimeout(() => {
                    this.validateField(field, validation);
                }, 300);
            };

            field.addEventListener('input', validateField);
            field.addEventListener('blur', () => {
                this.touched[field.name] = true;
                this.validateField(field, validation);
            });
        });
    }

    /**
     * Validate individual field
     */
    validateField(field, validation) {
        const value = this.getFieldValue(field);
        const errors = [];

        // Required validation
        if (field.required && (!value || (Array.isArray(value) && value.length === 0))) {
            errors.push('This field is required');
        }

        // Skip other validations if field is empty and not required
        if (!value && !field.required) {
            this.displayFieldValidation(field, []);
            return true;
        }

        // Pattern validation
        if (validation.pattern && typeof value === 'string') {
            const regex = new RegExp(validation.pattern);
            if (!regex.test(value)) {
                errors.push('Please enter a valid format');
            }
        }

        // Length validation
        if (typeof value === 'string') {
            if (validation.minLength && value.length < validation.minLength) {
                errors.push(`Minimum length is ${validation.minLength} characters`);
            }
            if (validation.maxLength && value.length > validation.maxLength) {
                errors.push(`Maximum length is ${validation.maxLength} characters`);
            }
        }

        // Numeric validation
        if (typeof value === 'number') {
            if (validation.min !== undefined && value < validation.min) {
                errors.push(`Minimum value is ${validation.min}`);
            }
            if (validation.max !== undefined && value > validation.max) {
                errors.push(`Maximum value is ${validation.max}`);
            }
        }

        // Custom validation
        if (validation.custom && typeof window[validation.custom] === 'function') {
            const customResult = window[validation.custom](value, field);
            if (customResult !== true) {
                errors.push(customResult || 'Invalid value');
            }
        }

        this.displayFieldValidation(field, errors);
        return errors.length === 0;
    }

    /**
     * Display field validation results
     */
    displayFieldValidation(field, errors) {
        const fieldContainer = field.closest('.form-field');
        const validationDiv = fieldContainer.querySelector('.field-validation');
        
        if (errors.length > 0) {
            validationDiv.className = 'field-validation error';
            validationDiv.innerHTML = errors.map(error => 
                `<div class="validation-message">❌ ${error}</div>`
            ).join('');
            field.classList.add('invalid');
        } else if (this.touched[field.name] && field.value) {
            validationDiv.className = 'field-validation success';
            validationDiv.innerHTML = '<div class="validation-message">✅ Valid</div>';
            field.classList.remove('invalid');
        } else {
            validationDiv.className = 'field-validation';
            validationDiv.innerHTML = '';
            field.classList.remove('invalid');
        }

        this.validationErrors[field.name] = errors;
    }

    /**
     * Clear field validation
     */
    clearFieldValidation(field) {
        if (!field) return;
        
        const fieldContainer = field.closest('.form-field');
        const validationDiv = fieldContainer?.querySelector('.field-validation');
        
        if (validationDiv) {
            validationDiv.className = 'field-validation';
            validationDiv.innerHTML = '';
        }
        
        field.classList.remove('invalid');
        delete this.validationErrors[field.name];
    }

    /**
     * Set up auto-save functionality
     */
    setupAutoSave() {
        if (!this.metadata.portal_config?.auto_save) return;

        let saveTimeout;
        this.form.addEventListener('input', () => {
            clearTimeout(saveTimeout);
            saveTimeout = setTimeout(() => {
                this.saveFormData();
            }, 2000);
        });

        // Load saved data on init
        this.loadSavedData();
    }

    /**
     * Save form data to localStorage
     */
    saveFormData() {
        const formData = this.getFormData();
        const key = `portal-form-${this.metadata.module_info.name}`;
        
        try {
            localStorage.setItem(key, JSON.stringify({
                data: formData,
                timestamp: Date.now()
            }));
            
            this.showNotification('Form data saved automatically', 'success');
        } catch (error) {
            console.warn('Could not save form data:', error);
        }
    }

    /**
     * Load saved form data from localStorage
     */
    loadSavedData() {
        const key = `portal-form-${this.metadata.module_info.name}`;
        
        try {
            const saved = localStorage.getItem(key);
            if (saved) {
                const { data, timestamp } = JSON.parse(saved);
                
                // Only load if saved within last 24 hours
                if (Date.now() - timestamp < 24 * 60 * 60 * 1000) {
                    this.setFormData(data);
                    this.showNotification('Restored previously saved form data', 'info');
                }
            }
        } catch (error) {
            console.warn('Could not load saved form data:', error);
        }
    }

    /**
     * Load default values from metadata
     */
    loadDefaults() {
        const sections = this.metadata.form_schema.sections;
        
        sections.forEach(section => {
            section.fields.forEach(field => {
                if (field.default !== undefined) {
                    const fieldElement = this.form.querySelector(`[name="${field.name}"]`);
                    if (fieldElement && !fieldElement.value) {
                        this.setFieldValue(fieldElement, field.default);
                    }
                }
            });
        });
    }

    /**
     * Set up dynamic list and map editors
     */
    setupDynamicEditors() {
        // List editors
        this.form.querySelectorAll('.list-editor').forEach(editor => {
            const addButton = editor.querySelector('.add-item');
            const itemsContainer = editor.querySelector('.list-items');
            
            addButton.addEventListener('click', () => {
                this.addListItem(itemsContainer);
            });
            
            // Set up existing remove buttons
            this.setupRemoveButtons(itemsContainer);
        });

        // Map editors
        this.form.querySelectorAll('.map-editor').forEach(editor => {
            const addButton = editor.querySelector('.add-map-item');
            const itemsContainer = editor.querySelector('.map-items');
            
            addButton.addEventListener('click', () => {
                this.addMapItem(itemsContainer);
            });
            
            // Set up existing remove buttons
            this.setupRemoveButtons(itemsContainer);
        });
    }

    /**
     * Add new list item
     */
    addListItem(container) {
        const item = document.createElement('div');
        item.className = 'list-item';
        item.innerHTML = `
            <input type="text" placeholder="Enter value" />
            <button type="button" class="remove-item">✕</button>
        `;
        
        container.appendChild(item);
        this.setupRemoveButtons(container);
        
        // Focus new input
        item.querySelector('input').focus();
    }

    /**
     * Add new map item
     */
    addMapItem(container) {
        const item = document.createElement('div');
        item.className = 'map-item';
        item.innerHTML = `
            <input type="text" placeholder="Key" class="map-key" />
            <input type="text" placeholder="Value" class="map-value" />
            <button type="button" class="remove-item">✕</button>
        `;
        
        container.appendChild(item);
        this.setupRemoveButtons(container);
        
        // Focus new key input
        item.querySelector('.map-key').focus();
    }

    /**
     * Set up remove buttons for dynamic items
     */
    setupRemoveButtons(container) {
        container.querySelectorAll('.remove-item').forEach(button => {
            button.onclick = () => {
                button.closest('.list-item, .map-item').remove();
            };
        });
    }

    /**
     * Set up JSON validation
     */
    setupJsonValidation() {
        this.form.querySelectorAll('.json-editor').forEach(editor => {
            editor.addEventListener('input', () => {
                this.validateJson(editor);
            });
        });
    }

    /**
     * Validate JSON input
     */
    validateJson(editor) {
        const validationDiv = editor.parentElement.querySelector('.json-validation');
        
        try {
            JSON.parse(editor.value);
            validationDiv.className = 'json-validation success';
            validationDiv.textContent = '✅ Valid JSON';
        } catch (error) {
            validationDiv.className = 'json-validation error';
            validationDiv.textContent = `❌ Invalid JSON: ${error.message}`;
        }
    }

    /**
     * Handle field changes
     */
    handleFieldChange(field) {
        this.formData[field.name] = this.getFieldValue(field);
        
        // Update cost estimation if relevant
        this.updateCostEstimation();
        
        // Trigger conditional field updates
        this.form.dispatchEvent(new CustomEvent('fieldChange', {
            detail: { field: field.name, value: this.formData[field.name] }
        }));
    }

    /**
     * Get field value based on field type
     */
    getFieldValue(field) {
        if (!field) return null;

        switch (field.type) {
            case 'checkbox':
                return field.checked;
            case 'number':
                return field.value ? parseFloat(field.value) : null;
            case 'file':
                return field.files;
            default:
                if (field.name.endsWith('[]')) {
                    // Multi-select
                    const checked = this.form.querySelectorAll(`[name="${field.name}"]:checked`);
                    return Array.from(checked).map(cb => cb.value);
                }
                return field.value;
        }
    }

    /**
     * Set field value based on field type
     */
    setFieldValue(field, value) {
        if (!field) return;

        switch (field.type) {
            case 'checkbox':
                field.checked = Boolean(value);
                break;
            case 'number':
                field.value = value || '';
                break;
            default:
                field.value = value || '';
        }
    }

    /**
     * Get all form data
     */
    getFormData() {
        const data = {};
        const formData = new FormData(this.form);
        
        // Handle regular fields
        for (const [key, value] of formData.entries()) {
            if (key.endsWith('[]')) {
                const cleanKey = key.slice(0, -2);
                if (!data[cleanKey]) data[cleanKey] = [];
                data[cleanKey].push(value);
            } else {
                data[key] = value;
            }
        }

        // Handle list editors
        this.form.querySelectorAll('.list-editor').forEach(editor => {
            const fieldName = editor.dataset.field;
            const inputs = editor.querySelectorAll('.list-item input');
            data[fieldName] = Array.from(inputs).map(input => input.value).filter(v => v);
        });

        // Handle map editors
        this.form.querySelectorAll('.map-editor').forEach(editor => {
            const fieldName = editor.dataset.field;
            const items = editor.querySelectorAll('.map-item');
            const mapData = {};
            
            items.forEach(item => {
                const key = item.querySelector('.map-key').value;
                const value = item.querySelector('.map-value').value;
                if (key && value) {
                    mapData[key] = value;
                }
            });
            
            data[fieldName] = mapData;
        });

        // Handle JSON editors
        this.form.querySelectorAll('.json-editor').forEach(editor => {
            const fieldName = editor.name;
            try {
                data[fieldName] = JSON.parse(editor.value);
            } catch (error) {
                data[fieldName] = editor.value;
            }
        });

        return data;
    }

    /**
     * Set form data
     */
    setFormData(data) {
        Object.entries(data).forEach(([key, value]) => {
            const field = this.form.querySelector(`[name="${key}"]`);
            if (field) {
                this.setFieldValue(field, value);
            }
        });
    }

    /**
     * Toggle section collapse/expand
     */
    toggleSection(section) {
        section.classList.toggle('collapsed');
        const toggle = section.querySelector('.collapse-toggle');
        toggle.textContent = section.classList.contains('collapsed') ? '▶' : '▼';
    }

    /**
     * Update cost estimation based on current form values
     */
    updateCostEstimation() {
        const costEstimator = document.querySelector('.cost-estimator');
        if (!costEstimator) return;

        const formData = this.getFormData();
        const costFactors = this.metadata.cost_estimation?.cost_factors || [];
        
        // Simple cost calculation based on form values
        let estimatedCost = this.metadata.cost_estimation?.estimated_monthly_cost?.typical || 0;
        
        // Apply cost factors based on form values
        costFactors.forEach(factor => {
            const fieldValue = formData[factor.field];
            if (fieldValue && factor.multiplier) {
                estimatedCost *= factor.multiplier;
            }
        });

        // Update display
        const costDisplay = costEstimator.querySelector('.cost-typical');
        if (costDisplay) {
            costDisplay.textContent = `$${Math.round(estimatedCost)}/month`;
        }
    }

    /**
     * Validate entire form
     */
    validateForm() {
        const fields = this.form.querySelectorAll('[data-validation]');
        let isValid = true;
        
        fields.forEach(field => {
            const validation = JSON.parse(field.dataset.validation || '{}');
            if (!this.validateField(field, validation)) {
                isValid = false;
            }
        });

        this.displayValidationSummary(isValid);
        return isValid;
    }

    /**
     * Display validation summary
     */
    displayValidationSummary(isValid) {
        const summary = document.getElementById('validation-summary');
        if (!summary) return;

        const errors = Object.values(this.validationErrors).flat().filter(e => e);
        
        if (isValid && errors.length === 0) {
            summary.querySelector('.validation-success').innerHTML = 
                '<h4>✅ Form is valid and ready for deployment</h4>';
            summary.querySelector('.validation-errors').innerHTML = '';
            summary.querySelector('.validation-warnings').innerHTML = '';
        } else {
            summary.querySelector('.validation-errors').innerHTML = 
                `<h4>❌ Please fix the following errors:</h4><ul>${
                    errors.map(error => `<li>${error}</li>`).join('')
                }</ul>`;
            summary.querySelector('.validation-success').innerHTML = '';
        }

        summary.style.display = 'block';
    }

    /**
     * Handle form submission
     */
    handleSubmit() {
        if (!this.validateForm()) {
            this.showNotification('Please fix validation errors before submitting', 'error');
            return;
        }

        const formData = this.getFormData();
        
        // Emit custom event for form submission
        this.form.dispatchEvent(new CustomEvent('portalFormSubmit', {
            detail: { formData, metadata: this.metadata }
        }));

        this.showNotification('Deploying infrastructure...', 'info');
    }

    /**
     * Show notification to user
     */
    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.innerHTML = `
            <span>${message}</span>
            <button onclick="this.parentElement.remove()">✕</button>
        `;
        
        document.body.appendChild(notification);
        
        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (notification.parentElement) {
                notification.remove();
            }
        }, 5000);
    }
}

// Global utility functions for form interactions

/**
 * Toggle password visibility
 */
function togglePassword(fieldId) {
    const field = document.getElementById(fieldId);
    const toggle = field.parentElement.querySelector('.password-toggle');
    
    if (field.type === 'password') {
        field.type = 'text';
        toggle.textContent = '🙈';
    } else {
        field.type = 'password';
        toggle.textContent = '👁️';
    }
}

/**
 * Reset form to defaults
 */
function resetForm() {
    if (confirm('Reset form to default values? This will lose any unsaved changes.')) {
        const form = document.getElementById('module-form');
        const utils = form.portalUtils;
        
        form.reset();
        utils.loadDefaults();
        utils.showNotification('Form reset to defaults', 'info');
    }
}

/**
 * Validate form manually
 */
function validateForm() {
    const form = document.getElementById('module-form');
    const utils = form.portalUtils;
    
    const isValid = utils.validateForm();
    if (isValid) {
        utils.showNotification('Form validation passed!', 'success');
    }
}

/**
 * Preview generated Terraform code
 */
function previewTerraform() {
    const form = document.getElementById('module-form');
    const utils = form.portalUtils;
    const formData = utils.getFormData();
    
    // Generate Terraform preview
    const terraformCode = generateTerraformCode(formData, utils.metadata);
    
    // Show in modal or new window
    showTerraformPreview(terraformCode);
}

/**
 * Generate Terraform code from form data
 */
function generateTerraformCode(formData, metadata) {
    const moduleName = metadata.module_info.name;
    const moduleSource = `kbrockhoff/${moduleName}/terraform`;
    
    let terraform = `module "${moduleName.replace(/-/g, '_')}" {\n`;
    terraform += `  source = "${moduleSource}"\n\n`;
    
    // Add form data as variables
    Object.entries(formData).forEach(([key, value]) => {
        if (value !== null && value !== undefined && value !== '') {
            if (typeof value === 'string') {
                terraform += `  ${key} = "${value}"\n`;
            } else if (typeof value === 'boolean') {
                terraform += `  ${key} = ${value}\n`;
            } else if (typeof value === 'number') {
                terraform += `  ${key} = ${value}\n`;
            } else if (Array.isArray(value)) {
                terraform += `  ${key} = ${JSON.stringify(value)}\n`;
            } else if (typeof value === 'object') {
                terraform += `  ${key} = ${JSON.stringify(value, null, 2).replace(/\n/g, '\n  ')}\n`;
            }
        }
    });
    
    terraform += '}\n';
    return terraform;
}

/**
 * Show Terraform preview in modal
 */
function showTerraformPreview(code) {
    const modal = document.createElement('div');
    modal.className = 'terraform-preview-modal';
    modal.innerHTML = `
        <div class="modal-content">
            <div class="modal-header">
                <h3>🔍 Terraform Preview</h3>
                <button onclick="this.closest('.terraform-preview-modal').remove()">✕</button>
            </div>
            <div class="modal-body">
                <pre><code class="language-hcl">${code}</code></pre>
            </div>
            <div class="modal-footer">
                <button onclick="copyToClipboard('${code.replace(/'/g, "\\'")}')">📋 Copy to Clipboard</button>
                <button onclick="this.closest('.terraform-preview-modal').remove()">Close</button>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
}

/**
 * Copy text to clipboard
 */
function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        const form = document.getElementById('module-form');
        const utils = form.portalUtils;
        utils.showNotification('Copied to clipboard!', 'success');
    });
}

/**
 * Check prerequisites
 */
async function checkPrerequisites() {
    const prereqItems = document.querySelectorAll('.prereq-item');
    
    for (const item of prereqItems) {
        const status = item.querySelector('.prereq-status');
        status.textContent = '⏳';
        
        // Simulate prerequisite checking
        await new Promise(resolve => setTimeout(resolve, 500));
        
        // Random success/failure for demo
        const isValid = Math.random() > 0.3;
        status.textContent = isValid ? '✅' : '❌';
        item.classList.toggle('prereq-valid', isValid);
        item.classList.toggle('prereq-invalid', !isValid);
    }
}

// Initialize form when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('module-form');
    if (form && window.portalMetadata) {
        form.portalUtils = new PortalFormUtils(form, window.portalMetadata);
    }
});

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { PortalFormUtils };
}