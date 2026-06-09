import QRCode from 'qrcode';

import { READ_METHODS } from './constants';
import type { CardanoDappClient } from './wc-client';

const UNSIGNED_TX_FIXTURE_PATH = '/fixtures/unsigned-tx.hex';
const SIGN_DATA_PAYLOAD_HEX = '48656c6c6f2057616c6c6574436f6e6e656374';
const CARDANOSCAN_PREPROD_TX_BASE = 'https://preprod.cardanoscan.io/transaction/';

export function setupUi(client: CardanoDappClient, logEl: HTMLElement): void {
  const statusEl = document.getElementById('status')!;
  const connectBtn = document.getElementById('btn-connect') as HTMLButtonElement;
  const qrContainer = document.getElementById('qr-container')!;
  const qrCanvas = document.getElementById('qr-canvas') as HTMLCanvasElement;
  const uriTextarea = document.getElementById('wc-uri') as HTMLTextAreaElement;
  const sessionInfo = document.getElementById('session-info')!;
  const methodsSection = document.getElementById('methods-section')!;
  const writeSection = document.getElementById('write-section')!;
  const submitBtn = document.getElementById('btn-submit-tx') as HTMLButtonElement;
  const txStatusEl = document.getElementById('tx-status')!;

  let cachedPaymentAddressHex: string | null = null;
  let cachedUnsignedTxHex: string | null = null;
  let signedWitnessHex: string | null = null;

  client.setSessionListener((connected) => {
    updateConnectionUi(connected);
  });

  connectBtn.addEventListener('click', async () => {
    if (client.isConnected) {
      await client.disconnect();
      qrContainer.classList.add('hidden');
      sessionInfo.classList.add('hidden');
      connectBtn.textContent = 'Connect via WalletConnect';
      return;
    }

    try {
      connectBtn.disabled = true;
      const { uri } = await client.connect();
      uriTextarea.value = uri;
      await QRCode.toCanvas(qrCanvas, uri, { width: 280, margin: 2 });
      qrContainer.classList.remove('hidden');
      connectBtn.textContent = 'Waiting for wallet…';
    } catch (error) {
      logEl.textContent += `\nERROR: ${String(error)}\n`;
      connectBtn.disabled = false;
    }
  });

  function updateConnectionUi(connected: boolean): void {
    connectBtn.disabled = false;

    if (connected) {
      statusEl.textContent = 'Connected';
      statusEl.className = 'status status-connected';
      connectBtn.textContent = 'Disconnect';
      methodsSection.classList.remove('hidden');
      writeSection.classList.remove('hidden');
      sessionInfo.classList.remove('hidden');
      sessionInfo.innerHTML = `
        <p><strong>Chain:</strong> cip34:0-1 (preprod)</p>
        <p><strong>Accounts:</strong></p>
        <ul>${client.connectedAccounts.map((a) => `<li><code>${a}</code></li>`).join('')}</ul>
      `;
      qrContainer.classList.add('hidden');
    } else {
      statusEl.textContent = 'Not connected';
      statusEl.className = 'status status-idle';
      connectBtn.textContent = 'Connect via WalletConnect';
      methodsSection.classList.add('hidden');
      writeSection.classList.add('hidden');
      sessionInfo.classList.add('hidden');
      clearTxStatus();
      cachedPaymentAddressHex = null;
      signedWitnessHex = null;
      submitBtn.disabled = true;
    }
  }

  document.querySelectorAll<HTMLButtonElement>('[data-method]').forEach((btn) => {
    btn.addEventListener('click', async () => {
      const method = btn.dataset.method!;
      btn.disabled = true;
      try {
        await invokeMethod(method);
      } catch (error) {
        logEl.textContent += `\nERROR (${method}): ${String(error)}\n`;
      } finally {
        btn.disabled = false;
        if (method === 'cardano_signTx') {
          submitBtn.disabled = signedWitnessHex == null;
        }
      }
    });
  });

  document.getElementById('btn-run-read')!.addEventListener('click', async () => {
    const btn = document.getElementById('btn-run-read') as HTMLButtonElement;
    btn.disabled = true;
    try {
      for (const method of READ_METHODS) {
        await invokeMethod(method);
      }
    } catch (error) {
      logEl.textContent += `\nERROR (run all): ${String(error)}\n`;
    } finally {
      btn.disabled = false;
    }
  });

  async function invokeMethod(method: string): Promise<void> {
    switch (method) {
      case 'cardano_signTx': {
        // CIP-30 requires a tx param; the wallet rebuilds from live Koios UTXOs.
        cachedUnsignedTxHex = null;
        const txHex = await loadUnsignedTxFixture();
        signedWitnessHex = await client.signTx(txHex, false);
        submitBtn.disabled = false;
        clearTxStatus();
        break;
      }
      case 'cardano_signData': {
        const addressHex = await resolvePaymentAddressHex();
        await client.signData(addressHex, SIGN_DATA_PAYLOAD_HEX);
        break;
      }
      case 'cardano_submitTx': {
        if (!signedWitnessHex) {
          throw new Error('Sign the transaction first with signTx');
        }
        showTxSubmitting();
        try {
          const txHex = await loadUnsignedTxFixture();
          const txHash = await client.submitTx(txHex);
          showTxSuccess(txHash);
        } catch (error) {
          showTxFailure(error);
          throw error;
        }
        break;
      }
      default:
        await client.request(method);
    }
  }

  function clearTxStatus(): void {
    txStatusEl.className = 'tx-status hidden';
    txStatusEl.innerHTML = '';
  }

  function showTxSubmitting(): void {
    txStatusEl.className = 'tx-status tx-status--pending';
    txStatusEl.innerHTML = '<p><strong>Submitting transaction…</strong></p>';
  }

  function showTxSuccess(txHash: string): void {
    const url = `${CARDANOSCAN_PREPROD_TX_BASE}${txHash}`;
    txStatusEl.className = 'tx-status tx-status--success';
    txStatusEl.innerHTML = `
      <p><strong>Transaction submitted successfully</strong></p>
      <p><code>${txHash}</code></p>
      <p><a href="${url}" target="_blank" rel="noopener noreferrer">View on preprod Cardanoscan</a></p>
    `;
  }

  function showTxFailure(error: unknown): void {
    txStatusEl.className = 'tx-status tx-status--error';
    txStatusEl.innerHTML = `
      <p><strong>Transaction submit failed</strong></p>
      <p>${escapeHtml(formatUiError(error))}</p>
      <p class="hint">Try signTx again to build a fresh transaction from current UTXOs.</p>
    `;
  }

  function formatUiError(error: unknown): string {
    if (error == null) return 'Unknown error';
    if (typeof error === 'string') return error;
    if (error instanceof Error) return error.message;
    if (typeof error === 'object') {
      const record = error as Record<string, unknown>;
      if (typeof record.message === 'string') return record.message;
    }
    return String(error);
  }

  function escapeHtml(text: string): string {
    return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
  }

  async function resolvePaymentAddressHex(): Promise<string> {
    if (cachedPaymentAddressHex) return cachedPaymentAddressHex;
    const used = await client.request<string[]>('cardano_getUsedAddresses');
    if (!used?.length) {
      cachedPaymentAddressHex = await client.request<string>(
        'cardano_getChangeAddress',
      );
    } else {
      cachedPaymentAddressHex = used[0]!;
    }
    return cachedPaymentAddressHex;
  }

  async function loadUnsignedTxFixture(): Promise<string> {
    if (cachedUnsignedTxHex) return cachedUnsignedTxHex;
    const response = await fetch(UNSIGNED_TX_FIXTURE_PATH);
    if (!response.ok) {
      throw new Error(
        `Missing unsigned tx fixture at ${UNSIGNED_TX_FIXTURE_PATH}. ` +
          'Run the faucet + fixture setup in docs/milestone-1-demo.md.',
      );
    }
    cachedUnsignedTxHex = (await response.text())
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line.length > 0 && !line.startsWith('#'))
      .join('');
    if (!cachedUnsignedTxHex) {
      throw new Error('unsigned-tx.hex fixture is empty');
    }
    return cachedUnsignedTxHex;
  }
}
