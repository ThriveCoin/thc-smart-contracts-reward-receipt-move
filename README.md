# thc-smart-contracts-reward-receipt-move
ThriveCoin reward receipt smart contracts for SUI network

## Prequises

This project requires the following software dependencies:
- rust
- cargo
- sui

All of these can be installed by following instructions under:
https://docs.sui.io/guides/developer/getting-started/sui-install

## Setup

Setup js dependencies via:
```
npm i
```

Then run build cmd:
```
npm run build
```

## Dev deployment

First ensure that you're running sui client under devnet:
```
sui client envs # check if devnet is present

# if not add the network
sui client new-env --alias devnet --rpc https://fullnode.devnet.sui.io:443

# switch to devnet
sui client switch --env devne
```

Then get the active address and send some funds to it via faucet:
```
# get address
sui client active-address

# get funds
curl --location --request POST 'https://faucet.devnet.sui.io/v1/gas' \
--header 'Content-Type: application/json' \
--data-raw '{
    "FixedAmountRequest": {
        "recipient": "<active-address output here>"
    }
}'
```

Then confirm funds:
```
sui client gas
```

After this deploy the package:
```
sui client publish --gas-budget <gas-limit>
```

Upon deployment you can check your tx on explorer and get necessary object ids:
```
https://suiexplorer.com/txblock/<tx_digest>?network=devnet
```

Then you can test adding a receipt:
```
sui client call --package <package-address> --module reward_receipt --function add_receipt --args <writer_role_address> <receipt_address> <tx_hash> <ver> <ts> <metadata_url> --gas-budget 9000990120

# example call
sui client call --package 0x5d62ac615dbe3990b2393d47ac34408bde8ccceabd216423f4e3cfe7e42eb6b1 --module reward_receipt --function add_receipt --args 0x562f1a8675ea9e77ed195620f885380d6354b23dad1a5861a6c35f0b0538f11f 0x6f94e7051ad3a7c799fd913b22e06f076ce21932d618f3f0e661cf2cd56760bb 0x123abc v1.0 1707423669723 'http://example.com' --gas-budget 9000990120
Transaction Digest: EETpJfZXSkesksvQML265Cr6gdHxQ9UWqQVkMzbs5cBX
```

## Testing

Simply run:
```
npm run test
```

For interaction with devnet you can also use `scripts` to run commands instead of sui client raw calls!
