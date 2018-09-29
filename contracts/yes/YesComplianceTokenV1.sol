pragma solidity ^0.4.24;

import "../../submodules/openzeppelin-zos/contracts/token/ERC721/ERC721Token.sol";

/**
 * an ERC721 "yes" compliance token supporting a collection of country-specific attributions which answer specific
 * compliance-related queries with YES. (attributions)
 *
 * primarily ERC721 is useful for the self-management of claiming addresses. a single token is more useful
 * than a non-ERC721 interface because of interop with other 721-supporting systems/ui; it allows users to
 * manage their financial stamp with flexibility, using a well-established simple concept of non-fungible tokens.
 * this interface is for anyone needing to carry around and otherwise manage their proof of compliance.
 *
 * the financial systems these users authenticate against have a different set of API requirements. they need
 * more contextualization ability than a balance check to support distinctions of attestations, as well as geographic
 * distinction. these integrations are made simpler as the language of the query more closely match the language of compliance.
 *
 * this interface describes, beyond 721, these simple compliance-specific interfaces (and their management tools)
 *
 * notes:
 *  - no address can be associated with more than one identity (though addresses may have more than token). issuance
 *    in this circumstance will fail
 *  - one person or business = one entity
 *  - one entity may have many tokens across many addresses; they can mint and burn tokens tied to their identity at will
 *  - two token types: control & non-control. both carry compliance proof
 *  - control tokens let their holders mint and burn (within the same entity)
 *  - non-control tokens are solely for compliance queries
 *  - a lock on the entity is used instead of token revocation to remove the cash burden assumed by a customer to
 *    redistribute a fleet of coins
 *  - all country codes should be via ISO-3166-1
 *
 */
contract YesComplianceTokenV1 is ERC721Token/*, ERC165 */ {

    // PARTNER INTERFACE - functionality beyond 721 for facilitating partner queries and operations

    /**
     * query api: returns true if the specified address has the given country/yes attestation. this
     * is the primary method partners will use to query the active qualifications of any particular
     * address.
     */
    function isYes(address _address, uint16 _countryCode, uint8 _yes) external view returns(bool) ;

    /** same as isYes except as an imperative */
    function requireYes(address _address, uint16 _countryCode, uint8 _yes) external view ;

    // function getYes(address _address, uint16 _countryCode)
    // function getYes(uint256 _entityId, uint16 _countryCode)
    // function getYes(uint256 _entityId)

    /**
     * minting with an implied entity. the caller must have a control token. will fail if _to already belongs
     * to a different entity.
     *
     * @param _control true if the new token is a control token (can mint, burn)
     */
    function mint(address _to, bool _control) external returns (uint256) /* permission_mint_sender() */ ;

    /** destroys a specific token. tokens can destroy themselves. control tokens can destroy any token (in same entity). */
    function burn(uint256 _tokenId) external ;

    // OPERATOR INTERFACE - functionality for contract operator (wyre)

    /** destroys the entire entity and all tokens (should this be partner interface?) */
    function destroyEntity(uint256 _entityId) external;

    /** minting done by the contract operator for an explicit entity */
    function mint(address _to, uint256 _entityId, bool _control) external returns (uint256);

    // function mint(address _to, uint256 _entityId, bool _control, bool _final) external returns (uint256);

    /** adds a specific yes to an entity */
    function activate(uint256 _entityId, uint16 _countryCode, uint8 _yes) external;

    /** removes a specific yes for an entity */
    function deactivate(uint256 _entityId, uint16 _countryCode, uint8 _yes) external;

    /** removes all YesMarks in a given country for a particular entity */
    function deactivate(uint256 _entityId, uint16 _countryCode) external;

    /** removes all YesMarks for a particular entity */
    function deactivate(uint256 _entityId) external;

    /** assigns a lock to an entity, rendering all isYes queries false */
    function setLocked(uint256 _entityId, bool _lock) external;

    // function isLocked(uint256 _entityId) ?
    // function isLocked(address _address) ? partner interface?

    // isFinalized
    // finalize()

}