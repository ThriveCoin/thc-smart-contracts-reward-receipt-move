'use strict'

const { SUI_NETWORKS } = require('./constants')
const yargs = require('yargs')
  .option('network', { alias: 'n', type: 'string', demandOption: true, default: 'devnet', choices: SUI_NETWORKS })
  .option('address', { alias: 'a', type: 'string', demandOption: true })
const { getFullnodeUrl, SuiClient } = require('@mysten/sui.js/client')
const { getFaucetHost, requestSuiFromFaucetV0 } = require('@mysten/sui.js/faucet')

const { fromUnit } = require('./utils')

const main = async () => {
  const { address, network } = yargs.argv
  const suiClient = new SuiClient({ url: getFullnodeUrl(network) })

  const balBefore = await suiClient.getBalance({ owner: address })
  console.log('balance before (unit)', balBefore.totalBalance)
  console.log('balance before', fromUnit(balBefore.totalBalance))

  await requestSuiFromFaucetV0({
    host: getFaucetHost(network),
    recipient: address
  })

  const balAfter = await suiClient.getBalance({ owner: address })
  console.log('balance after (unit)', balAfter.totalBalance)
  console.log('balance after', fromUnit(balAfter.totalBalance))
}

main().catch(console.error)
