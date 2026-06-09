import { REOWN_PROJECT_ID } from './constants';
import { setupUi } from './ui';
import { CardanoDappClient } from './wc-client';

const envProjectId = import.meta.env.VITE_REOWN_PROJECT_ID as string | undefined;
const projectId =
  envProjectId && envProjectId !== 'your_project_id_here'
    ? envProjectId
    : REOWN_PROJECT_ID;
const logEl = document.getElementById('log')!;

function appendLog(message: string, data?: unknown): void {
  const timestamp = new Date().toISOString().slice(11, 19);
  let line = `[${timestamp}] ${message}`;
  if (data !== undefined) {
    line += `\n${JSON.stringify(data, null, 2)}`;
  }
  logEl.textContent = `${line}\n\n${logEl.textContent}`;
}

async function main(): Promise<void> {
  const client = new CardanoDappClient(appendLog);
  await client.init(projectId);
  setupUi(client, logEl);
  appendLog('Ready — click Connect and scan QR with the example wallet app');
}

void main();
