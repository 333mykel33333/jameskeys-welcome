const app = document.getElementById('app');
const dialog = app.querySelector('[role="dialog"]');
const vehicleContainer = document.getElementById('vehicles');
const claimForm = document.getElementById('claim-form');
const claimButton = document.getElementById('claim-button');
const statusText = document.getElementById('status');
const soundToggle = document.getElementById('sound-toggle');
const footerState = document.getElementById('footer-state');

const showcaseVehicles = [
    {
        model: 'bbghost2',
        label: 'Rolls-Royce Ghost',
        subtitle: 'A custom animated luxury sedan',
    },
    {
        model: 'dc_rs7animated',
        label: 'Audi RS7 Mansory',
        subtitle: 'A custom animated performance sedan',
    },
    {
        model: 'm2',
        label: 'BMW M2',
        subtitle: 'A custom animated sports coupe',
    },
];

const profiles = {
    bbghost2: {
        make: 'ROLLS-ROYCE / BESPOKE',
        name: 'Ghost',
        className: 'ULTRA-LUXURY',
        copy: 'Quiet confidence with a custom animated finish. A statement ride for your first chapter in the city.',
        image: 'assets/rolls-royce-ghost.png',
    },
    dc_rs7animated: {
        make: 'AUDI / MANSORY',
        name: 'RS7 Mansory',
        className: 'SPORT / SEDAN',
        copy: 'A custom animated performance sedan with sharp lines and a presence that does the talking.',
        image: 'assets/audi-rs7.png',
    },
    m2: {
        make: 'BMW / M PERFORMANCE',
        name: 'M2',
        className: 'SPORT / COUPE',
        copy: 'Compact, focused and built to make every drive through the city feel like your own.',
        image: 'assets/bmw-m2.png',
    },
};

let selectedVehicle = null;
let vehicles = [];
let alreadyClaimed = false;
let requestPending = false;
let soundEnabled = true;
let audioContext;
let lastHoverSoundAt = 0;

function createAmbientParticles() {
    const layer = document.getElementById('ambient-particles');
    if (!layer) return;

    for (let index = 0; index < 26; index += 1) {
        const particle = document.createElement('span');
        const position = (index * 37 + 11) % 100;
        const vertical = (index * 61 + 19) % 100;
        const size = index % 7 === 0 ? 3 : 2;
        const opacity = index % 5 === 0 ? 0.62 : 0.38;
        const hue = 'rgba(255, 128, 0, .98)';

        particle.className = 'ambient-particle';
        particle.style.setProperty('--particle-x', `${position}%`);
        particle.style.setProperty('--particle-y', `${vertical}%`);
        particle.style.setProperty('--particle-size', `${size}px`);
        particle.style.setProperty('--particle-duration', `${8 + (index % 7) * 1.4}s`);
        particle.style.setProperty('--particle-delay', `${-(index % 11) * 0.8}s`);
        particle.style.setProperty('--particle-drift', `${(index % 2 ? 1 : -1) * (8 + index % 17)}px`);
        particle.style.setProperty('--particle-opacity', String(opacity));
        particle.style.setProperty('--particle-color', hue);
        particle.style.setProperty('--particle-glow', hue);
        layer.append(particle);
    }
}

function postNui(eventName, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${eventName}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    });
}

