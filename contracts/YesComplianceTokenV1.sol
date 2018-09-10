pragma solidity ^0.4.24;

// import "./Upgradeable.sol";
import "../submodules/openzeppelin-zos/contracts/token/ERC721/ERC721Token.sol";
import "./Upgradeable.sol";
import "../submodules/openzeppelin-zos/contracts/token/ERC20/ERC20.sol";

/**
 * an ERC721 "yes" compliance token supporting country-level
 *
 * really, ERC721 is useful as an end-user management interface. financial integrations can (and should) go beyond this
 * for a more domain-specific API, catering to compliance. the ERC721 (and ERC20 moreover) sweet spot is ease in
 * of management for connecting tokens to addresses
 *
 * upgradeability notes: ....
 *
 * rules:
 *  - no address can be associated with more than one identity (though addresses may have more than token). issuance
 *    in this circumstance will fail
 *  -
 */
contract YesComplianceTokenV1 is ERC721Token /*, Upgradeable /*, ERC165 */ {

    // todo could shorten the entity IDs to anything 160+ to make this cheaper

    /**
     * tracks the state for a single recognized entity
     */
    struct EntityRecord {

        /** true marking this entity ID has been encountered */
        bool init;

        /** when true, this entity is effectively useless */
        bool locked;

        /** position of the entityId in allEntityIds */
        uint32 entityIdIdx;

        /** used for creating reliable token IDs */
        uint64 tokenIdCounter;

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
         * all tokens associated with this identity
         */
        uint256[] tokenIds;
    }

    /** all fields we want to add per-token */
    struct TokenRecord {
        /** true if this token can mint/burn on behalf of this entity */
        bool minter;

        /** position of the tokenId in TokenRecord.tokenIds */
        uint32 tokenIdIdx;
    }

    address public ownerAddress;
    mapping(uint256 => EntityRecord) public entityRecordById;
    mapping(uint256 => TokenRecord) public tokenRecordById;
    mapping(uint256 => uint256) public entityIdByTokenId;
    uint256[] allEntityIds;

    // bytes4 private constant InterfaceId_TokenstampV1 = '';

    constructor(string _name, string _symbol) public {
        initialize(_name, _symbol);
        ownerAddress = msg.sender;
    }

    modifier onlyOwner {
        assert(isOwner());
        _;
    }

    function initialize() public {
        // _sizes[bytes4(sha3("getUint()"))] = 32;
        // _sizes[bytes4(sha3("requireYes(address,uint16,uint8)"))] = 32;
        // _sizes[bytes4(sha3("mint(address,bool)"))] = 256;
        // todo ERC721 value-returning methods here
    }

    function requireYes(address _address, uint16 _countryCode, uint8 _yes) external view {
        require(_yes < 64);
        uint256 entityId = this.tokenOfOwnerByIndex(_address, 0);
        EntityRecord storage s = entityRecordById[entityId]; // safe lookup unecessary  // EntityRecord storage s = entity(entityId);
        require(!s.locked && (s.yesmaskByCountryCode[_countryCode] & (uint64(1) << _yes)) > 0);
    }

    // todo isYes
    // function isYes(address _address, uint16 _country, uint8 _verification) external view {}

    /**
     * minting done by the owner of a token for its own entity
     */
    function mint(address _to, bool _minter) external returns (uint256) {
        uint256 tokenId = this.tokenOfOwnerByIndex(msg.sender, 0);
        require(tokenRecordById[tokenId].minter);
        uint256 entityId = entityIdByTokenId[tokenId];
        EntityRecord storage s = entity(entityId);
        require(!s.locked);
        return mintUnsafe(_to, entityId, _minter);
    }

    /**
     * minting done by the contract operator for any entity
     */
    function mint(address _to, uint256 _entityId, bool _minter) external onlyOwner returns (uint256) {
        return mintUnsafe(_to, _entityId, _minter);
    }

    function activate(uint256 _entityId, uint16 _countryCode, uint16 _yes) external onlyOwner {
        EntityRecord storage s = entity(_entityId);
        s.yesmaskByCountryCode[_countryCode] |= (uint64(1) << _yes);
    }

    function deactivate(uint256 _entityId, uint16 _countryCode, uint16 _no) external onlyOwner {
        EntityRecord storage s = entity(_entityId);
        s.yesmaskByCountryCode[_countryCode] &= ~(uint64(1) << _no);
    }

    function setLock(uint256 _entityId, bool _lock) external onlyOwner {
        EntityRecord storage s = entity(_entityId);
        s.locked = _lock;
    }

    function setYesmask(uint256 _entityId, uint16 _countryCode, uint64 __yesmask) external onlyOwner {
        EntityRecord storage s = entity(_entityId);
        s.yesmaskByCountryCode[_countryCode] = __yesmask; // &= ~(1 << _no);
    }

    //    function destroyEntity(uint256 _entityId) external onlyOwner {
//        // todo
//    }
//    function burn(uint256 _tokenId) external {
//        if(isOwner()) {
//            // owner can burn any token
//            // uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
//
//            super._burn(_owner, _tokenId);
//
//        } else {
//            tokenOfOwnerByIndex(msg.sender, 0)
//
//            // a minter can burn any token for the entity
//            require(tokenRecordById[_tokenId].minter); // a
//            uint256 entityId = entityIdByTokenId[_tokenId];
//            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
//            super._burn(_owner, _tokenId);
//
//        } else {
//            // any other token can burn itself
//        }
//    }

    /** non-permissed internal function with minting impl */
    function mintUnsafe(address _to, uint256 _entityId, bool _minter) internal returns (uint256) {
        EntityRecord storage s = entity(_entityId);
        uint256 tokenId = uint256(keccak256(abi.encodePacked(_entityId, s.tokenIdCounter++)));
        super._mint(_to, tokenId);
        tokenRecordById[tokenId].tokenIdIdx = uint32(s.tokenIds.length);
        tokenRecordById[tokenId].minter = _minter;
        s.tokenIds.push(tokenId);
        entityIdByTokenId[tokenId] = _entityId;
        return tokenId;
    }

    function entity(uint256 _entityId) internal returns (EntityRecord storage) {
        require(_entityId > 0);
        EntityRecord storage s = entityRecordById[_entityId];
        if(s.init) return s;
        s.init = true;
        s.entityIdIdx = uint32(allEntityIds.length);
        allEntityIds.push(_entityId);
        return s;
    }

    function isOwner() internal returns (bool) {
        return msg.sender == ownerAddress;
    }
}
