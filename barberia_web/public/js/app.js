/**
 * Barbería T13 - Frontend Utilities
 * Funciones compartidas para todas las páginas
 */

// API Base URL
const API_BASE = '';

/**
 * Fetch wrapper con manejo de errores
 */
async function fetchAPI(endpoint) {
    try {
        const response = await fetch(API_BASE + endpoint);
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        return await response.json();
    } catch (error) {
        console.error('API Error:', error);
        return [];
    }
}

/**
 * Mostrar alerta en la página
 */
function showAlert(message, type = 'info') {
    const container = document.getElementById('alertContainer');
    if (!container) return;

    const alert = document.createElement('div');
    alert.className = `alert alert-${type}`;
    alert.innerHTML = message;
    container.innerHTML = '';
    container.appendChild(alert);

    // Auto-remove after 5 seconds
    setTimeout(() => {
        alert.remove();
    }, 5000);
}

/**
 * Formatear moneda
 */
function formatCurrency(value) {
    return '$' + parseFloat(value || 0).toFixed(2);
}

/**
 * Formatear fecha
 */
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('es-EC', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
    });
}

/**
 * Formatear fecha y hora
 */
function formatDateTime(dateString) {
    const date = new Date(dateString);
    return date.toLocaleString('es-EC', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

console.log('Barbería T13 - Frontend Ready');
