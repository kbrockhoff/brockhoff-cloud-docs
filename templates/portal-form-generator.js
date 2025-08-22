/**
 * Portal Form Generator
 * 
 * Generates user-friendly forms from portal metadata schema for developer portals.
 * Includes sensible defaults, clear validation, and UX optimizations.
 */

class PortalFormGenerator {
    constructor(metadata, options = {}) {
        this.metadata = metadata;
        this.options = {
            theme: 'default',
            showAdvanced: false,
            enableTooltips: true,
            autoSave: true,
            ...options
        };
        this.formData = {};
        this.validationErrors = {};
        this.touched = {};
    }

    /**
     * Generate complete form HTML with user-friendly features
     */
    generateForm() {
        const formHtml = `
            <div class="portal-form" data-module="${this.metadata.module_info.name}">
                ${this.generateFormHeader()}
                ${this.generateCostEstimator()}
                ${this.generateDifficultyIndicator()}
                ${this.generatePrerequisitesCheck()}
                <form id="module-form" class="module-form">
                    ${this.generateFormSections()}
                    ${this.generateFormActions()}
                </form>
                ${this.generateValidationSummary()}
            </div>
        `;
        
        return formHtml;
    }

    /**
     * Generate form header with module information
     */
    generateFormHeader() {
        const moduleInfo = this.metadata.module_info;
        const portalConfig = this.metadata.portal_config;
        
        return `
            <div class="form-header">
                <div class="module-title">
                    <h2>${this.humanizeModuleName(moduleInfo.name)}</h2>
                    <span class="module-version">v${moduleInfo.version}</span>
                    <span class="module-category category-${moduleInfo.category}">${moduleInfo.category}</span>
                </div>
                <p class="module-description">${moduleInfo.description}</p>
                <div class="module-meta">
                    <span class="deployment-time">
                        <i class="icon-clock"></i>
                        Deployment: ${portalConfig.deployment_time}
                    </span>
                    <span class="complexity-level complexity-${portalConfig.complexity_level}">
                        <i class="icon-gauge"></i>
                        ${this.capitalizeFirst(portalConfig.complexity_level)}
                    </span>
                    ${this.generateCloudProviderBadges()}
                </div>
            </div>
        `;
    }

    /**
     * Generate interactive cost estimator
     */
    generateCostEstimator() {
        const costEst = this.metadata.cost_estimation;
        
        return `
            <div class="cost-estimator">
                <h3>💰 Cost Estimation</h3>
                <div class="cost-summary">
                    <div class="cost-category cost-${costEst.base_cost_category}">
                        ${this.getCostCategoryIcon(costEst.base_cost_category)}
                        ${this.capitalizeFirst(costEst.base_cost_category)} Cost
                    </div>
                    ${costEst.estimated_monthly_cost ? `
                        <div class="cost-range">
                            <span class="cost-typical">$${costEst.estimated_monthly_cost.typical}/month</span>
                            <span class="cost-range-text">
                                ($${costEst.estimated_monthly_cost.min} - $${costEst.estimated_monthly_cost.max})
                            </span>
                        </div>
                    ` : ''}
                </div>
                <div class="cost-factors">
                    <details>
                        <summary>Cost Factors & Optimization Tips</summary>
                        <div class="cost-details">
                            <div class="cost-factors-list">
                                <h4>What affects the cost:</h4>
                                <ul>
                                    ${costEst.cost_factors.map(factor => `
                                        <li class="factor-${factor.impact}">
                                            <strong>${factor.factor}</strong>
                                            <span class="impact impact-${factor.impact}">${factor.impact} impact</span>
                                            <p>${factor.description}</p>
                                        </li>
                                    `).join('')}
                                </ul>
                            </div>
                            ${costEst.cost_optimization_tips ? `
                                <div class="optimization-tips">
                                    <h4>💡 Cost Optimization Tips:</h4>
                                    <ul>
                                        ${costEst.cost_optimization_tips.map(tip => `<li>${tip}</li>`).join('')}
                                    </ul>
                                </div>
                            ` : ''}
                        </div>
                    </details>
                </div>
            </div>
        `;
    }

