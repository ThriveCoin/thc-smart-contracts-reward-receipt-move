'use strict'

const { SUI_NETWORKS } = require('./constants')
const yargs = require('yargs')
  .option('network', { alias: 'n', type: 'string', demandOption: true, default: 'devnet', choices: SUI_NETWORKS })
  .option('address', { alias: 'a', type: 'string', demandOption: true })
const { getFullnodeUrl, SuiClient } = require('@mysten/sui.js/client')

const { fromUnit } = require('./utils')

const main = async () => {
  const { address, network } = yargs.argv
  const suiClient = new SuiClient({ url: getFullnodeUrl(network) })
  const bal = await suiClient.getBalance({ owner: address })
  console.log('balance (unit)', bal.totalBalance)
  console.log('balance', fromUnit(bal.totalBalance))
}

main().catch(console.error)
