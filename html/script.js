const pianoKeys = document.querySelectorAll(".piano-keys .key");
const volumeSlider = document.querySelector(".volume-slider input");
const keysCheckbox = document.querySelector(".keys-checkbox input");

let allKeys = [];
let playedKeys = [];
let currentVolume = 0.5;
let keyStates = {};
var audioPlayer = {};

function playSound(note, volume) {
    if (audioPlayer[note]) {
        audioPlayer[note].stop();
    }
    audioPlayer[note] = new Howl({
        src: [`./notes/${note}.mp3`],
        volume: volume
    });
    audioPlayer[note].play();
}

window.addEventListener('message', function(event) {
    if (event.data.transactionType === 'playSound') {
        playSound(event.data.note, event.data.volume);
    }
});


const playTune = (key) => {
    $.post('https://atiya-piano/playPianoNote', JSON.stringify({
        note: key,
        volume: currentVolume
    }));

    $.post('https://atiya-piano/playSound', JSON.stringify({
        transactionFile: key,
        transactionVolume: currentVolume
    }));

    playedKeys.push(key);

    const clickedKey = document.querySelector(`[data-key="${key}"]`);
    clickedKey.classList.add("active");

    setTimeout(() => {
        clickedKey.classList.remove("active");
    }, 100);
};

pianoKeys.forEach(key => {
    allKeys.push(key.dataset.key);

    key.addEventListener("mousedown", (e) => {
        e.preventDefault();
        if (!keyStates[key.dataset.key]) {
            keyStates[key.dataset.key] = true;
            playTune(key.dataset.key);
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
            playTune(key.dataset.key);
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
        playTune(e.key);
    }
};

const handleKeyUp = (e) => {
    if (allKeys.includes(e.key)) {
        e.preventDefault();
        keyStates[e.key] = false;
    }
};

function delayDispatchKeyboardEvent(key, delay) {
    setTimeout(function() {
        document.dispatchEvent(new KeyboardEvent("keydown", { key: key }));
        playedKeys = [];
    }, delay);
}

const pressedKey = (e) => {
    if (allKeys.includes(e.key) && !isKeyPressed[e.key]) {
        playTune(e.key);
    }
};

const handleVolume = (e) => {
    currentVolume = e.target.value;
};

const showHideKeys = () => {
    pianoKeys.forEach(key => key.classList.toggle("hide"));
};

const play = () => {
    setTimeout(() => playTune("t"), 300);
    setTimeout(() => playTune("t"), 600);
    setTimeout(() => playTune("y"), 1000);
    setTimeout(() => playTune("t"), 1500);
    setTimeout(() => playTune("o"), 2000);
    setTimeout(() => playTune("i"), 2500);
    setTimeout(() => playTune("t"), 3000);
    setTimeout(() => playTune("t"), 3300);
    setTimeout(() => playTune("x"), 3700);
    setTimeout(() => playTune("p"), 4200);
    setTimeout(() => playTune("i"), 4600);
    setTimeout(() => playTune("u"), 5000);
    setTimeout(() => playTune("y"), 5450);
    setTimeout(() => playTune("z"), 6000);
    setTimeout(() => playTune("z"), 6300);
    setTimeout(() => playTune("p"), 6800);
    setTimeout(() => playTune("i"), 7400);
    setTimeout(() => playTune("o"), 7900);
    setTimeout(() => playTune("i"), 8500);
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

window.addEventListener('message', function(event) {
    if (event.data.transactionType === 'playSound') {
        playSound(event.data.note, event.data.volume);
    }
});

document.addEventListener("keydown", handleKeyDown);
document.addEventListener("keyup", handleKeyUp);
volumeSlider.addEventListener("input", handleVolume);
keysCheckbox.addEventListener("click", showHideKeys);