    /**
     * Generate difficulty indicator with skill requirements
     */
    generateDifficultyIndicator() {
        const difficulty = this.metadata.difficulty_assessment;
        
        return `
            <div class="difficulty-indicator">
                <h3>📊 Difficulty Assessment</h3>
                <div class="difficulty-summary">
                    <div class="difficulty-rating">
                        <span class="rating-label">Overall Difficulty:</span>
                        <div class="rating-stars">
                            ${this.generateStarRating(difficulty.overall_difficulty)}
                        </div>
                        <span class="rating-text">${difficulty.overall_difficulty}/5</span>
                    </div>
                </div>
                <details>
                    <summary>Skill Requirements & Complexity Factors</summary>
                    <div class="skill-requirements">
                        <h4>Required Skills:</h4>
                        <div class="skills-grid">
                            ${Object.entries(difficulty.skill_requirements).map(([skill, level]) => `
                                <div class="skill-item skill-${level}">
                                    <span class="skill-name">${this.humanizeSkillName(skill)}</span>
                                    <span class="skill-level level-${level}">${this.capitalizeFirst(level)}</span>
                                </div>
                            `).join('')}
                        </div>
                        ${difficulty.complexity_factors ? `
                            <h4>Complexity Factors:</h4>
                            <ul class="complexity-factors">
                                ${difficulty.complexity_factors.map(factor => `
                                    <li class="complexity-${factor.level}">
                                        <strong>${factor.factor}</strong>
                                        <span class="level level-${factor.level}">${factor.level}</span>
                                        <p>${factor.description}</p>
                                    </li>
                                `).join('')}
                            </ul>
                        ` : ''}
                    </div>
                </details>
            </div>
        `;
    }

    /**
     * Generate prerequisites checker
     */
    generatePrerequisitesCheck() {
        const prereqs = this.metadata.prerequisites;
        if (!prereqs) return '';

        return `
            <div class="prerequisites-check">
                <h3>✅ Prerequisites Check</h3>
                <div class="prereq-sections">
                    ${prereqs.required_modules ? `
                        <div class="prereq-section">
                            <h4>Required Modules:</h4>
                            <ul class="prereq-list">
                                ${prereqs.required_modules.map(mod => `
                                    <li class="prereq-item" data-check="module:${mod.module_name}">
                                        <span class="prereq-status">⏳</span>
                                        <div class="prereq-details">
                                            <strong>${mod.module_name}</strong>
                                            <span class="version">${mod.version_constraint}</span>
                                            <p>${mod.description}</p>
                                        </div>
                                    </li>
                                `).join('')}
                            </ul>
                        </div>
                    ` : ''}
                    
                    ${prereqs.cloud_resources ? `
                        <div class="prereq-section">
                            <h4>Cloud Resources:</h4>
                            <ul class="prereq-list">
                                ${prereqs.cloud_resources.map(resource => `
                                    <li class="prereq-item" data-check="resource:${resource.resource_type}">
                                        <span class="prereq-status">⏳</span>
                                        <div class="prereq-details">
                                            <strong>${resource.resource_type}</strong>
                                            <span class="provider provider-${resource.provider}">${resource.provider.toUpperCase()}</span>
                                            <p>${resource.description}</p>
                                            ${resource.setup_instructions ? `
                                                <details class="setup-instructions">
                                                    <summary>Setup Instructions</summary>
                                                    <p>${resource.setup_instructions}</p>
                                                </details>
                                            ` : ''}
                                        </div>
                                    </li>
                                `).join('')}
                            </ul>
                        </div>
                    ` : ''}
                    
                    ${prereqs.permissions ? `
                        <div class="prereq-section">
                            <h4>Required Permissions:</h4>
                            <ul class="prereq-list">
                                ${prereqs.permissions.map(perm => `
                                    <li class="prereq-item" data-check="permission:${perm.permission}">
                                        <span class="prereq-status">⏳</span>
                                        <div class="prereq-details">
                                            <strong>${perm.permission}</strong>
                                            <span class="provider provider-${perm.provider}">${perm.provider.toUpperCase()}</span>
                                            <p>${perm.description}</p>
                                        </div>
                                    </li>
                                `).join('')}
                            </ul>
                        </div>
                    ` : ''}
                </div>
                <button type="button" class="btn-check-prereqs" onclick="checkPrerequisites()">
                    🔍 Check Prerequisites
                </button>
            </div>
        `;
    }

