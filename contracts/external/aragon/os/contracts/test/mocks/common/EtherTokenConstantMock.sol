pragma solidity >=0.4.24 <0.9.0;

import "../../../common/EtherTokenConstant.sol";


contract EtherTokenConstantMock is EtherTokenConstant {
    function getETHConstant() external pure returns (address) { return ETH; }
}
