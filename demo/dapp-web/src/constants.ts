/** Preprod chain ID per CIP-34. */
export const PREPROD_CHAIN_ID = 'cip34:0-1';

/** All CIP-30 JSON-RPC methods supported by wallet_connect_cardano. */
export const CIP30_METHODS = [
  'cardano_getExtensions',
  'cardano_getNetworkId',
  'cardano_getBalance',
  'cardano_getUsedAddresses',
  'cardano_getUnusedAddresses',
  'cardano_getChangeAddress',
  'cardano_getRewardAddresses',
  'cardano_getRewardAddress',
  'cardano_getUtxos',
  'cardano_signTx',
  'cardano_signData',
  'cardano_submitTx',
] as const;

export const CIP30_EVENTS = [
  'chainChanged',
  'accountsChanged',
  'cardano_onNetworkChange',
  'cardano_onAccountChange',
] as const;

export const READ_METHODS = [
  'cardano_getExtensions',
  'cardano_getNetworkId',
  'cardano_getBalance',
  'cardano_getUsedAddresses',
  'cardano_getUnusedAddresses',
  'cardano_getChangeAddress',
  'cardano_getRewardAddresses',
  'cardano_getRewardAddress',
  'cardano_getUtxos',
] as const;