    /**
     * Generate form sections with user-friendly features
     */
    generateFormSections() {
        const sections = this.metadata.form_schema.sections;
        
        return sections.map(section => `
            <div class="form-section ${section.collapsible ? 'collapsible' : ''}" 
                 data-section="${this.slugify(section.title)}">
                <div class="section-header">
                    <h3>${section.title}</h3>
                    ${section.collapsible ? '<button type="button" class="collapse-toggle">▼</button>' : ''}
                </div>
                ${section.description ? `<p class="section-description">${section.description}</p>` : ''}
                <div class="section-fields">
                    ${section.fields.map(field => this.generateField(field)).join('')}
                </div>
            </div>
        `).join('');
    }

    /**
     * Generate individual form field with validation and UX features
     */
    generateField(field) {
        const fieldId = `field-${field.name}`;
        const isRequired = field.required || false;
        const hasDefault = field.default !== undefined;
        
        return `
            <div class="form-field field-${field.type} ${isRequired ? 'required' : ''}" 
                 data-field="${field.name}"
                 ${field.conditional ? `data-conditional='${JSON.stringify(field.conditional)}'` : ''}>
                
                <label for="${fieldId}" class="field-label">
                    ${field.label}
                    ${isRequired ? '<span class="required-indicator">*</span>' : ''}
                    ${this.options.enableTooltips && field.description ? `
                        <span class="tooltip" data-tooltip="${field.description}">ℹ️</span>
                    ` : ''}
                </label>
                
                ${field.description && !this.options.enableTooltips ? `
                    <p class="field-description">${field.description}</p>
                ` : ''}
                
                <div class="field-input-wrapper">
                    ${this.generateFieldInput(field, fieldId)}
                    <div class="field-validation" id="${fieldId}-validation"></div>
                </div>
                
                ${field.help_text ? `
                    <div class="field-help">
                        <details>
                            <summary>Need help?</summary>
                            <p>${field.help_text}</p>
                        </details>
                    </div>
                ` : ''}
            </div>
        `;
    }

    /**
     * Generate field input based on type
     */
    generateFieldInput(field, fieldId) {
        const commonAttrs = `
            id="${fieldId}"
            name="${field.name}"
            ${field.required ? 'required' : ''}
            ${field.placeholder ? `placeholder="${field.placeholder}"` : ''}
            data-validation='${JSON.stringify(field.validation || {})}'
        `;

        switch (field.type) {
            case 'string':
                return `<input type="text" ${commonAttrs} value="${field.default || ''}" />`;
            
            case 'password':
                return `
                    <div class="password-input">
                        <input type="password" ${commonAttrs} value="${field.default || ''}" />
                        <button type="button" class="password-toggle" onclick="togglePassword('${fieldId}')">👁️</button>
                    </div>
                `;
            
            case 'number':
                const numAttrs = field.validation ? `
                    ${field.validation.min !== undefined ? `min="${field.validation.min}"` : ''}
                    ${field.validation.max !== undefined ? `max="${field.validation.max}"` : ''}
                ` : '';
                return `<input type="number" ${commonAttrs} ${numAttrs} value="${field.default || ''}" />`;
            
            case 'boolean':
                return `
                    <div class="checkbox-wrapper">
                        <input type="checkbox" ${commonAttrs} ${field.default ? 'checked' : ''} />
                        <span class="checkbox-label">${field.label}</span>
                    </div>
                `;
            
            case 'select':
                return `
                    <select ${commonAttrs}>
                        ${!field.required ? '<option value="">-- Select an option --</option>' : ''}
                        ${field.options.map(option => `
                            <option value="${option.value}" 
                                    ${option.value === field.default ? 'selected' : ''}
                                    ${option.description ? `title="${option.description}"` : ''}>
                                ${option.label}
                            </option>
                        `).join('')}
                    </select>
                `;
            
            case 'multiselect':
                return `
                    <div class="multiselect-wrapper">
                        ${field.options.map(option => `
                            <label class="multiselect-option">
                                <input type="checkbox" 
                                       name="${field.name}[]" 
                                       value="${option.value}"
                                       ${Array.isArray(field.default) && field.default.includes(option.value) ? 'checked' : ''} />
                                <span>${option.label}</span>
                                ${option.description ? `<small>${option.description}</small>` : ''}
                            </label>
                        `).join('')}
                    </div>
                `;
            
            case 'textarea':
                return `<textarea ${commonAttrs} rows="4">${field.default || ''}</textarea>`;
            
            case 'json':
                return `
                    <div class="json-editor-wrapper">
                        <textarea ${commonAttrs} class="json-editor" rows="6">${
                            field.default ? JSON.stringify(field.default, null, 2) : '{}'
                        }</textarea>
                        <div class="json-validation"></div>
                    </div>
                `;
            
            case 'list':
                return `
                    <div class="list-editor" data-field="${field.name}">
                        <div class="list-items">
                            ${Array.isArray(field.default) ? field.default.map((item, index) => `
                                <div class="list-item">
                                    <input type="text" value="${item}" />
                                    <button type="button" class="remove-item">✕</button>
                                </div>
                            `).join('') : ''}
                        </div>
                        <button type="button" class="add-item">+ Add Item</button>
                    </div>
                `;
            
            case 'map':
                return `
                    <div class="map-editor" data-field="${field.name}">
                        <div class="map-items">
                            ${field.default && typeof field.default === 'object' ? 
                                Object.entries(field.default).map(([key, value]) => `
                                    <div class="map-item">
                                        <input type="text" placeholder="Key" value="${key}" class="map-key" />
                                        <input type="text" placeholder="Value" value="${value}" class="map-value" />
                                        <button type="button" class="remove-item">✕</button>
                                    </div>
                                `).join('') : ''
                            }
                        </div>
                        <button type="button" class="add-map-item">+ Add Key-Value Pair</button>
                    </div>
                `;
            
            default:
                return `<input type="text" ${commonAttrs} value="${field.default || ''}" />`;
        }
    }

