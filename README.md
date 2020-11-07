# IoTeX Protocol Governance Framework

IoTeX blockchain protocol is managed by a decentralized community of delegates and voters who hold IOTX coins, who propose and vote on upgrades to the protocol. This is the governance framework for [IoTeX](https://iotex.io) blockchain protocol which extends [EIP1202](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1202.md), and empowers community governance.


# The Life of a Proposal
1. **Anyone** can make a proposal via [`register`](https://github.com/iotexproject/IOTX-EIP-1202-contracts/blob/master/contracts/OffChainIssueRegistration.sol#L48) which will be recorded [here](https://github.com/iotexproject/IOTX-EIP-1202-contracts/blob/master/contracts/AdhocIssueSheet.sol).

2. The whitelisted accounts can [accept](https://github.com/iotexproject/IOTX-EIP-1202-contracts/blob/master/contracts/AdhocIssueSheet.sol#L49) this proposal, [start](https://github.com/iotexproject/IOTX-EIP-1202-contracts/blob/master/contracts/AdhocIssueSheet.sol#L67), [pause](https://github.com/iotexproject/IOTX-EIP-1202-contracts/blob/master/contracts/AdhocIssueSheet.sol#L79), [stop](https://github.com/iotexproject/IOTX-EIP-1202-contracts/blob/master/contracts/AdhocIssueSheet.sol#L103) the proposal.

3. Once it is started, voters can vote via [`vote`](https://github.com/iotexproject/IOTX-EIP-1202-contracts/blob/master/contracts/OffchainIssue.sol#L119).

4. Behind the scene, IoTeX's stakeholders and voters information are injected into [`RotatableWeightedVPS`](https://github.com/iotexproject/IoTeXVitaTokenContract/tree/master/contracts/voting) every 25 hours. `RotatableWeightedVPS` - considered as a system contract - is used by [VITA claim](https://iotex.io/vita) and [poll](https://member.iotex.io).


# Mainnet Deployment
`RotatableWeightedVPS` - [io1476tz4nx8v8qc5xdpu3hclk0uyanus6x2laddq](https://www.iotexscan.io/address/io1476tz4nx8v8qc5xdpu3hclk0uyanus6x2laddq)
`OffChainIssueRegistration` - [io17nq7vnm3wcs5a2cmhwhcnhwtwv4s6lxuv7qqj5](https://www.iotexscan.io/address/io17nq7vnm3wcs5a2cmhwhcnhwtwv4s6lxuv7qqj5)
`AdhocIssueSheet` - [TBD](TBD)´

# Development

## Compile

`truffle compile`

## Test

`truffle test`

## Lint

`npm install truffle-plugin-solhint`

`truffle run solhint`
