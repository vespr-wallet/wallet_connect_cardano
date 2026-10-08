import {
  Address,
  BigNum,
  LinearFee,
  Transaction,
  TransactionBuilder,
  TransactionBuilderConfigBuilder,
  TransactionUnspentOutput,
  TransactionWitnessSet,
  UnitInterval,
} from '@emurgo/cardano-serialization-lib-browser';

// ponytail: preprod protocol parameters hardcoded (the demo is preprod-only); fetch them if mainnet is added.
const PREPROD_TX_CONFIG = TransactionBuilderConfigBuilder.new()
  .fee_algo(LinearFee.new(BigNum.from_str('44'), BigNum.from_str('155381')))
  .coins_per_utxo_byte(BigNum.from_str('4310'))
  .pool_deposit(BigNum.from_str('500000000'))
  .key_deposit(BigNum.from_str('2000000'))
  .max_value_size(5000)
  .max_tx_size(16384)
  .ref_script_coins_per_byte(UnitInterval.new(BigNum.from_str('15'), BigNum.from_str('1')))
  .build();

/**
 * Builds an unsigned self-transfer spending the wallet's largest UTXO back to
 * its change address. The fee and the change output's minimum ADA are computed
 * by CSL; native assets on that UTXO are kept.
 */
export function buildSelfTransfer(utxoHexes: string[], changeAddressHex: string): string {
  // ponytail: single largest UTXO, no coin selection; enough for a demo transfer.
  const utxos = utxoHexes.map((hex) => TransactionUnspentOutput.from_hex(hex));
  const largest = utxos.reduce((a, b) =>
    a.output().amount().coin().compare(b.output().amount().coin()) >= 0 ? a : b,
  );

  const builder = TransactionBuilder.new(PREPROD_TX_CONFIG);
  builder.add_regular_input(largest.output().address(), largest.input(), largest.output().amount());
  // Throws if the UTXO cannot cover the fee plus the change output's minimum ADA.
  builder.add_change_if_needed(Address.from_hex(changeAddressHex));
  return Transaction.new(builder.build(), TransactionWitnessSet.new()).to_hex();
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