    /**
     * Generate form actions with user-friendly options
     */
    generateFormActions() {
        return `
            <div class="form-actions">
                <div class="action-buttons">
                    <button type="button" class="btn btn-secondary" onclick="resetForm()">
                        🔄 Reset to Defaults
                    </button>
                    <button type="button" class="btn btn-secondary" onclick="validateForm()">
                        ✅ Validate Configuration
                    </button>
                    <button type="button" class="btn btn-secondary" onclick="previewTerraform()">
                        👁️ Preview Terraform
                    </button>
                    <button type="submit" class="btn btn-primary">
                        🚀 Deploy Infrastructure
                    </button>
                </div>
                <div class="form-options">
                    <label class="option">
                        <input type="checkbox" id="save-as-template" />
                        💾 Save as template for future use
                    </label>
                    <label class="option">
                        <input type="checkbox" id="enable-notifications" checked />
                        🔔 Send deployment notifications
                    </label>
                </div>
            </div>
        `;
    }

    /**
     * Generate validation summary panel
     */
    generateValidationSummary() {
        return `
            <div class="validation-summary" id="validation-summary" style="display: none;">
                <h3>Validation Results</h3>
                <div class="validation-content">
                    <div class="validation-errors"></div>
                    <div class="validation-warnings"></div>
                    <div class="validation-success"></div>
                </div>
            </div>
        `;
    }

    // Utility methods for user-friendly display

    humanizeModuleName(name) {
        return name.split('-').map(word => 
            word.charAt(0).toUpperCase() + word.slice(1)
        ).join(' ');
    }

    humanizeSkillName(skill) {
        return skill.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
    }

    capitalizeFirst(str) {
        return str.charAt(0).toUpperCase() + str.slice(1);
    }

    slugify(text) {
        return text.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
    }

    getCostCategoryIcon(category) {
        const icons = {
            'free': '🆓',
            'low': '💚',
            'medium': '💛',
            'high': '🔴',
            'variable': '📊'
        };
        return icons[category] || '💰';
    }

    generateStarRating(rating) {
        const stars = [];
        for (let i = 1; i <= 5; i++) {
            if (i <= rating) {
                stars.push('⭐');
            } else {
                stars.push('☆');
            }
        }
        return stars.join('');
    }

    generateCloudProviderBadges() {
        const providers = this.metadata.module_info.cloud_providers || [];
        return providers.map(provider => `
            <span class="provider-badge provider-${provider}">
                ${this.getProviderIcon(provider)} ${provider.toUpperCase()}
            </span>
        `).join('');
    }

    getProviderIcon(provider) {
        const icons = {
            'aws': '☁️',
            'azure': '🔷',
            'gcp': '🌐'
        };
        return icons[provider] || '☁️';
    }
}

// Export for use in different environments
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PortalFormGenerator;
} else if (typeof window !== 'undefined') {
    window.PortalFormGenerator = PortalFormGenerator;
}