function playSound(kind) {
    if (!soundEnabled) return;

    try {
        const AudioContextClass = window.AudioContext || window.webkitAudioContext;
        if (!AudioContextClass) return;

        if (!audioContext) {
            audioContext = new AudioContextClass();
        }

        if (audioContext.state === 'suspended') {
            audioContext.resume().catch(() => {});
        }

        const now = audioContext.currentTime;
        const notes = {
            hover: [{ frequency: 740, duration: 0.035, volume: 0.012 }],
            select: [
                { frequency: 520, duration: 0.065, volume: 0.027 },
                { frequency: 790, duration: 0.09, volume: 0.022, delay: 0.045 },
            ],
            claim: [
                { frequency: 440, duration: 0.09, volume: 0.027 },
                { frequency: 660, duration: 0.12, volume: 0.024, delay: 0.075 },
                { frequency: 880, duration: 0.16, volume: 0.019, delay: 0.15 },
            ],
            close: [{ frequency: 490, endFrequency: 300, duration: 0.095, volume: 0.018 }],
        };

        for (const note of notes[kind] || []) {
            const startAt = now + (note.delay || 0);
            const oscillator = audioContext.createOscillator();
            const gain = audioContext.createGain();
            oscillator.type = 'sine';
            oscillator.frequency.setValueAtTime(note.frequency, startAt);
            if (note.endFrequency) {
                oscillator.frequency.exponentialRampToValueAtTime(
                    note.endFrequency,
                    startAt + note.duration
                );
            }
            gain.gain.setValueAtTime(0.0001, startAt);
            gain.gain.exponentialRampToValueAtTime(note.volume, startAt + 0.012);
            gain.gain.exponentialRampToValueAtTime(0.0001, startAt + note.duration);
            oscillator.connect(gain);
            gain.connect(audioContext.destination);
            oscillator.start(startAt);
            oscillator.stop(startAt + note.duration + 0.01);
        }
    } catch {
        // Audio is an enhancement; unsupported or blocked audio must not interrupt the claim UI.
    }
}

function setStatus(message, kind = '') {
    statusText.textContent = message;
    statusText.classList.toggle('error', kind === 'error');
    statusText.classList.toggle('success', kind === 'success');
}

function setFooterState(message) {
    footerState.lastChild.textContent = ` ${message}`;
}

function createMiniCar() {
    const namespace = 'http://www.w3.org/2000/svg';
    const svg = document.createElementNS(namespace, 'svg');
    svg.setAttribute('class', 'mini-car');
    svg.setAttribute('viewBox', '0 0 150 70');
    svg.setAttribute('aria-hidden', 'true');

    const path = document.createElementNS(namespace, 'path');
    path.setAttribute('class', 'body');
    path.setAttribute('d', 'M12 45 20 30q2-5 9-7l22-5 14-13q3-3 8-3h24q7 0 12 6l13 15 14 4q4 1 5 6l3 11-7 6h-9a11 11 0 0 0-22 0H47a11 11 0 0 0-22 0h-8l-7-5z');

    const windowPath = document.createElementNS(namespace, 'path');
    windowPath.setAttribute('class', 'window');
    windowPath.setAttribute('d', 'm55 20 13-12q2-2 5-2h19v15H55zm41-14h9q4 0 7 4l10 11H96z');

    const detail = document.createElementNS(namespace, 'path');
    detail.setAttribute('class', 'detail');
    detail.setAttribute('d', 'm20 34 32-2m40-9v16m21-16v16m-68-9h4m57 0h15');

    svg.append(path, windowPath, detail);
    for (const x of [36, 113]) {
        const wheel = document.createElementNS(namespace, 'circle');
        wheel.setAttribute('class', 'wheel');
        wheel.setAttribute('cx', String(x));
        wheel.setAttribute('cy', '48');
        wheel.setAttribute('r', '10');
        const rim = document.createElementNS(namespace, 'circle');
        rim.setAttribute('class', 'rim');
        rim.setAttribute('cx', String(x));
        rim.setAttribute('cy', '48');
        rim.setAttribute('r', '4');
        svg.append(wheel, rim);
    }

    return svg;
}

function updateProfile(vehicle, index) {
    const profile = profiles[vehicle.model] || {
        make: 'JAMESKEYS / CUSTOM',
        name: vehicle.label,
        className: 'CUSTOM VEHICLE',
        copy: vehicle.subtitle,
    };

    document.getElementById('profile-make').textContent = profile.make;
    document.getElementById('profile-name').textContent = profile.name;
    document.getElementById('profile-class').textContent = profile.className;
    document.getElementById('profile-copy').textContent = profile.copy;
    document.getElementById('profile-number').textContent = `JK-0${index + 1}`;
    document.getElementById('selected-description').textContent =
        `${vehicle.label} reserved as your welcome vehicle`;
    document.getElementById('selected-count').textContent = '1';

    const profileImage = document.getElementById('profile-image');
    const fallbackArt = document.querySelector('.car-art');
    profileImage.hidden = true;
    fallbackArt.hidden = false;
    profileImage.onload = () => {
        profileImage.hidden = false;
        fallbackArt.hidden = true;
    };
    profileImage.onerror = () => {
        profileImage.hidden = true;
        fallbackArt.hidden = false;
    };
    profileImage.src = profile.image;
}

