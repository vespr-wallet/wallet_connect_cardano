import {
  Address,
  BigNum,
  Transaction,
  TransactionBody,
  TransactionInputs,
  TransactionOutput,
  TransactionOutputs,
  TransactionUnspentOutput,
  TransactionWitnessSet,
  Value,
} from '@emurgo/cardano-serialization-lib-asmjs';

/** Flat fee, comfortably above the preprod minimum for a 1-in/1-out transaction. */
const FEE_LOVELACE = '300000';

/**
 * Builds an unsigned self-transfer spending the wallet's largest UTXO back to
 * its change address, minus the fee. Native assets on that UTXO are kept.
 */
export function buildSelfTransfer(utxoHexes: string[], changeAddressHex: string): string {
  // ponytail: single largest UTXO, no coin selection; enough for a demo transfer.
  const utxos = utxoHexes.map((hex) => TransactionUnspentOutput.from_hex(hex));
  const largest = utxos.reduce((a, b) =>
    a.output().amount().coin().compare(b.output().amount().coin()) >= 0 ? a : b,
  );

  const inputs = TransactionInputs.new();
  inputs.add(largest.input());
  const fee = BigNum.from_str(FEE_LOVELACE);
  const outputs = TransactionOutputs.new();
  outputs.add(
    TransactionOutput.new(
      Address.from_hex(changeAddressHex),
      largest.output().amount().checked_sub(Value.new(fee)),
    ),
  );

  const body = TransactionBody.new_tx_body(inputs, outputs, fee);
  return Transaction.new(body, TransactionWitnessSet.new()).to_hex();
}

/** Attaches the wallet's witness set (CIP-30 `signTx` result) to the unsigned transaction. */
export function attachWitnesses(unsignedTxHex: string, witnessSetHex: string): string {
  const tx = Transaction.from_hex(unsignedTxHex);
  return Transaction.new(
    tx.body(),
    TransactionWitnessSet.from_hex(witnessSetHex),
    tx.auxiliary_data(),
  ).to_hex();
}
