const pianoKeys = document.querySelectorAll(".piano-keys .key");
const volumeSlider = document.querySelector(".volume-slider input");
const keysCheckbox = document.querySelector(".keys-checkbox input");

let allKeys = [];
let currentVolume = 0.5;
let keyStates = {};

function playTune(note, volume) {
    $.post('https://atiya-piano/playPianoNote', JSON.stringify({
        note: note,
        volume: volume
    }));

    const clickedKey = document.querySelector(`[data-key="${note}"]`);
    clickedKey.classList.add("active");

    setTimeout(() => {
        clickedKey.classList.remove("active");
    }, 100);
}

pianoKeys.forEach(key => {
    allKeys.push(key.dataset.key);

    key.addEventListener("mousedown", (e) => {
        e.preventDefault();
        if (!keyStates[key.dataset.key]) {
            keyStates[key.dataset.key] = true;
            playTune(key.dataset.key, currentVolume);
        }
    });

    key.addEventListener("mouseup", (e) => {
        e.preventDefault();
        keyStates[key.dataset.key] = false;
    });

    key.addEventListener("touchstart", (e) => {
        e.preventDefault();
        if (!keyStates[key.dataset.key]) {
            keyStates[key.dataset.key] = true;
            playTune(key.dataset.key, currentVolume);
        }
    });

    key.addEventListener("touchend", (e) => {
        e.preventDefault();
        keyStates[key.dataset.key] = false;
    });
});

const handleKeyDown = (e) => {
    if (allKeys.includes(e.key) && !keyStates[e.key]) {
        e.preventDefault();
        keyStates[e.key] = true;
        playTune(e.key, currentVolume);
    }
};

const handleKeyUp = (e) => {
    if (allKeys.includes(e.key)) {
        e.preventDefault();
        keyStates[e.key] = false;
    }
};

const handleVolume = (e) => {
    currentVolume = e.target.value;
};

const showHideKeys = () => {
    pianoKeys.forEach(key => key.classList.toggle("hide"));
};

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' || event.key === 'Backspace' || event.key === 'Enter') {
        $.post('https://atiya-piano/closePiano', JSON.stringify({}));
    }
});

window.addEventListener('message', function(event) {
    if (event.data.type === 'showPiano') {
        document.querySelector('.wrapper').style.display = 'block';
        document.getElementById('hint').style.display = 'block';
    }
});

window.addEventListener('message', function(event) {
    if (event.data.type === 'hidePiano') {
        document.querySelector('.wrapper').style.display = 'none';
        document.getElementById('hint').style.display = 'none';
    }
});

const debugDuration = 15000;
const pressInterval = 300;

const startDebugging = () => {
    const startTime = Date.now();
    const interval = setInterval(() => {
        if (Date.now() - startTime > debugDuration) {
            clearInterval(interval);
            console.log("Debugging ended.");
            return;
        }
        const randomKeyIndex = Math.floor(Math.random() * allKeys.length);
        const randomKey = allKeys[randomKeyIndex];
        if (!keyStates[randomKey]) {
            keyStates[randomKey] = true;
            playTune(randomKey, currentVolume);
            setTimeout(() => {
                keyStates[randomKey] = false;
            }, pressInterval - 50);
        }
    }, pressInterval);
    console.log("Debugging started.");
};

window.addEventListener('message', function(event) {
    if (event.data.action === "startDebugging") {
        startDebugging();
    }
});

document.addEventListener("keydown", handleKeyDown);
document.addEventListener("keyup", handleKeyUp);
volumeSlider.addEventListener("input", handleVolume);
keysCheckbox.addEventListener("click", showHideKeys);
