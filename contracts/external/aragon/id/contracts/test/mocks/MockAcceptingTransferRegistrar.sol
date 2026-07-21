pragma solidity >=0.4.24 <0.9.0;

import "../ens/Registrar.sol";


contract MockAcceptingTransferRegistrar {
    mapping(bytes32 => bool) public acceptedTransfer;

    function acceptRegistrarTransfer(bytes32 hash, Deed deed, uint registrationDate) {
        acceptedTransfer[hash] = true;
    }
}
