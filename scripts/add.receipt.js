'use strict'

const { SUI_NETWORKS } = require('./constants')
const yargs = require('yargs')
  .option('network', { alias: 'n', type: 'string', demandOption: true, default: 'devnet', choices: SUI_NETWORKS })
  .option('priv-key', { alias: 'k', type: 'string', demandOption: true })
  .option('pkg', { alias: 'p', type: 'string', demandOption: true })
  .option('writer-role', { alias: 'w', type: 'string', demandOption: true })
  .option('recipient', { alias: 'r', type: 'string', demandOption: true })
  .option('transfer-tx', { alias: 't', type: 'string', demandOption: true })
  .option('ver', { alias: 'v', type: 'string', demandOption: true, default: 'v1.0' })
  .option('timestamp', { alias: 's', type: 'number' })
  .option('meta-data-uri', { alias: 'm', type: 'string', demandOption: true })
const { getFullnodeUrl, SuiClient } = require('@mysten/sui.js/client')
const { Ed25519Keypair, Ed25519PublicKey } = require('@mysten/sui.js/keypairs/ed25519')
const { TransactionBlock } = require('@mysten/sui.js/transactions')

const { bech32ToBuffer, fromUnit } = require('./utils')
const { inspect } = require('util')

const main = async () => {
  const {
    privKey, network, pkg, writerRole, recipient,
    transferTx, ver, timestamp = Date.now(), metaDataUri
  } = yargs.argv
  const suiClient = new SuiClient({ url: getFullnodeUrl(network) })

  const keypair = Ed25519Keypair.fromSecretKey(bech32ToBuffer(privKey))

  const publicKey = new Ed25519PublicKey(keypair.getPublicKey().toRawBytes())
  const address = publicKey.toSuiAddress()
  console.log('opened address', address)

  const bal = await suiClient.getBalance({ owner: address })
  console.log('balance (unit)', bal.totalBalance)
  console.log('balance', fromUnit(bal.totalBalance))
  console.debug('package', pkg)
  console.debug('receipt data', { writerRole, recipient, transferTx, ver, timestamp, metaDataUri })

  const txb = new TransactionBlock()
  txb.moveCall({
    target: `${pkg}::reward_receipt::add_receipt`,
    arguments: [
      txb.object(writerRole),
      txb.pure.address(recipient),
      txb.pure.string(transferTx),
      txb.pure.string(ver),
      txb.pure.u64(timestamp),
      txb.pure.string(metaDataUri)
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

  const receiptObj = res.objectChanges.find(x =>
    x.type === 'created' && x.objectType.endsWith('::reward_receipt::RewardReceipt')
  )
  console.log('created receipt', receiptObj)
}

main().catch(console.error)
