import Foundation

enum RemoteControlHTML {
    static let page = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
        <title>Rec Remote</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'SF Pro', sans-serif;
                background: #1a1a1a;
                color: #fff;
                height: 100vh;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                padding: 24px;
                -webkit-user-select: none;
                user-select: none;
            }
            .logo {
                font-size: 28px;
                font-weight: 700;
                letter-spacing: -0.5px;
                margin-bottom: 8px;
            }
            .status {
                font-size: 14px;
                color: #888;
                margin-bottom: 40px;
            }
            .status .dot {
                display: inline-block;
                width: 8px;
                height: 8px;
                border-radius: 50%;
                background: #30d158;
                margin-right: 6px;
                vertical-align: middle;
            }
            .controls {
                display: flex;
                flex-direction: column;
                gap: 16px;
                width: 100%;
                max-width: 320px;
            }
            .btn-row {
                display: flex;
                gap: 12px;
            }
            button {
                flex: 1;
                padding: 18px 16px;
                border: none;
                border-radius: 14px;
                font-size: 17px;
                font-weight: 600;
                cursor: pointer;
                transition: transform 0.1s, opacity 0.1s;
                -webkit-tap-highlight-color: transparent;
            }
            button:active {
                transform: scale(0.96);
                opacity: 0.8;
            }
            .btn-primary {
                background: #0a84ff;
                color: #fff;
            }
            .btn-danger {
                background: #ff453a;
                color: #fff;
            }
            .btn-secondary {
                background: #2c2c2e;
                color: #fff;
            }
            .btn-play {
                padding: 24px;
                font-size: 20px;
            }
            .speed-display {
                text-align: center;
                font-size: 48px;
                font-weight: 200;
                font-variant-numeric: tabular-nums;
                margin: 8px 0;
            }
            .speed-label {
                text-align: center;
                font-size: 13px;
                color: #888;
                text-transform: uppercase;
                letter-spacing: 1px;
                margin-bottom: 4px;
            }
            .script-name {
                text-align: center;
                font-size: 15px;
                color: #aaa;
                margin-top: 24px;
                padding: 12px;
                background: #2c2c2e;
                border-radius: 10px;
                width: 100%;
                max-width: 320px;
            }
        </style>
    </head>
    <body>
        <div class="logo">Rec</div>
        <div class="status"><span class="dot"></span><span id="statusText">Connected</span></div>

        <div class="controls">
            <button class="btn-primary btn-play" id="playPauseBtn" onclick="togglePlayPause()">
                Pause
            </button>

            <div class="speed-label">Speed</div>
            <div class="speed-display" id="speedDisplay">2.0x</div>

            <div class="btn-row">
                <button class="btn-secondary" onclick="speedDown()">Slower</button>
                <button class="btn-secondary" onclick="speedUp()">Faster</button>
            </div>

            <button class="btn-danger" onclick="stopPrompt()">Stop</button>
        </div>

        <div class="script-name" id="scriptName">No script loaded</div>

        <script>
            let isPlaying = true;

            async function send(endpoint) {
                try {
                    const res = await fetch(endpoint, { method: 'POST' });
                    return await res.json();
                } catch (e) {
                    document.getElementById('statusText').textContent = 'Disconnected';
                    return null;
                }
            }

            async function togglePlayPause() {
                const btn = document.getElementById('playPauseBtn');
                if (isPlaying) {
                    await send('/pause');
                    btn.textContent = 'Play';
                    isPlaying = false;
                } else {
                    await send('/play');
                    btn.textContent = 'Pause';
                    isPlaying = true;
                }
            }

            async function speedUp() {
                const data = await send('/speed-up');
                if (data) updateSpeed(data.speed);
            }

            async function speedDown() {
                const data = await send('/speed-down');
                if (data) updateSpeed(data.speed);
            }

            async function stopPrompt() {
                await send('/stop');
                document.getElementById('playPauseBtn').textContent = 'Play';
                isPlaying = false;
            }

            function updateSpeed(speed) {
                document.getElementById('speedDisplay').textContent = speed.toFixed(1) + 'x';
            }

            async function pollStatus() {
                try {
                    const res = await fetch('/status');
                    const data = await res.json();
                    isPlaying = data.playing;
                    document.getElementById('playPauseBtn').textContent = isPlaying ? 'Pause' : 'Play';
                    updateSpeed(data.speed);
                    document.getElementById('scriptName').textContent = data.script || 'No script loaded';
                    document.getElementById('statusText').textContent = 'Connected';
                } catch (e) {
                    document.getElementById('statusText').textContent = 'Disconnected';
                }
            }

            setInterval(pollStatus, 2000);
            pollStatus();
        </script>
    </body>
    </html>
    """
}