function selectVehicle(model) {
    const cards = [...vehicleContainer.querySelectorAll('.vehicle-card')];
    const index = cards.findIndex((card) => card.dataset.model === model);
    if (index < 0) return;

    selectedVehicle = model;
    const vehicle = vehicles[index];
    for (const card of cards) {
        const selected = card.dataset.model === model;
        card.classList.toggle('selected', selected);
        card.setAttribute('aria-pressed', String(selected));
    }
    updateProfile(vehicle, index);
    claimButton.disabled = alreadyClaimed || requestPending;
    playSound('select');
}

function renderVehicles(vehicleData) {
    vehicles = vehicleData;
    vehicleContainer.replaceChildren();
    selectedVehicle = null;
    claimButton.disabled = true;
    document.getElementById('selected-count').textContent = '0';
    document.getElementById('profile-make').textContent = 'SELECT A VEHICLE';
    document.getElementById('profile-name').textContent = 'Your ride awaits';
    document.getElementById('profile-class').textContent = '—';
    document.getElementById('profile-copy').textContent =
        'Choose one of the available vehicles to view its profile.';
    document.getElementById('profile-number').textContent = '—';
    document.getElementById('selected-description').textContent =
        'Select a vehicle to reserve your choice';
    const profileImage = document.getElementById('profile-image');
    profileImage.hidden = true;
    profileImage.removeAttribute('src');
    document.querySelector('.car-art').hidden = false;

    vehicles.forEach((vehicle, index) => {
        const card = document.createElement('button');
        card.type = 'button';
        card.className = 'vehicle-card';
        card.dataset.model = vehicle.model;
        card.setAttribute('aria-pressed', 'false');
        card.setAttribute('aria-label', `${vehicle.label}. ${vehicle.subtitle}`);

        const top = document.createElement('span');
        top.className = 'vehicle-card-top';
        const indexLabel = document.createElement('span');
        indexLabel.className = 'vehicle-index';
        indexLabel.textContent = `AVAILABLE / 0${index + 1}`;
        const badge = document.createElement('span');
        badge.className = 'vehicle-badge';
        badge.textContent = vehicle.model === 'm2' ? 'SPORT' : 'CUSTOM';
        top.append(indexLabel, badge);

        const visual = document.createElement('span');
        visual.className = 'vehicle-visual';
        const fallbackCar = createMiniCar();
        const photo = document.createElement('img');
        photo.className = 'vehicle-photo';
        photo.src = profiles[vehicle.model]?.image || '';
        photo.alt = '';
        photo.setAttribute('aria-hidden', 'true');
        photo.addEventListener('load', () => fallbackCar.hidden = true);
        photo.addEventListener('error', () => {
            photo.hidden = true;
            fallbackCar.hidden = false;
        });
        visual.append(fallbackCar, photo);

        const name = document.createElement('span');
        name.className = 'vehicle-name';
        name.textContent = vehicle.label;
        const description = document.createElement('span');
        description.className = 'vehicle-description';
        description.textContent = vehicle.subtitle;
        const selectedLabel = document.createElement('span');
        selectedLabel.className = 'vehicle-selected-label';
        selectedLabel.textContent = '✓ SELECTED';

        card.append(top, visual, name, description, selectedLabel);
        card.addEventListener('pointerenter', () => {
            const now = performance.now();
            if (now - lastHoverSoundAt > 120) {
                lastHoverSoundAt = now;
                playSound('hover');
            }
        });
        card.addEventListener('click', () => selectVehicle(vehicle.model));
        vehicleContainer.append(card);
    });
}

function getFocusableElements() {
    return [...dialog.querySelectorAll('button:not(:disabled), input:not(:disabled), a[href]')]
        .filter((element) => element.getClientRects().length > 0);
}

