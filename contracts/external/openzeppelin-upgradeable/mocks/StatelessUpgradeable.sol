// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// We keep these imports and a dummy contract just to we can run the test suite after transpilation.

import {Address} from "@crane/contracts/external/openzeppelin-contracts/utils/Address.sol";
import {Arrays} from "@crane/contracts/external/openzeppelin-contracts/utils/Arrays.sol";
import {AuthorityUtils} from "@crane/contracts/external/openzeppelin-contracts/access/manager/AuthorityUtils.sol";
import {Base64} from "@crane/contracts/external/openzeppelin-contracts/utils/Base64.sol";
import {BitMaps} from "@crane/contracts/external/openzeppelin-contracts/utils/structs/BitMaps.sol";
import {Checkpoints} from "@crane/contracts/external/openzeppelin-contracts/utils/structs/Checkpoints.sol";
import {CircularBuffer} from "@crane/contracts/external/openzeppelin-contracts/utils/structs/CircularBuffer.sol";
import {Clones} from "@crane/contracts/external/openzeppelin-contracts/proxy/Clones.sol";
import {Create2} from "@crane/contracts/external/openzeppelin-contracts/utils/Create2.sol";
import {DoubleEndedQueue} from "@crane/contracts/external/openzeppelin-contracts/utils/structs/DoubleEndedQueue.sol";
import {ECDSA} from "@crane/contracts/external/openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {EnumerableMap} from "@crane/contracts/external/openzeppelin-contracts/utils/structs/EnumerableMap.sol";
import {EnumerableSet} from "@crane/contracts/external/openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import {ERC1155HolderUpgradeable} from "../token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import {ERC165Upgradeable} from "../utils/introspection/ERC165Upgradeable.sol";
import {ERC165Checker} from "@crane/contracts/external/openzeppelin-contracts/utils/introspection/ERC165Checker.sol";
import {ERC1967Utils} from "@crane/contracts/external/openzeppelin-contracts/proxy/ERC1967/ERC1967Utils.sol";
import {ERC721HolderUpgradeable} from "../token/ERC721/utils/ERC721HolderUpgradeable.sol";
import {Heap} from "@crane/contracts/external/openzeppelin-contracts/utils/structs/Heap.sol";
import {Math} from "@crane/contracts/external/openzeppelin-contracts/utils/math/Math.sol";
import {MerkleProof} from "@crane/contracts/external/openzeppelin-contracts/utils/cryptography/MerkleProof.sol";
import {
    MessageHashUtils
} from "@crane/contracts/external/openzeppelin-contracts/utils/cryptography/MessageHashUtils.sol";
import {P256} from "@crane/contracts/external/openzeppelin-contracts/utils/cryptography/P256.sol";
import {Panic} from "@crane/contracts/external/openzeppelin-contracts/utils/Panic.sol";
import {Packing} from "@crane/contracts/external/openzeppelin-contracts/utils/Packing.sol";
import {RSA} from "@crane/contracts/external/openzeppelin-contracts/utils/cryptography/RSA.sol";
import {SafeCast} from "@crane/contracts/external/openzeppelin-contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {ShortStrings} from "@crane/contracts/external/openzeppelin-contracts/utils/ShortStrings.sol";
import {
    SignatureChecker
} from "@crane/contracts/external/openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";
import {SignedMath} from "@crane/contracts/external/openzeppelin-contracts/utils/math/SignedMath.sol";
import {StorageSlot} from "@crane/contracts/external/openzeppelin-contracts/utils/StorageSlot.sol";
import {Strings} from "@crane/contracts/external/openzeppelin-contracts/utils/Strings.sol";
import {Time} from "@crane/contracts/external/openzeppelin-contracts/utils/types/Time.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

contract Dummy1234Upgradeable is Initializable {
    function __Dummy1234_init() internal onlyInitializing {}

    function __Dummy1234_init_unchained() internal onlyInitializing {}
}
