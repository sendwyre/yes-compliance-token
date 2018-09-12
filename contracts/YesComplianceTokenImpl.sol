pragma solidity ^0.4.24;

// import "./Upgradeable.sol";
import "../submodules/openzeppelin-zos/contracts/token/ERC721/ERC721Token.sol";
import "./Upgradeable.sol";
import "../submodules/openzeppelin-zos/contracts/token/ERC20/ERC20.sol";
import "./YesComplianceTokenV1.sol";

/**
 * draft implementation of YES compliance token
 *
 * todo exclusivity rules to prevent an entity being both an individual & business
 * todo finish entity destruction
 *
 */
contract YesComplianceTokenImpl is /*Upgradeable,*/ ERC721Token, YesComplianceTokenV1 {

    uint64 private constant MAX_TOKENS_PER_ENTITY = 1024;

    // todo could shorten the entity IDs to anything 160+ to make this cheaper

    /*
     events: entity updated, destroyed
     */

    /**
     * a single YES attestation
     */
    struct YesMark {

        /** ISO-3166-1 country codes */
        uint16 countryCode;

        /**
         * the possibly-country-speicifc YES being marked.
         *

         */
        uint8 yes;

        // uint8 entityListIdx;

    }

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

        mapping(bytes4 => bool) yesMarksByKey;

        YesMark[] yesMarks;

        /**
         * all tokens associated with this identity
         */
        uint256[] tokenIds;

        // type - biz vs individual, other enum/XOR attributes?
        // trellisEndpoint?
    }

    /** all fields we want to add per-token */
    struct TokenRecord {
//        /** true for the first token issued to any entity (not sure if useful yet) */
//        bool origin;

        /** true if this token can mint/burn on behalf of this entity */
        bool control;

        /** position of the tokenId in EntityRecord.tokenIds */
        uint32 tokenIdIdx;

        // limitations: in/out?
    }

    // CONTRACT STATE --------------------------------------------------------------------------------------------------

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

