pragma solidity ^0.4.24;

import "../../submodules/openzeppelin-zos/contracts/token/ERC721/ERC721Token.sol";

/**
 * @notice an ERC721 "yes" compliance token supporting a collection of country-specific attributions which answer specific
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

    /**
     * @notice query api: returns true if the specified address has the given country/yes attestation. this
     * is the primary method partners will use to query the active qualifications of any particular
     * address.
     */
    function isYes(uint256 _validatorEntityId, address _address, uint16 _countryCode, uint8 _yes) external view returns(bool) ;

    /** @notice same as isYes except as an imperative */
    function requireYes(uint256 _validatorEntityId, address _address, uint16 _countryCode, uint8 _yes) external view ;

    /**
     * @notice retrieve all YES marks for an address in a particular country
     * @param _validatorEntityId the validator ID to consider. or, use 0 for any of them
     * @param _address the validator ID to consider, or 0 for any of them
     * @param _countryCode the ISO-3166-1 country code
     */
    function getYes(uint256 _validatorEntityId, address _address, uint16 _countryCode) external view returns(uint8[]);

    /**
     * @notice retrieve all YES marks grouped by country for a particular address
     * @param _validatorEntityId the validator ID to consider. or, use 0 for any of them
     * @param _address the validator ID to consider, or 0 for any of them
     */
    function getYes(uint256 _validatorEntityId, address _address, uint16 _countryCode) external view returns(uint8[]);

    /**
     * @notice retrieve all YES marks grouped by country for a particular address
     * @param _validatorEntityId the validator ID to consider. or, use 0 for any of them
     * @param _address the validator ID to consider, or 0 for any of them
     */
    function getYes(uint256 _validatorEntityId, address _address) external view returns(mapping(uint16=>uint8[]));

    /**
     * @notice create new tokens. the caller must have a control token. will fail if _to already
     * belongs to a different entity. minting to any entity other than the one associated with the caller
     * is only allowed by validators.
     * @param _control true if the new token is a control token (can mint, burn)
     * @param _entityId the entity to mint for, supply 0 to use the entity tied to the caller
     */
    function mint(address _to, uint256 _entityId, bool _control) external returns (uint256);

    // function mint(address _to, bool _control) external returns (uint256) /* permission_mint_sender() */ ;

    /** @notice destroys a specific token. tokens can destroy themselves. control tokens can destroy any token (in same entity). */
    function burn(uint256 _tokenId) external ;

    // OPERATOR INTERFACE - functionality for contract operator (wyre)

    /** @notice destroys the entire entity and all tokens (should this be partner interface?) */
    function burnEntity(uint256 _entityId) external;

    // function mint(address _to, uint256 _entityId, bool _control, bool _final) external returns (uint256);

    /** @notice adds a specific attestations (yes) to an entity */
    function setAttestation(uint256 _entityId, uint16 _countryCode, uint8 _yes) external;

    /**
     * @notice removes a attestation(s) from a specific validator for an entity
     * @param _validatorEntityId either a specific validator entity id, or 0 for any/all
     */
    function clearAttestations(uint256 _validatorEntityId, uint256 _entityId, uint16 _countryCode, uint8 _yes) external;

    /** @notice  removes all attestations in a given country for a particular entity */
    function clearAttestations(uint256 _entityId, uint16 _countryCode) external;

    /** @notice removes all attestations for a particular entity */
    function clearAttestations(uint256 _entityId) external;

    /** @notice assigns a lock to an entity, rendering all isYes queries false */
    function setLocked(uint256 _entityId, bool _lock) external;

    /** @notice checks whether or not a particular entity is locked */
    function isLocked(uint256 _entityId) external view returns(boolean);

    /** @notice retrieve the entity ID associated with an address (or fail if there is not one) */
    function getEntityId(address _address) external view returns(uint256);


    // function isLocked(address _address) ? partner interface?
    // isFinalized
    // finalize()

}
