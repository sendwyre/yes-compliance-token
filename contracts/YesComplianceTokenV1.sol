pragma solidity ^0.4.24;

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
 *
 * Structure of YES:
 * [*] means all country codes, [840] means US only (probably needs revising)
 *
 * Individual:
 * 1: financially compliant individual (country-wide/strictest) [*]
 * 2: accredited investor (invidivual) [840]
 *
 * Business:
 * 16: financially compliant business (country-wide/strictest) [*]
 * 17: MSB [840]
 *
 */
interface YesComplianceTokenV1 /* is ERC721Token /*, Upgradeable /*, ERC165 */ {

    /**
     * primary query api: returns true if the specified address has the given country/yes attestation
     */
    function isYes(address _address, uint16 _countryCode, uint8 _yes) external view returns(bool) ;

    /** same as isYes except as an imperative */
    function requireYes(address _address, uint16 _countryCode, uint8 _yes) external view ;

    /**
     * minting done by the owner of a token for its own entity
     */
    function mint(address _to, bool _control) external returns (uint256) /* permission_mint_sender() */ ;

    /** destroys a specific token */
    function burn(uint256 _tokenId) external ;

    /**
     * minting done by the contract operator for an explicit entity
     */
    function mint(address _to, uint256 _entityId, bool _control) external returns (uint256);

    /** destroys the entire entity and all tokens */
    function destroyEntity(uint256 _entityId) external;

    /** adds a specific yes to an entity */
    function activate(uint256 _entityId, uint16 _countryCode, uint8 _yes) external;

    /** removes a specific yes for an entity */
    function deactivate(uint256 _entityId, uint16 _countryCode, uint8 _yes) external;

    /** removes all YesMarks in a given country for a particular entity */
    function deactivate(uint256 _entityId, uint16 _countryCode) external;

    /** removes all YesMarks for a particular entity */
    function deactivate(uint256 _entityId) external;

    /** assigns a lock to an entity, rendering all isYes queries false */
    function setLock(uint256 _entityId, bool _lock) external;

}
