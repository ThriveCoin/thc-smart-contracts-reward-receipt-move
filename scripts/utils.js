'use strict'

const { bech32 } = require('bech32')
const { MIST_PER_SUI } = require('@mysten/sui.js/utils')

/**
 * @param {string} bal
 * @returns {number}
 */
const fromUnit = (bal) => {
  return Number.parseInt(bal) / Number(MIST_PER_SUI)
}

/**
 * @param {string} input
 * @returns {Buffer}
 */
const bech32ToBuffer = (input) => {
  const decoded = bech32.decode(input)
  const bytes = bech32.fromWords(decoded.words)
  const hex = bytes.map(byte => byte.toString(16).padStart(2, '0'))
    .join('')
    .substring(2)
  return Buffer.from(hex, 'hex')
}

module.exports = {
  fromUnit,
  bech32ToBuffer
}
