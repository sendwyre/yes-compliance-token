pragma solidity ^0.4.24;

// import "./Upgradeable.sol";
import "../submodules/openzeppelin-zos/contracts/token/ERC721/ERC721Token.sol";
import "./Upgradeable.sol";
import "../submodules/openzeppelin-zos/contracts/token/ERC20/ERC20.sol";

/**
 * an ERC721 "yes" compliance token supporting country-level
 *
 * really, ERC721 is useful as an end-user management interface. financial integrations can (and should) go beyond this
 * for a more domain-specific API, catering to compliance.
 *
 * i think upgradeability (contract address stability)....
 *
 * rules:
 *  - no address can be associated with more than one identity (though addresses may have more than token). issuance
 *    in this circumstance will fail
 *  -
 */
contract YesComplianceTokenV1 is ERC721Token /*, ERC20 Upgradeable /*, ERC165 */ {

    // bytes4 private constant InterfaceId_TokenstampV1 = '';

    // todo could shorten the entity IDs to anything 160+ to make this cheaper

    address public ownerAddress;

    /**
     * tracks the state for a single recognized entity
     */
    struct EntityRecord {

        bool init;

        uint64 tokenIdCounter;

        /** must be true for any of the present state to be considered valid. otherwise, under review (temporary) */
        bool active;

//        /** must be true for this entity to mint */
//        bool mintingActive;

//        /**
//         * the stable identity which backs this token
//         *
//         * if the entityId higest byte is 0xff, the lowest 20 bytes are an address that was at least once associated with the
//         * identity (this is enforced). in all other cases, self-selectable first-come-first-serve.
//         */
//        uint256 entityId;

        /**
         * maps ISO-3166-1 country codes to "yesmask" 64-bitmask. when any bit is 1, this is an attestation
         * that this token is backed by the respective verification check.
         *
         * yesmask structure:
         * for country code 840 (United States):
         * bit 0: subject is a fully government-recognized compliant individual (country-wide/strictest)
         * bit 1: subject is a fully government-recognized compliant (any C/S/? designation required?)
         * bit 2:
         * ...
         */
        mapping(uint16 => uint64) yesmaskByCountryCode;

        /**
         * all addresses associated with this identity
         */
        uint256[] tokenIds;
    }

    struct TokenRecord {
        bool minter;
    }

    mapping(uint256 => EntityRecord) public entityById;

    mapping(uint256 => TokenRecord) public tokenRecordById;

    mapping(uint256 => uint256) public entityIdByTokenId;

    uint256[] allEntityIds;

    modifier onlyOwner {
        assert(msg.sender == ownerAddress);
        _;
    }

    constructor(string _name, string _symbol) public {
        initialize(_name, _symbol);
        ownerAddress = msg.sender;
    }

//    function isFullyAuthorizedIndividual(address _address, uint16 _country) external view returns (bool) {
//        return this.hasVerification(_address, _country, 0);
//    }
//    function isFullyAuthorizedCorporation(address _address, uint16 country) external view {
//        return this.hasVerification(_address, _country, 1);
//    }

    function initialize() public {
        // _sizes[bytes4(sha3("getUint()"))] = 32;
    }

    function requireYes(address _address, uint16 _country, uint8 _yes) external view {
        require(_yes < 64);
        uint256 entityId = this.tokenOfOwnerByIndex(_address, 0);
        EntityRecord storage s = entityById[entityId];
        require(s.active);
        require((s.yesmaskByCountryCode[_country] & (uint64(1) << _yes)) > 0);
    }

    // function isYes(address _address, uint16 _country, uint8 _verification) external view {
    // }

    /**
     * minting done by the owner of a token
     */
    function mint(address _to, bool _minter) external returns (uint256) {
        uint256 tokenId = this.tokenOfOwnerByIndex(msg.sender, 0);
        require(tokenRecordById[tokenId].minter);
        uint256 entityId = entityIdByTokenId[tokenId];
        EntityRecord storage s = entityById[entityId];
        require(s.active);
        return mintUnsafe(_to, entityId, _minter);
    }

//    function mintYes(address _to, uint256 _entityId, bool _active, bool _minter, uint8 _yes, uint16 _countryCode)
//            external onlyOwner
//            returns (uint256) {
//
//        EntityRecord storage s = entityById[_entityId];
//
//        require(_countryCode == 840); // USA only
//        require(_yes < 64);
//
//        markYes()
//        s.active = _active;
//        s.yesByCountryCode[_countryCode] |= (1 << _yes);
//
//        return mintYesUnsafe(_to, _entityId, _minter);
//    }

    function mint(address _to, uint256 _entityId, bool _minter) external onlyOwner returns (uint256) {
        return mintUnsafe(_to, _entityId, _minter);
    }

//    function destroyEntity(uint256 _entityId) external onlyOwner {
//        // todo
//    }

    /** across-the-board enable/disable */
    function setEntityActive(uint256 _entityId, bool _active) external onlyOwner {
        EntityRecord storage s = entityById[_entityId];
        // require(s.init);
        if(!s.init) initEntity(_entityId); // this allows tokenless entities... fine
        s.active = _active;
    }

    function markYes(uint256 _entityId, uint16 _countryCode, uint16 _yes) external onlyOwner {
        EntityRecord storage s = entityById[_entityId];
        if(!s.init) initEntity(_entityId);
         s.yesmaskByCountryCode[_countryCode] |= (uint64(1) << _yes);
    }

    function markNo(uint256 _entityId, uint16 _countryCode, uint16 _no) external onlyOwner {
        EntityRecord storage s = entityById[_entityId];
        if(!s.init) initEntity(_entityId);
         s.yesmaskByCountryCode[_countryCode] &= ~(uint64(1) << _no);
    }

    function mark(uint256 _entityId, uint16 _countryCode, uint64 __yesmask) external onlyOwner {
        EntityRecord storage s = entityById[_entityId];
        if(!s.init) initEntity(_entityId);
        s.yesmaskByCountryCode[_countryCode] = __yesmask; // &= ~(1 << _no);
    }

//    function burn(uint256 _tokenId) external {
//        uint256 tokenId = this.tokenOfOwnerByIndex(msg.sender, 0);
//        super._burn(_owner, _tokenId);
//    }

    /** non-permissed internal function with minting impl */
    function mintUnsafe(address _to, uint256 _entityId, bool _minter) internal returns (uint256) {
        EntityRecord storage s = entityById[_entityId];
        if(!s.init) initEntity(_entityId);
        uint256 tokenId = uint256(keccak256(abi.encodePacked(_entityId, s.tokenIdCounter)));
        super._mint(_to, tokenId);
        s.tokenIdCounter++;
        entityIdByTokenId[tokenId] = _entityId;
        tokenRecordById[tokenId].minter = _minter;
        return tokenId;
    }

    function initEntity(uint256 _entityId) internal {
        require(_entityId > 0);
        EntityRecord storage s = entityById[_entityId];
        require(!s.init);
        s.init = true;
        allEntityIds.push(_entityId);
    }

    // function
}
