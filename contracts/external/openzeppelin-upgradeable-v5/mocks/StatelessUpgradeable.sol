// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// We keep these imports and a dummy contract just to we can run the test suite after transpilation.

import {Address} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/Address.sol";
import {Arrays} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/Arrays.sol";
import {AuthorityUtils} from "@crane/contracts/external/openzeppelin-contracts-v5/access/manager/AuthorityUtils.sol";
import {Base64} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/Base64.sol";
import {BitMaps} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/structs/BitMaps.sol";
import {Bytes} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/Bytes.sol";
import {CAIP2} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/CAIP2.sol";
import {CAIP10} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/CAIP10.sol";
import {Checkpoints} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/structs/Checkpoints.sol";
import {CircularBuffer} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/structs/CircularBuffer.sol";
import {Clones} from "@crane/contracts/external/openzeppelin-contracts-v5/proxy/Clones.sol";
import {Create2} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/Create2.sol";
import {DoubleEndedQueue} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/structs/DoubleEndedQueue.sol";
import {ECDSA} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/cryptography/ECDSA.sol";
import {EnumerableMap} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/structs/EnumerableMap.sol";
import {EnumerableSet} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/structs/EnumerableSet.sol";
import {ERC1155HolderUpgradeable} from "../token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import {ERC165Upgradeable} from "../utils/introspection/ERC165Upgradeable.sol";
import {ERC165Checker} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/introspection/ERC165Checker.sol";
import {ERC1967Utils} from "@crane/contracts/external/openzeppelin-contracts-v5/proxy/ERC1967/ERC1967Utils.sol";
import {ERC721HolderUpgradeable} from "../token/ERC721/utils/ERC721HolderUpgradeable.sol";
import {ERC4337Utils} from "@crane/contracts/external/openzeppelin-contracts-v5/account/utils/draft-ERC4337Utils.sol";
import {ERC7579Utils} from "@crane/contracts/external/openzeppelin-contracts-v5/account/utils/draft-ERC7579Utils.sol";
import {Heap} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/structs/Heap.sol";
import {Math} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/math/Math.sol";
import {MerkleProof} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/cryptography/MerkleProof.sol";
import {MessageHashUtils} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/cryptography/MessageHashUtils.sol";
import {NoncesUpgradeable} from "../utils/NoncesUpgradeable.sol";
import {NoncesKeyedUpgradeable} from "../utils/NoncesKeyedUpgradeable.sol";
import {P256} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/cryptography/P256.sol";
import {Panic} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/Panic.sol";
import {Packing} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/Packing.sol";
import {RSA} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/cryptography/RSA.sol";
import {SafeCast} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/math/SafeCast.sol";
import {SafeERC20} from "@crane/contracts/external/openzeppelin-contracts-v5/token/ERC20/utils/SafeERC20.sol";
import {ShortStrings} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/ShortStrings.sol";
import {SignatureChecker} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/cryptography/SignatureChecker.sol";
import {SignedMath} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/math/SignedMath.sol";
import {StorageSlot} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/StorageSlot.sol";
import {Strings} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/Strings.sol";
import {Time} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/types/Time.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

contract Dummy1234Upgradeable is Initializable {    function __Dummy1234_init() internal onlyInitializing {
    }

    function __Dummy1234_init_unchained() internal onlyInitializing {
    }
}
