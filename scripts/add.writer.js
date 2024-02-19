'use strict'

const { SUI_NETWORKS } = require('./constants')
const yargs = require('yargs')
  .option('network', { alias: 'n', type: 'string', demandOption: true, default: 'devnet', choices: SUI_NETWORKS })
  .option('priv-key', { alias: 'k', type: 'string', demandOption: true })
  .option('pkg', { alias: 'p', type: 'string', demandOption: true })
  .option('admin-role', { alias: 'a', type: 'string', demandOption: true })
  .option('writer-role', { alias: 'w', type: 'string', demandOption: true })
  .option('account', { alias: 'u', type: 'string', demandOption: true })
const { getFullnodeUrl, SuiClient } = require('@mysten/sui.js/client')
const { Ed25519Keypair, Ed25519PublicKey } = require('@mysten/sui.js/keypairs/ed25519')
const { TransactionBlock } = require('@mysten/sui.js/transactions')

const { bech32ToBuffer, fromUnit } = require('./utils')
const { inspect } = require('util')

const main = async () => {
  const { privKey, network, pkg, adminRole, writerRole, account } = yargs.argv
  const suiClient = new SuiClient({ url: getFullnodeUrl(network) })

  const keypair = Ed25519Keypair.fromSecretKey(bech32ToBuffer(privKey))

  const publicKey = new Ed25519PublicKey(keypair.getPublicKey().toRawBytes())
  const address = publicKey.toSuiAddress()
  console.log('opened address', address)

  const bal = await suiClient.getBalance({ owner: address })
  console.log('balance (unit)', bal.totalBalance)
  console.log('balance', fromUnit(bal.totalBalance))
  console.debug('package', pkg)
  console.debug('arguments', { adminRole, writerRole, account })

  const txb = new TransactionBlock()
  txb.moveCall({
    target: `${pkg}::reward_receipt::add_writer`,
    arguments: [
      txb.object(adminRole),
      txb.object(writerRole),
      txb.pure.address(account)
    ]
  })
  txb.setGasBudget(parseInt(+bal.totalBalance * 0.01))

  const res = await suiClient.signAndExecuteTransactionBlock({
    transactionBlock: txb,
    signer: keypair,
    options: {
      showEffects: true,
      showObjectChanges: true
    }
  })

  console.log('tx digest', res.digest)
  if (res.effects.status.error || res.effects.status.status !== 'success') {
    console.log(inspect(res, false, 100, true))
    throw new Error(res.effects.status.error)
  }

  await suiClient.waitForTransactionBlock({
    digest: res.digest
  })

  const writer = await suiClient.getObject({ id: writerRole, options: { showContent: true } })
  console.log('write role', inspect(writer, false, 100, true))
}

main().catch(console.error)
