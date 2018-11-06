## Explain Like I'm 5 - ERC-DeFi

Applying a walkthrough with familiar use-cases, identifying the relevant hurdles, and how they're addressed. We're proposing the following:

#### WHAT
* Lets not require every entrepreneur to pour capital out getting licenses and legal opinions, just to goto market.
* Give businesses a chance to reduce costs of operating, by sharing resources and minimizing duplicate efforts.
* Lower the number of targets that could be compromised (customer data or AUM).
* Require user data only on a need to know basis. 
* Prioritize user privacy.
* Optimize UX.
* Balance former regulatory standards with new technology. Educating and collaborating with end goal of adjusting the requirements.

#### HOW
* Regulated platforms (called "Validators") take information and issue a token to the user ("entity"). Think of it like a *blue check mark on twitter*
* Validators choose to allow "control" to the end user. Meaning users can issue more tokens to their other wallets that carry this same verification from the validator.
* Validators remain liable for user-activity.
* Validators can lock an entity, it pauses the status of verification. Good example of this would be a verified account, and then the user documents expiring and being needed to re-verify in order to keep trading on an exchange. The exchange would "lock" the entity, which means the verification tick mark from that particular exchange would be paused. Other validator status' are unaffected.
* Platforms disclose user information to other platforms, if required by legal intervention (DOJ, Subpoena, etc...)
* Publicly available lookup. Kind of like a public utility for everyone to use. Not a paid service.
* Validators can work together, which would allow a validators users to immediately get attestation from the other validator. 

### Example - As a regulated platform

* **ABC SecurityTokens, Inc.** is a registered broker dealer in North America. `Validator`

* **Alice** needs to submit her relevant information plus letter from legal (stating she's met certain income or asset requirements) in order to satisfy the _Accredited Investor_ status. `Entity`

* Alice's documentation is approved. `Tier`

* Alice opts in to receive a verification token, so when she trades on TradingDeFi.io she is not required to re-submit all her information again. `mint`

* Alice specifies that she uses a number of devices & wallets, so she'd like flexibility to issue more tokens across them instead of needing to always revert back to ABC SecurityTokens, Inc. `_control true`

ABC SecurityTokens, Inc. is now going to `mint` a token for Alice, their new user. I'm using the shortcut (cited [here](https://github.com/sendwyre/EIP-Resources/blob/master/Interface.md)) because it creates the entity **and** mints the token for that entity.


``` js
function mint(
address _to, 
uint256 _entityId, 
bool _control, 
uint16 _countryCode, 
uint8[] _yes
) 
external returns (uint256);
```


Lets go ahead and sub in our relevant information to mint this token for Alice!



``` js
function mint(
address 0x12345, // Alice's address.
uint256 42424242, // Specified by ABC SecurityTokens, Inc. Their internal account Id.
bool true, // Alice said she would like to be able to create more tokens for herself. _control == true.
uint16 840, // We're in North America.
uint8[] [1,10] // "1" because the Tier 1 AML/KYC successful. "10" - Accredited Investor successful.
) 
external returns (999333); // Alice's tokenId.
```


### Example - As a non-regulated platform

TradingDeFi.io is a team of 3 devs. Alicia, Antonia, and Adam. They've built an amazing UX, but don't have any background, education, or capital to learn the legal requirements needed to service any customers.

They know that ABC SecurityTokens, Inc. is fully compliant, so for their MVP they decide to permit anyone who's verified by ABC SecurityTokens, Inc. to trade on their platform.

In order to do that, the users that visit the site will supply their address and they'll use the `isYes` function.

Alice (same Alice from before btw) shows up to the website, and they check her status.



``` js
function isYes(
uint256 222222, //  This is the validatorId of ABC SecurityTokens, Inc. Set by them when they first started.
address 0x12345, // Visitors address. In this case, Alice's.
uint16 840, // USA customers they're trying to serve. Knowing that ABC is regulated for this. 
uint8 [10] // TradingDeFi.io could be highly regulated, so they're following the ABC lead, and only permitting _Accredited Investors_ which is marked "10" to trade while they wait to save some funds to get a legal opinion.
) 
external view returns(true) // It returns _true_ because Alice is verified from her on-boarding.
```



- [x] Alicia, Antonia, and Adam are validating their MVP and servicing customers (safely).

- [x] The team are not holding sensitive customer data, and not a target for attacks.

- [x] TradingTokens.com is only accessible by to accredited investors, verifiable on-chain by everyone.

- [x] Alice has her sensitive data sitting with one entity, not multiple.

- [x] Alice has zero friction trying the service out.



### Implementation

If this resonates, and you're interested to play around, there's a draft implementation completed which can be found [here](https://github.com/sendwyre/yes-compliance-token).

### Comparison examples
This is showing the incumbents, the licenses they have. It's to identify participants that could add meaningful value to the innovation of DeFi.

If you're building out in a particular category, then you're ideally wanting one of the incumbent types to start participating as a validator to provide more on-chain identifiers. Aiming to open a larger user-base for new entrepreneurs who are capital constrained to fulfill all regulatory licensing on their own. 

#### Money
Before: WorldFirst, Transferwise, OFX, PayPal, Western Union.

License examples: Money Services Business (US), Money Service Operator (HK), FCA (UK), E-Money (EU), etc...

DeFi: Payments/Remittances, e.g. Abra, Bitpesa, BitSpark, Wyre, Veem, etc...

GICS Category - #40203040

#### Securities
Before: Robinhood

License examples: Broker Dealer License (US), Money Services Business (US)

DeFi: DEX's, e.g. IDEX, ERC-DEX, Paradex.

GICS Category - #40203040

#### Lending
Before: LendingClub, Sofi, 9fBank

Licenses: Collections License (US-State), State Licensed Consumer Lending(US-State), Life Insurance Agency Licenses (US-State)

DeFi: Dharma Relayer, Salt (?), Compound (?)

GICS Category - #40202010

#### Gaming
Before: Ladbrokes, SportingBet, Pokerstars, FunFair

License Examples: Remote casino operating license, Gibraltar

After: FunFair (Licensed), Augur Dapp, etc...

GICS Category: #25301010

### Notes & Resources

First pass, nothing in stone but good to get the ideas flowing for other readers...

**Masterlist required for _each_ of the following:**

List | Standard | Status | Reference
---- | -------- |------- |---------- |
Countries | ISO | Done | [Link.](https://www.iso.org/iso-3166-country-codes.html)
Industry | GICS | Please discuss | [Link.](https://en.wikipedia.org/wiki/Global_Industry_Classification_Standard)
Licenses (Per country) | State/Federal (US) | Please discuss | [Link.](https://docs.google.com/spreadsheets/d/1pcxcnSB_ViDZvao3ckSogUfbTbBalrU4WngYXgSiawE/edit?usp=sharing)



Any feedback/comments/criticisms is appreciated! [Twitter](https://www.twitter.com/sendwyre) / [Email](ERC@sendwyre.com) / [Site](https://www.sendwyre.com) / [Github](https://vignette.wikia.nocookie.net/epicrapbattlesofhistory/images/f/fd/2680765-nicolas_cage_you_dont_say.jpg/revision/latest?cb=20150209201221&format=original).
