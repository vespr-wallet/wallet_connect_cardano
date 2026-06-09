import SignClient from '@walletconnect/sign-client';
import type { SessionTypes } from '@walletconnect/types';

import {
  CIP30_EVENTS,
  CIP30_METHODS,
  PREPROD_CHAIN_ID,
} from './constants';

export type LogFn = (message: string, data?: unknown) => void;

export class CardanoDappClient {
  private client: SignClient | null = null;
  private session: SessionTypes.Struct | null = null;
  private onSessionChange: ((connected: boolean) => void) | null = null;

  constructor(private readonly log: LogFn) {}

  get isConnected(): boolean {
    return this.session != null;
  }

  get sessionTopic(): string | null {
    return this.session?.topic ?? null;
  }

  get connectedAccounts(): string[] {
    return this.session?.namespaces.cip34?.accounts ?? [];
  }

  setSessionListener(listener: (connected: boolean) => void): void {
    this.onSessionChange = listener;
  }

  async init(projectId: string): Promise<void> {
    if (this.client) return;

    this.client = await SignClient.init({
      projectId,
      metadata: {
        name: 'WC Cardano dApp Demo',
        description: 'Milestone 1 test dApp for wallet_connect_cardano',
        url: 'https://github.com/vespr-wallet/wallet_connect_cardano',
        icons: ['https://vespr.xyz/favicon.ico'],
      },
    });

    this.client.on('session_delete', () => {
      this.session = null;
      this.log('Session disconnected');
      this.onSessionChange?.(false);
    });

    this.log('Sign Client initialized');
  }

  async connect(): Promise<{ uri: string }> {
    if (!this.client) {
      throw new Error('Client not initialized');
    }

    const { uri, approval } = await this.client.connect({
      requiredNamespaces: {
        cip34: {
          chains: [PREPROD_CHAIN_ID],
          methods: [...CIP30_METHODS],
          events: [...CIP30_EVENTS],
        },
      },
    });

    if (!uri) {
      throw new Error('No WalletConnect URI returned');
    }

    this.log('Pairing URI generated — scan with wallet app');

    void approval()
      .then((session) => {
        this.session = session;
        this.log('Session established', {
          topic: session.topic,
          accounts: session.namespaces.cip34?.accounts,
        });
        this.onSessionChange?.(true);
      })
      .catch((error: unknown) => {
        this.log('Session approval failed', String(error));
        this.onSessionChange?.(false);
      });

    return { uri };
  }

  async disconnect(): Promise<void> {
    if (!this.client || !this.session) return;

    await this.client.disconnect({
      topic: this.session.topic,
      reason: {
        code: 6000,
        message: 'User disconnected',
      },
    });
    this.session = null;
    this.onSessionChange?.(false);
  }

  async request<T = unknown>(method: string, params?: unknown): Promise<T> {
    if (!this.client || !this.session) {
      throw new Error('Not connected');
    }

    const wireParams: unknown[] =
      params == null ? [] : Array.isArray(params) ? params : [params];
    this.log(`→ ${method}`, wireParams.length > 0 ? wireParams : undefined);

    const result = await this.client.request<T>({
      topic: this.session.topic,
      chainId: PREPROD_CHAIN_ID,
      request: { method, params: wireParams },
    });

    this.log(
      `← ${method}`,
      result === undefined ? '(no result)' : result,
    );
    return result;
  }

  async getNetworkId(): Promise<number> {
    return this.request<number>('cardano_getNetworkId');
  }

  async signTx(unsignedTxHex: string, partialSign = false): Promise<string> {
    return this.request<string>('cardano_signTx', [unsignedTxHex, partialSign]);
  }

  async signData(addressHex: string, payloadHex: string): Promise<unknown> {
    return this.request('cardano_signData', [addressHex, payloadHex]);
  }

  async submitTx(txHex: string): Promise<string> {
    return this.request<string>('cardano_submitTx', [txHex]);
  }
}