//    function initializeForUpgrades() public {
//        // _sizes[bytes4(keccak256("getUint()"))] = 32;
//        // _sizes[bytes4(keccak256("requireYes(address,uint16,uint8)"))] = 32;
//        // _sizes[bytes4(keccak256("mint(address,bool)"))] = 256;
//        // todo ERC721 value-returning methods here
//    }

    // YesComplianceTokenV1 Interface Methods --------------------------------------------------------------------------

    function isYes(address _address, uint16 _countryCode, uint8 _yes) external view returns(bool) {
        return isYesInternal(_address, _countryCode, _yes);
    }

    function requireYes(address _address, uint16 _countryCode, uint8 _yes) external view {
        require(isYesInternal(_address, _countryCode, _yes));
    }

    function mint(address _to, bool _control) external returns (uint256) /* permission_mint_sender() */{
        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        require(tokenRecordById[tokenId].control);
        uint256 entityId = entityIdByTokenId[tokenId];
        // EntityRecord storage s = entity(entityId);
        // require(!s.locked); allow minting even when locked
        return mintUnsafe(_to, entityId, _control);
    }

    function burn(uint256 _tokenId) external permission_control_tokenId(_tokenId) {
        uint256 entityId = entityIdByTokenId[_tokenId];
        EntityRecord storage s = entity(entityId);
        TokenRecord storage t = tokenRecordById[_tokenId];

        // remove token from entity
        s.tokenIds[t.tokenIdIdx] = s.tokenIds[s.tokenIds.length - 1];
        delete(s.tokenIds[s.tokenIds.length - 1]); // i think is unnecessary, but have seen peeps do this...
        s.tokenIds.length--;

        // remove token record
        delete tokenRecordById[_tokenId];

        // burn the actual token
        super._burn(tokenOwner[_tokenId], _tokenId);
    }

    function mint(address _to, uint256 _entityId, bool _control) external permission_control_entityId(_entityId) returns (uint256) {
        return mintUnsafe(_to, _entityId, _control);
    }

    function destroyEntity(uint256 _entityId) external permission_control_entityId(_entityId) {
        // require(isOwner() || _entityId == entityIdByTokenId[tokenOfOwnerByIndex(msg.sender, 0)]);
        // todo implement me
        require(false);
    }

    function activate(uint256 _entityId, uint16 _countryCode, uint8 _yes) external permission_super {
        EntityRecord storage s = entity(_entityId);
        bytes4 key = yesKey(_countryCode, _yes);
        require(!s.yesMarksByKey[key]);
        s.yesMarksByKey[key] = true;
        s.yesMarks.push(YesMark(_countryCode, _yes));
    }

    function deactivate(uint256 _entityId, uint16 _countryCode, uint8 _yes) external permission_super {
        EntityRecord storage s = entity(_entityId);
        bytes4 key = yesKey(_countryCode, _yes);
        require(s.yesMarksByKey[key]);
        uint len = s.yesMarks.length;
        for(uint i=0; i<len; i++) {
            YesMark storage mark = s.yesMarks[i];
            if(_countryCode == mark.countryCode && _yes == mark.yes) {
                s.yesMarks[i] = s.yesMarks[len-1];
                delete s.yesMarks[len - 1]; // i think is unnecessary, but have seen peeps do this...
                s.yesMarks.length--;
                break;
            }
        }
        delete s.yesMarksByKey[key];
    }

    function deactivate(uint256 _entityId, uint16 _countryCode) external permission_super {
        EntityRecord storage s = entity(_entityId);
        // uint len = s.yesMarks.length;
        for(uint i = 0; i<s.yesMarks.length; i++) {
            YesMark storage mark = s.yesMarks[i];
            if(mark.countryCode != _countryCode)
                continue;
            s.yesMarks[i] = s.yesMarks[s.yesMarks.length-1];
            delete s.yesMarks[s.yesMarks.length - 1]; // i think is unnecessary, but have seen peeps do this...
            s.yesMarks.length--;
        }
    }

    function deactivate(uint256 _entityId) external permission_super {
        EntityRecord storage s = entity(_entityId);
        uint len = s.yesMarks.length;
        for(uint i = 0; i<len; i++) {
            YesMark storage mark = s.yesMarks[i];
            delete s.yesMarksByKey[yesKey(mark.countryCode, mark.yes)];
        }
        s.yesMarks.length = 0;
    }

    function setLocked(uint256 _entityId, bool _lock) external permission_super {
        EntityRecord storage s = entity(_entityId);
        s.locked = _lock;
    }

    //    function destroyEntity(uint256 _entityId) external onlyOwner {
    //        // todo
    //    }

    // Internal Methods ------------------------------------------------------------------------------------------------

    function isYesInternal(address _address, uint16 _countryCode, uint8 _yes) internal view returns(bool) {
        if(balanceOf(_address) == 0)
            return false;

        uint256 entityId = entityIdByTokenId[tokenOfOwnerByIndex(_address, 0)];
        EntityRecord storage s = entityRecordById[entityId];
        return (!s.locked && s.yesMarksByKey[yesKey(_countryCode, _yes)]);

        // return (!s.locked && (s.yesmaskByCountryCode[_countryCode] & (uint64(1) << _yes)) > 0);
    }

    /** non-permissed internal function with minting impl */
    function mintUnsafe(address _to, uint256 _entityId, bool _control) internal returns (uint256) {
        EntityRecord storage s = entity(_entityId);
        require(s.tokenIds.length < MAX_TOKENS_PER_ENTITY);
        uint256 tokenId = uint256(keccak256(abi.encodePacked(_entityId, s.tokenIdCounter++)));
        super._mint(_to, tokenId);
        tokenRecordById[tokenId].tokenIdIdx = uint32(s.tokenIds.length);
        tokenRecordById[tokenId].control = _control;
        s.tokenIds.push(tokenId);
        entityIdByTokenId[tokenId] = _entityId;
        return tokenId;
    }

    /** centralized entity resolution */
    function entity(uint256 _entityId) internal returns (EntityRecord storage) {
        require(_entityId > 0);
        EntityRecord storage s = entityRecordById[_entityId];
        if(s.init) return s;
        s.init = true;
        s.entityIdIdx = uint32(allEntityIds.length);
        allEntityIds.push(_entityId);
        return s;
    }

    /** override default addTokenTo for additional transaction limitations */
    function addTokenTo(address _to, uint256 _tokenId) internal {
        uint256 entityId = entityIdByTokenId[_tokenId];

        // ensure one owner cannot be associated with multiple entities
        // todo this breaks hotwallet integrations
        if(balanceOf(_to) > 0) {
            uint256 prevEntityId = entityIdByTokenId[tokenOfOwnerByIndex(_to, 0)];
            require(prevEntityId == entityId);
        }

        super.addTokenTo(_to, _tokenId);
    }

    /** the sender is the same entity as the one specified */
    function senderIsEntity_ByEntityId(uint256 _entityId) internal view returns (bool) {
        return _entityId == entityIdByTokenId[tokenOfOwnerByIndex(msg.sender, 0)];
    }

    /** the sender is the same entity as the one specified, and the sender is a control for that entity */
    function senderIsControl_ByEntityId(uint256 _entityId) internal view returns (bool) {
        uint256 tokenId = tokenOfOwnerByIndex(msg.sender, 0);
        uint256 senderEntityId = entityIdByTokenId[tokenId];
        return _entityId == senderEntityId && tokenRecordById[tokenId].control;
    }

    /** the sender is the same entity as the one tied to the token specified */
    function senderIsEntity_ByTokenId(uint256 _tokenId) internal view returns (bool) {
        return entityIdByTokenId[_tokenId] == entityIdByTokenId[tokenOfOwnerByIndex(msg.sender, 0)];
    }

    /** the sender is the same entity as the one tied to the token specified, and the sender is a control for that entity */
    function senderIsControl_ByTokenId(uint256 _tokenId) internal view returns (bool) {
        uint256 senderEntityId = entityIdByTokenId[tokenOfOwnerByIndex(msg.sender, 0)];
        return entityIdByTokenId[_tokenId] == senderEntityId && tokenRecordById[_tokenId].control;
    }

    /** the contract owner */
    function senderIsContractOwner() internal view returns (bool) {
        return msg.sender == ownerAddress;
    }

    /** a key for a YesMark */
    function yesKey(uint16 _countryCode, uint8 _yes) internal pure returns(bytes4) {
        return bytes4(keccak256(abi.encodePacked(_countryCode, _yes)));
    }

    // PERMISSIONS MODIFIERS ----------------------------------------------------------------

    modifier permission_super {
        assert(senderIsContractOwner());
        _;
    }

    modifier permission_access_entityId(uint256 _entityId) {
        assert(senderIsContractOwner() || senderIsEntity_ByEntityId(_entityId));
        _;
    }

    modifier permission_control_entityId(uint256 _entityId) {
        assert(senderIsContractOwner() || senderIsControl_ByEntityId(_entityId));
        _;
    }

    modifier permission_access_tokenId(uint256 _tokenId) {
        assert(senderIsContractOwner() || senderIsEntity_ByTokenId(_tokenId));
        _;
    }

    modifier permission_control_tokenId(uint256 _tokenId) {
        assert(senderIsContractOwner() || senderIsControl_ByTokenId(_tokenId));
        _;
    }

}
