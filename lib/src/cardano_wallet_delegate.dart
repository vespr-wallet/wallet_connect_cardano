import 'models/models.dart';

/// The contract that a Cardano wallet app must implement to integrate with
/// this SDK.
///
/// When a dApp sends a CIP-30 JSON-RPC request over WalletConnect, the SDK
/// deserialises the parameters and calls the corresponding method on this
/// delegate. The delegate performs the actual wallet operation (querying
/// state, presenting UI, signing) and returns the result. The SDK then
/// serialises the result and sends it back to the dApp.
///
/// All address, transaction, and CBOR values are represented as **lowercase
/// hex-encoded strings**. The SDK never encodes or decodes CBOR itself --
/// that is the responsibility of the wallet app and the dApp.
///
abstract class CardanoWalletDelegate {
  /// Returns the network identifier for the currently active network.
  ///
  /// Returns `0` for testnet, `1` for mainnet, as defined by CIP-30.
  Future<int> getNetworkId();

  /// Returns a list of unspent transaction outputs (UTXOs) for this wallet,
  /// optionally filtered and paginated.
  ///
  /// [amount] is an optional hex-encoded CBOR `value` (lovelace + multi-asset)
  /// that the dApp requires. If provided, only UTXOs sufficient to cover this
  /// amount should be returned. If `null`, all UTXOs are returned.
  ///
  /// [paginate] optionally limits the number of results returned.
  ///
  /// Returns a list of hex-encoded CBOR `TransactionUnspentOutput` values,
  /// or `null` if pagination has been exceeded.
  Future<List<String>?> getUtxos({String? amount, CardanoPaginate? paginate});

  /// Returns the total balance of the wallet as a hex-encoded CBOR `value`.
  ///
  /// The returned value encodes lovelace and any multi-asset amounts.
  Future<String> getBalance();

  /// Returns a list of used payment addresses for this wallet.
  ///
  /// Each address is hex-encoded. [paginate] optionally limits results.
  Future<List<String>> getUsedAddresses({CardanoPaginate? paginate});

  /// Returns a list of unused payment addresses that have never received funds.
  ///
  /// Each address is hex-encoded.
  Future<List<String>> getUnusedAddresses();

  /// Returns the wallet's change address as a hex-encoded byte string.
  Future<String> getChangeAddress();

  /// Returns the wallet's reward (staking) addresses as hex-encoded strings.
  Future<List<String>> getRewardAddresses();

  /// Signs a transaction and returns the witness set.
  ///
  /// [tx] is the hex-encoded CBOR of the transaction to sign.
  ///
  /// [partialSign] if `true`, the wallet may return an incomplete witness set
  /// when it does not own all required signing keys. Defaults to `false`.
  ///
  /// Returns the hex-encoded CBOR `transaction_witness_set`.
  ///
  /// Throws [CardanoTxSignError] on failure.
  Future<String> signTx(String tx, {bool partialSign = false});

  /// Signs arbitrary data and returns a CIP-8 DataSignature.
  ///
  /// [address] is the hex-encoded address whose signing key should be used.
  /// [payload] is the hex-encoded bytes to sign.
  ///
  /// Returns a [CardanoDataSignature] containing hex-encoded CBOR for both
  /// the `COSE_Sign1` signature and the `COSE_Key`.
  ///
  /// Throws [CardanoDataSignError] on failure.
  Future<CardanoDataSignature> signData(String address, String payload);

  /// Submits a signed transaction to the Cardano network.
  ///
  /// [tx] is the hex-encoded CBOR of the fully-signed transaction.
  ///
  /// Returns the transaction hash as a hex-encoded string.
  ///
  /// Throws [CardanoTxSendError] on failure.
  Future<String> submitTx(String tx);

  /// Returns the list of CIP extensions supported by this wallet.
  ///
  /// Each [CardanoExtension] describes a CIP number that extends the base
  /// CIP-30 API. Return an empty list if no extensions are supported.
  Future<List<CardanoExtension>> getExtensions();
}
