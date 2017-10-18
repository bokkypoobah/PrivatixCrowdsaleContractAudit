var abi = require('ethereumjs-abi')

var encoded = abi.rawEncode([ "uint256", "address" ], [ 1508421600, "0xb1c5d524382324c9472c6f8e1a3c0a64465a4902"]);

console.log(encoded.toString('hex'));