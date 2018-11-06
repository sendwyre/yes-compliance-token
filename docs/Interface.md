### Methods

**NOTES**:
 - No address can be associated with more than one identity (though addresses may have more than token). Issuance in this circumstance will fail.
 - One person _or_ business = one entity.
 - One entity may have *many* tokens across many addresses; they can mint and burn tokens tied to their verification status at will.
 - Two token types: control & non-control. Both carry compliance proof.
  - _control_ tokens let their holders mint and burn (within the same entity).
  - _non-control_ tokens are solely for compliance queries.
 - A lock on the entity is used instead of token revocation to remove the cash burden assumed by a customer to redistribute a fleet of coins.
 - All country codes should be via ISO-3166-1
 
 Any (non-view) methods not explicitly marked idempotent are not idempotent.
     
#### isYes

Query api: returns true if the specified address has the given country/yes attestation. this
is the primary method partners will use to query the active qualifications of any particular address.

``` js
function isYes(uint256 _validatorEntityId, address _address, uint16 _countryCode, uint8 _yes) external view returns(bool) ;
```

#### requireYes

Same as ```isYes``` except as an imperative.

``` js
function requireYes(uint256 _validatorEntityId, address _address, uint16 _countryCode, uint8 _yes) external view ;
```

#### getYes

Retrieve all YES marks for an address in a particular country. ```_validatorEntityId``` the validator ID to consider. Or, use 0 for any of them. 
* ```_address``` - The validator ID to consider, or 0 for any of them.
* ```_countryCode``` - The ISO-3166-1 country code
* _return_ - Non-duplicate array of YES marks present.

``` js
function getYes(uint256 _validatorEntityId, address _address, uint16 _countryCode) external view returns(uint8[] /* memory */);
```

*Excluding this?* ```// function getCountries(uint256 _validatorEntityId, address _address) external view returns(uint16[]  /* memory */);```

#### mint

Create new tokens. Fail if ```_to``` already belongs to a different entity and caller is not validator.
* ```_control``` - True if the new token is a control token (can mint, burn). aka NOT limited.
* ```_entityId``` - The entity to mint for, supply 0 to use the entity tied to the caller
* _return_  the newly created token ID

``` js
function mint(address _to, uint256 _entityId, bool _control) external returns (uint256);
```

#### mint (Shortcut)

Shortcut to mint() + setYes() in one call, for a single country.
``` js
function mint(address _to, uint256 _entityId, bool _control, uint16 _countryCode, uint8[] _yes) external returns (uint256);
```

#### burn

Destroys a specific token.

``` js
function burn(uint256 _tokenId) external;
```

#### burnEntity

Destroys the entire entity and all tokens.

``` js
function burnEntity(uint256 _entityId) external;
```

#### setYes

Adds a specific attestations (yes) to an entity. Idempotent: will return normally even if the mark was already set by this validator

``` js 
function setYes(uint256 _entityId, uint16 _countryCode, uint8 _yes) external;
```

#### clearYes (Validator-Entity)

Removes a attestation(s) from a specific validator for an entity. Idempotent.

``` js
function clearYes(uint256 _entityId, uint16 _countryCode, uint8 _yes) external;
```

#### clearYes (Country-Entity)

Removes all attestations in a given _country_ for a particular entity.
``` js
function clearYes(uint256 _entityId, uint16 _countryCode) external;
```

#### clearYes (Entire Entity)

Removes all attestations for a particular entity. Idempotent.
``` js
function clearYes(uint256 _entityId) external;
```

#### setLocked

Assigns a lock to an entity, rendering all isYes queries false. idempotent */
``` js
function setLocked(uint256 _entityId, bool _lock) external;
```

#### isLocked

Checks whether or not a particular entity is locked.
``` js
function isLocked(uint256 _entityId) external view returns(bool);
```

#### isFinalized

Returns true if the specified token has been finalized (cannot be moved) */
``` js
function isFinalized(uint256 _tokenId) external view returns(bool);
```

#### finalize

Finalizes a token by ID preventing it from getting moved. idempotent */
``` js
function finalize(uint256 _tokenId) external;
```

#### getEntityId

The entity ID associated with an address (or fail if there is not one) */
``` js
function getEntityId(address _address) external view returns(uint256);
```

### Events

#### Mint

MUST trigger when tokens are minted, including zero value transfers.

A contract which creates new tokens SHOULD trigger a Transfer event with the `_from` address set to `0x0` when tokens are created.

``` js
event Mint(address _to, uint256 _entityId, bool _control)
```

#### Burn

MUST trigger when entity or tokens are burned.

An entity which burns tokens SHOULD trigger a Burn event with the `_from` address set to `0x0` when anything is burned.
``` js
event Burn(uint256 _tokenId, uint256 _entityId)
```

#### Locked

MUST trigger when entity is locked.

``` js
event SetLocked(uint256 _entityId, bool _lock)
```

#### Finalize

MUST trigger when a Token is finalized.

Tokens SHOULD trigger a Finalize event with the `_tokenId` being set to `0x0` when tokens are created.
``` js
event finalize(uint256 _tokenId) external;
```

### Solidity Interface

``` js
pragma solidity ^0.4.23;


contract YesComplianceTokenV1 is ERC721Token /*, ERC165 :should: */ {

    uint256 public constant OWNER_ENTITY_ID = 1;
    uint8 public constant YESMARK_OWNER = 128;
    uint8 public constant YESMARK_VALIDATOR = 129;

    event Mint(address _to, uint256 _entityId, bool _control)
    event Burn(uint256 _tokenId, uint256 _entityId)
    event SetLocked(uint256 _entityId, bool _lock)
    event finalize(uint256 _tokenId)


function isYes(uint256 _validatorEntityId, address _address, uint16 _countryCode, uint8 _yes) external view returns(bool) ;
function requireYes(uint256 _validatorEntityId, address _address, uint16 _countryCode, uint8 _yes) external view ;
function getYes(uint256 _validatorEntityId, address _address, uint16 _countryCode) external view returns(uint8[] /* memory */);
function setYes(uint256 _entityId, uint16 _countryCode, uint8 _yes) external;

function clearYes(uint256 _entityId, uint16 _countryCode, uint8 _yes) external;
function clearYes(uint256 _entityId, uint16 _countryCode) external;
function clearYes(uint256 _entityId) external;

function mint(address _to, uint256 _entityId, bool _control) external returns (uint256);
function burn(uint256 _tokenId) external;
function burnEntity(uint256 _entityId) external;

function setLocked(uint256 _entityId, bool _lock) external;
function isLocked(uint256 _entityId) external view returns(bool);
function isFinalized(uint256 _tokenId) external view returns(bool);
function finalize(uint256 _tokenId) external;
```

### Implementation

A draft implementation covering the entirety of this spec is located [here](https://github.com/sendwyre/yes-compliance-token).