function closeMenu() {
    if (app.classList.contains('is-hidden')) return;
    playSound('close');
    app.classList.add('is-hidden');
    app.setAttribute('aria-hidden', 'true');
    postNui('close');
}

function hideMenu() {
    app.classList.add('is-hidden');
    app.setAttribute('aria-hidden', 'true');
}

document.getElementById('close').addEventListener('click', closeMenu);

soundToggle.addEventListener('click', () => {
    soundEnabled = !soundEnabled;
    soundToggle.setAttribute('aria-pressed', String(soundEnabled));
    soundToggle.setAttribute(
        'aria-label',
        `Turn interface sounds ${soundEnabled ? 'off' : 'on'}`
    );
    soundToggle.title = `Interface sounds ${soundEnabled ? 'on' : 'off'}`;
    if (soundEnabled) playSound('select');
});

claimForm.addEventListener('submit', (event) => {
    event.preventDefault();
    if (alreadyClaimed || requestPending) return;
    if (!selectedVehicle) {
        setStatus('Choose one of the three vehicles first.', 'error');
        vehicleContainer.querySelector('.vehicle-card')?.focus();
        return;
    }
    requestPending = true;
    claimButton.disabled = true;
    setFooterState('VERIFYING CLAIM');
    setStatus('Securing your vehicle and rewards…');
    playSound('claim');
    postNui('claim', {
        vehicle: selectedVehicle,
    }).catch(() => {
        requestPending = false;
        claimButton.disabled = alreadyClaimed || !selectedVehicle;
        setFooterState('SYSTEM READY');
        setStatus('Unable to reach the claim service. Please try again.', 'error');
    });
});

window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || typeof data !== 'object') return;

    if (data.action === 'open') {
        app.classList.remove('is-hidden');
        app.setAttribute('aria-hidden', 'false');
        alreadyClaimed = data.alreadyClaimed === true;
        requestPending = false;
        claimButton.disabled = alreadyClaimed;
        setFooterState(alreadyClaimed ? 'CLAIM ALREADY USED' : 'SYSTEM READY');
        const availableVehicles = Array.isArray(data.vehicles) && data.vehicles.length > 0
            ? data.vehicles
            : showcaseVehicles;
        renderVehicles(availableVehicles);
        setStatus(
            alreadyClaimed ? 'This character has already claimed the welcome drop.' : '',
            alreadyClaimed ? 'error' : ''
        );
        const firstVehicle = vehicleContainer.querySelector('.vehicle-card');
        (alreadyClaimed ? document.getElementById('close') : firstVehicle || document.getElementById('close')).focus();
        postNui('opened', { requestId: data.requestId }).catch((error) => {
            console.warn('Welcome UI could not confirm that it rendered.', error);
        });
    }

    if (data.action === 'hide') hideMenu();

    if (data.action === 'claimResult') {
        requestPending = false;
        if (data.success) alreadyClaimed = true;
        claimButton.disabled = alreadyClaimed;
        setFooterState(data.success ? 'CLAIM CONFIRMED' : 'SYSTEM READY');
        setStatus(data.message || '', data.success ? 'success' : 'error');
    }
});

window.addEventListener('keydown', (event) => {
    if (app.classList.contains('is-hidden')) return;
    if (event.key === 'Escape') {
        event.preventDefault();
        closeMenu();
        return;
    }

    if (event.key !== 'Tab') return;
    const focusable = getFocusableElements();
    if (focusable.length === 0) {
        event.preventDefault();
        dialog.focus();
        return;
    }

    const first = focusable[0];
    const last = focusable[focusable.length - 1];
    if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
    } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
    }
});

function signalNuiReady() {
    postNui('ready')
        .then((response) => {
            if (!response.ok) {
                throw new Error(`NUI ready callback returned ${response.status}`);
            }
        })
        .catch((error) => {
            console.warn('Welcome UI could not signal readiness to the game client; retrying.', error);
            window.setTimeout(signalNuiReady, 1000);
        });
}

createAmbientParticles();
signalNuiReady();
