// originally from
// https://github.com/evbots/ethereum_tutorials/blob/master/deploy.js

const { readFileSync } = require("fs");
const solc = require("solc");
const Web3 = require("web3");

const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
const params = {
  language: "Solidity",
  sources: {
    contract: {
      content: readFileSync("./contracts/example.sol", "utf-8")
    }
  },
  settings: {
    outputSelection: {
      "*": {
        "*": ["abi", "evm.bytecode"]
      }
    }
  }
};

const compiled = JSON.parse(
  solc.compileStandardWrapper(JSON.stringify(params))
);
const compiledContract = compiled.contracts["contract"];
const contract = new web3.eth.Contract(compiledContract.Calculator.abi);

contract.deploy(compiledContract.Calculator.evm.bytecode);
