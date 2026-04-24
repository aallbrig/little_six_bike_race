// play-host.js - Handles Godot engine startup and host communication

const GODOT_CONFIG = {
    canvas: document.getElementById('godot-canvas'),
    canvasResizePolicy: 0, // Adaptive
    experimentalVK: false,
    focusCanvas: true,
    gdextensionLibs: [],
};

const loadingOverlay = document.getElementById('loading-overlay');
const exitButton = document.getElementById('exit-button');
const orientationHint = document.getElementById('orientation-hint');

let engine = null;

// Listen for messages from Godot
window.addEventListener('message', (event) => {
    if (event.origin !== window.location.origin) return;
    const msg = event.data;
    if (!msg || msg.source !== 'little-six-game' || msg.version !== 1) return;

    switch (msg.type) {
        case 'ready':
            hideLoadingOverlay();
            break;
        case 'quit':
            setTimeout(() => { window.location.href = '/'; }, 150);
            break;
        case 'orientation_request':
            if (msg.payload?.orientation === 'landscape') {
                showOrientationHint();
            }
            break;
        case 'analytics':
            // Stub for future analytics
            console.debug('Analytics:', msg.payload);
            break;
    }
});

// Exit button
exitButton.addEventListener('click', () => {
    // Simulate quit message
    window.postMessage({
        source: 'little-six-game',
        version: 1,
        type: 'quit',
        payload: { reason: 'user_exit' }
    }, window.location.origin);
});

// Start Godot
(async () => {
    try {
        const { Engine } = await import('/game/little_six.js');
        engine = new Engine(GODOT_CONFIG);
        await engine.start();
    } catch (error) {
        console.error('Failed to start Godot:', error);
        loadingOverlay.innerHTML = '<p>Error loading game. Please refresh.</p>';
    }
})();

function hideLoadingOverlay() {
    loadingOverlay.style.display = 'none';
}

function showOrientationHint() {
    orientationHint.hidden = false;
    // Auto-hide after 5 seconds
    setTimeout(() => { orientationHint.hidden = true; }, 5000);
}

// Handle canvas resizing and orientation
const resizeObserver = new ResizeObserver(() => {
    if (engine) {
        engine.requestAnimationFrame(() => {
            // Godot handles canvas resizing automatically in Compatibility renderer
            // But we can trigger it explicitly if needed
        });
    }
});
resizeObserver.observe(document.getElementById('game-root'));

// Handle orientation changes for mobile
window.addEventListener('orientationchange', () => {
    // Small delay to let viewport settle
    setTimeout(() => {
        if (engine) {
            engine.requestAnimationFrame(() => {
                // Force canvas resize on orientation change
            });
        }
    }, 100);
});

// Handle fullscreen API for mobile
document.addEventListener('fullscreenchange', () => {
    if (engine) {
        engine.requestAnimationFrame(() => {
            // Handle fullscreen state changes
        });
    }
});