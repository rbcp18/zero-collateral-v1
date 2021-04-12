import "./Beacon2.sol";
import "./Proxy2.sol";
import "../../contexts2/access-control/roles/RolesMods.sol";
import "../../shared/roles.sol";
import "contracts/shared/libraries/LibDiamond.sol";

contract EscrowManager2 {
    mapping(string => address) public implementations;

    event BeaconCreated(
        string indexed name,
        BeaconType beaconType,
        address addr
    );
    event ProxyCreated(address addr);

    enum BeaconType { Main, Backup }

    function getImplementation(string calldata name)
        external
        view
        returns (address)
    {
        return implementations[name];
    }

    function createImplementation(string memory name, address impl) public {
        LibDiamond.enforceIsContractOwner();
        implementations[name] = impl;
        _deployBeacon(name, BeaconType.Main);
    }

    function beginUpgrade(string memory name, address newImpl) public {
        LibDiamond.enforceIsContractOwner();
        implementations[name] = newImpl;
        _deployBeacon(name, BeaconType.Backup);
        _destroyBeacon(name, BeaconType.Main);
    }

    function finishUpgrade(string memory name) public {
        LibDiamond.enforceIsContractOwner();
        _deployBeacon(name, BeaconType.Main);
        _destroyBeacon(name, BeaconType.Backup);
    }

    function createProxy(string memory name) public returns (address) {
        address main = _getBeaconAddress(name, BeaconType.Main);
        address backup = _getBeaconAddress(name, BeaconType.Backup);
        bytes memory proxyCode =
            abi.encodePacked(
                type(Proxy2).creationCode,
                abi.encode(main, backup)
            );

        address deployed;
        assembly {
            deployed := create(0, add(proxyCode, 0x20), mload(proxyCode))
        }

        emit ProxyCreated(deployed);
        return deployed;
    }

    function _deployBeacon(string memory name, BeaconType beaconType)
        internal
        returns (address)
    {
        bytes memory bytecode = _getBeaconCode(name);
        bytes32 salt = _getBeaconSalt(name, beaconType);

        address beacon;
        assembly {
            beacon := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }

        emit BeaconCreated(name, beaconType, beacon);
        return beacon;
    }

    function _destroyBeacon(string memory name, BeaconType beaconType)
        internal
    {
        address beaconAddress = _getBeaconAddress(name, beaconType);
        Beacon2(beaconAddress).destroy();
    }

    function _getBeaconCode(string memory name)
        internal
        view
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                type(Beacon2).creationCode,
                abi.encode(address(this), name)
            );
    }

    function _getBeaconSalt(string memory name, BeaconType beaconType)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(beaconType, name));
    }

    function _getBeaconAddress(string memory name, BeaconType beaconType)
        internal
        view
        returns (address)
    {
        bytes32 bytecodeHash = keccak256(_getBeaconCode(name));
        bytes32 salt = _getBeaconSalt(name, beaconType);
        bytes32 dataHash =
            keccak256(
                abi.encodePacked(
                    bytes1(0xff),
                    address(this),
                    salt,
                    bytecodeHash
                )
            );
        return address(uint160(uint256(dataHash)));
    }
}