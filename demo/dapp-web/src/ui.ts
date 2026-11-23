import QRCode from 'qrcode';

import { READ_METHODS } from './constants';
import { requireElement } from './dom';
import { attachWitnesses, buildSelfTransfer } from './tx';
import type { CardanoDappClient } from './wc-client';

const SIGN_DATA_PAYLOAD_HEX = '48656c6c6f2057616c6c6574436f6e6e656374';
const CARDANOSCAN_PREPROD_TX_BASE = 'https://preprod.cardanoscan.io/transaction/';
const COLLATERAL_AMOUNT_CBOR = '1a004c4b40';

export function setupUi(client: CardanoDappClient, logEl: HTMLElement): void {
  const statusEl = requireElement('status', HTMLElement);
  const connectBtn = requireElement('btn-connect', HTMLButtonElement);
  const qrContainer = requireElement('qr-container', HTMLElement);
  const qrCanvas = requireElement('qr-canvas', HTMLCanvasElement);
  const uriTextarea = requireElement('wc-uri', HTMLTextAreaElement);
  const sessionInfo = requireElement('session-info', HTMLElement);
  const methodsSection = requireElement('methods-section', HTMLElement);
  const writeSection = requireElement('write-section', HTMLElement);
  const submitBtn = requireElement('btn-submit-tx', HTMLButtonElement);
  const txStatusEl = requireElement('tx-status', HTMLElement);

  let cachedPaymentAddressHex: string | null = null;
  let signedTxHex: string | null = null;
  // Bumped on every session change so an in-flight signTx can't land on a different session.
  let sessionGeneration = 0;

  client.setSessionListener((connected) => {
    sessionGeneration++;
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
      signedTxHex = null;
      submitBtn.disabled = true;
    }
  }

  document.querySelectorAll<HTMLButtonElement>('[data-method]').forEach((btn) => {
    const method = btn.dataset.method;
    if (method === undefined) return;
    btn.addEventListener('click', async () => {
      btn.disabled = true;
      try {
        await invokeMethod(method);
      } catch (error) {
        logEl.textContent += `\nERROR (${method}): ${String(error)}\n`;
      } finally {
        btn.disabled = false;
        if (method === 'cardano_signTx') {
          submitBtn.disabled = signedTxHex == null;
        }
      }
    });
  });

  requireElement('btn-run-read', HTMLElement).addEventListener('click', async () => {
    const btn = requireElement('btn-run-read', HTMLButtonElement);
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
        signedTxHex = null;
        const generation = sessionGeneration;
        const utxos = await client.request<string[] | null>('cardano_getUtxos');
        if (!utxos?.length) {
          throw new Error('Wallet has no UTXOs. Fund it from the preprod faucet.');
        }
        const changeAddressHex = await client.request<string>('cardano_getChangeAddress');
        const unsignedTxHex = buildSelfTransfer(utxos, changeAddressHex);
        const witnessSetHex = await client.signTx(unsignedTxHex, false);
        if (generation !== sessionGeneration) {
          throw new Error('Session changed while signing; signature discarded.');
        }
        signedTxHex = attachWitnesses(unsignedTxHex, witnessSetHex);
        submitBtn.disabled = false;
        clearTxStatus();
        break;
      }
      case 'cardano_getCollateral': {
        await client.getCollateral(COLLATERAL_AMOUNT_CBOR);
        break;
      }
      case 'cardano_signData': {
        const addressHex = await resolvePaymentAddressHex();
        await client.signData(addressHex, SIGN_DATA_PAYLOAD_HEX);
        break;
      }
      case 'cardano_submitTx': {
        if (!signedTxHex) {
          throw new Error('Sign the transaction first with signTx');
        }
        showTxSubmitting();
        try {
          const txHash = await client.submitTx(signedTxHex);
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
    if (typeof error === 'object' && 'message' in error && typeof error.message === 'string') {
      return error.message;
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
    const address =
      used?.[0] ?? (await client.request<string>('cardano_getChangeAddress'));
    cachedPaymentAddressHex = address;
    return address;
  }
}
