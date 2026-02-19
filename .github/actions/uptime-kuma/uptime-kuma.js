const { io } = require("socket.io-client");

const ACTION = process.env.INPUT_ACTION;
const KUMA_URL = process.env.INPUT_KUMA_URL;
const MONITOR_IDS = process.env.INPUT_MONITOR_IDS;
const USERNAME = process.env.INPUT_KUMA_USERNAME;
const PASSWORD = process.env.INPUT_KUMA_PASSWORD;
const TIMEOUT = parseInt(process.env.INPUT_TIMEOUT || "30", 10) * 1000;
const DEBUG = process.env.INPUT_DEBUG === "true";

function log(msg) {
  console.log(msg);
}

function debug(msg) {
  if (DEBUG) console.log(`[debug] ${msg}`);
}

function validate() {
  if (!ACTION || !["pause", "resume"].includes(ACTION)) {
    throw new Error(`Invalid action: "${ACTION}". Must be "pause" or "resume".`);
  }
  if (!KUMA_URL) {
    throw new Error("kuma-url is required.");
  }
  if (!MONITOR_IDS) {
    throw new Error("monitor-ids is required.");
  }
  if (!USERNAME || !PASSWORD) {
    throw new Error("KUMA_USERNAME and KUMA_PASSWORD secrets are required.");
  }
}

function parseMonitorIds(input) {
  return input
    .split(",")
    .map((id) => id.trim())
    .filter((id) => id.length > 0)
    .map((id) => {
      const num = parseInt(id, 10);
      if (isNaN(num)) {
        throw new Error(`Invalid monitor ID: "${id}". Must be a number.`);
      }
      return num;
    });
}

function connectAndAuthenticate() {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      reject(new Error(`Connection to ${KUMA_URL} timed out after ${TIMEOUT / 1000}s`));
    }, TIMEOUT);

    debug(`Connecting to ${KUMA_URL}`);

    const socket = io(KUMA_URL, {
      reconnection: false,
      timeout: TIMEOUT,
      transports: ["websocket"],
    });

    socket.on("connect_error", (err) => {
      clearTimeout(timer);
      reject(new Error(`Failed to connect to ${KUMA_URL}: ${err.message}`));
    });

    socket.on("connect", () => {
      debug("Connected, authenticating...");

      socket.emit("login", { username: USERNAME, password: PASSWORD }, (res) => {
        clearTimeout(timer);
        if (res.ok) {
          debug("Authenticated successfully");
          resolve(socket);
        } else {
          socket.disconnect();
          reject(new Error(`Authentication failed: ${res.msg}`));
        }
      });
    });
  });
}

function performAction(socket, monitorId, action) {
  const event = action === "pause" ? "pauseMonitor" : "resumeMonitor";

  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      reject(new Error(`${action} monitor ${monitorId} timed out`));
    }, TIMEOUT);

    socket.emit(event, monitorId, (res) => {
      clearTimeout(timer);
      if (res.ok) {
        resolve({ id: monitorId, success: true });
      } else {
        resolve({ id: monitorId, success: false, error: res.msg });
      }
    });
  });
}

async function run() {
  validate();

  const ids = parseMonitorIds(MONITOR_IDS);
  log(`Action: ${ACTION}`);
  log(`Uptime Kuma: ${KUMA_URL}`);
  log(`Monitors: ${ids.join(", ")}`);

  const socket = await connectAndAuthenticate();

  const results = [];
  for (const id of ids) {
    debug(`${ACTION === "pause" ? "Pausing" : "Resuming"} monitor ${id}...`);
    const result = await performAction(socket, id, ACTION);
    results.push(result);

    if (result.success) {
      log(`  Monitor ${id}: ${ACTION}d`);
    } else {
      log(`  Monitor ${id}: failed - ${result.error}`);
    }
  }

  socket.disconnect();

  const succeeded = results.filter((r) => r.success);
  const failed = results.filter((r) => !r.success);

  log("");
  log(`${ACTION === "pause" ? "Paused" : "Resumed"} ${succeeded.length}/${results.length} monitors`);

  if (failed.length > 0) {
    log("");
    log("Failed monitors:");
    for (const f of failed) {
      log(`  - ${f.id}: ${f.error}`);
    }
    process.exit(1);
  }
}

run().catch((err) => {
  console.error(`Error: ${err.message}`);
  process.exit(1);
});
