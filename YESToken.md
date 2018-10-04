---
eip: ???
title: "YES Compliance Token"
author:
type: ?
category: ? 
status: Draft
created: 2018-09-08
---

ROUGH DRAFT

## YES Compliance Token

### Abstract

This document describes the operation of a flexible, lightweight on-chain compliance ecosystem. It provides a simple,
privacy-focused mechanism for _end-users_ to acquire proof-of-compliance tokens, for _validators_ to validate and attest
this proof, and for _integrators_ to query the state of the proof. It furthermore defines the mechanics of how this
design fosters a safe, legally compliant blockchain environment.

We provision the compliance attestation through ERC721-compliant non-fungible tokens. This interfacing allows end-users
to independently, freely, and securely associate or de-associate their compliance status with many Ethereum 
addresses at their own discretion.

These tokens are issued by _validators_. These are organizations which provide specific
verifications for end-users; ultimately, the ecosystem owner (Wyre) backs the attestations distributed on the network. 
The specific attestations allowed are defined authoritatively by this document and may be country-specific.

When an end-user attempts to interact with some 3rd-party financial service or application which supports this protocol 
(an _integrator_), the application can quickly query the compliance status of the end-user on the blockchain. Beyond 
the ERC721 interface, a set of query APIs are defined so that the partner can contextualize their needs and 
acquire a direct authoritative answer on the compliance status of a particular address. All defined attestations
are boolean; they may be present or not, without degree.

One deployed contract of this token encompasses a single ecosystem of recognized minters in the space. This
ensures that any partner attempting to query compliance status need not ask many minters separately, but rather
query them all through a single token. The _ecosystem owner_ (original owner of the contract - Wyre, in our case) 
ultimately controls the list of authorized validators.

### Specification

See the YES interface definition [here](contracts/yes/YesComplianceTokenV1.sol).

#### Token Operation

The YES system distinguishes between _tokens_ and _entities_. An entity is a business or individual which maintains
some verified compliance status. An entity may have many tokens. One token will always have a single entity. All
token are linked to an identified entity and can be used as proof-of-compliance. They represent a formally identified 
entity - business or individual - which has met specific compliance requirements, as attested to by one or more validators. 

There are two high-level token types: standard and control. Both tokens are generally identical in 
functionality (and appearance!), except that control tokens grant their holder additional permissions. This distinction
is made solely for security. Control tokens permit their holders the ability to mint new tokens as well as burn 
existing ones. Standard tokens are used solely for identification; they provide no minting powers, though do allow 
self-destruction/self-burn.

Typically, a validator would mint and send one new control to a user once their compliance status is passing. Because 
it's a control token, the user would be free to create more of them (control or standard) and distribute them to any
other addresses they would like to identify with (using the increasingly well-known ERC721).

***Validators*** are entities with the `129. Ecosystem Validator` YES mark. They are the parties who are
interacting with the end-user to process their proof of identity, and they have reporting (and liability?)
agreements established with the ecosystem owner. This gives that entity the ability to create new YES attestations 
for any entity. (Though, only the ecosystem owner has the ability to mark entities with with `129`) 
For auditability, all YES attestations marked carry the set of validator ID(s) which validated them. 

Attempting to move a token to an address that already possesses a token linking it to a different address is forbidden;
one address can be associated with at most a single entity (but one address could own many tokens linked to that single
entity).

As such, any entity may have many tokens which all link back to a single record of compliance (entity). That entity
consists of a collection of specific attestations as defined by the section below. Querying the token (via `isYes` 
or `requireYes`) without specifying an explicit set of allowable validators implies any validator is considered. 

***Locking:*** An entity may be locked. This may be invoked by any validator against any entity and suspends that entity from 
receiving any compliance approval. This is intended to function in response to any type of compliance flag that throws
the overall validity of the identity into question - as in the case of possible identity theft or fraud. However, in 
the happy case where the alert is cleared, we save a lot of fees and token-holder effort by flipping one bit instead
of needing to re-issue possibly many coins to many addresses. 

***Finalization:*** Permissible to any token holder, this will prevent the token from ever being moved. It could only
get burned. In systems which have no use to move the tokens around once they reach their target, this adds a small 
degree of safety for tokens to be erroneously (or maliciously) moved.

***Proxying:*** _TODO/Future/Maybe_: Token 'proxying' to enable the ecosystem owner to delegate token recognition to 
a specific whitelist of other YES-compatible tokens so that other top-level minters could maintain their own networks 
of partners, yet remain queryable through a single token interface.

#### Regulatory Mechanics

The usage of these tokens ***does not*** relinquish the need for businesses themselves to always remain compliant. However,
any business may establish an agreement with Wyre (or another ecosystem) which offloads the KYC/AML requirements to the
ecosystem owner. In the case of applications which manage user-controlled funds, they are not money services businesses,
as they do not custodialize their customers' funds. Therefore, they are not required to maintain these licenses. 

However, this passes the buck of remaining compliant to the end-user. If someone wants to trade money with a friend, with an 
exchange, with a business, anywhere - they want to know they are fully and properly handing over the liability of 
what happens with those funds. They can only do this if there is a chain of liable, well-identified parties. They needn't
know or maintain any personal details of the end-user; only a legal guarantee from a liable party. All ongoing reporting
and fraud prevention
is the responsibility of the liable party (Wyre), which may have delegated it further (through agreements) with other
parties (validators). 

In the cases of businesses which custodialize their customers' funds, they must (at the least, in the US) be licensed 
money service businesses. They must follow all relevant reporting requirements as dictated by their business practices
in their own locality, and this protocol does nothing to alleviate those requirements. However, this protocol does
offer an avenue to enable simpler offloading of this relatively rigorous process to any of the validators in the 
ecosystem. By forming an agreement with a validator, enabling an end-user UX flow for such processing, they can gain
access to a much larger body of verified customers through the on-chain query API. 

By offering channels which give compliant users access to other compliant users, we
create a very flexible but legally safe financial environment on the blockchain. This reduction in friction will 
increase access to the rapidly burgeoning innovation coming from the cryptocurrency space. 

#### YES Marks: Compliance Attestation Codes

A YES mark (8-bit unsigned integer) is a code which, by convention, maps to a specific compliance attestation as given 
below. The tiers of permissions required for the outlined mechanics are also encapsulated within this structure via 
codes 128 and 129. All codes are granted in country-specific contexts, except for the owner code 128 (which has a country
code of 0).

`[*]` means all country codes, `[840]` means US only (probably needs revising) (ISO-3166-1 country code)

    Individual: (most significant bit is 0)
    1. Compliant Individual - country-wide/strictest [*]
    2. Accredited Investor [840 or *?]

    Business: (most significant bit is 1)
    128. (special) Ecosystem Owner - there will only be one of these, can attest all marks except 128 [0]
    129. (special) Ecosystem Validator - can attest all marks except 128, 129 [0]
    
    130. Compliant Business - country-wide/strictest [*]
    131. Money Services Business [*] (question: should this be [840] US only or does this distinction indeed exist elsewhere)
    132. ??? Bank [*]
    133. ??? Public Corporation [*]

Note the `[0]` on 128/129, indicating that these codes are not contextualized by country, so are only valid when the country
code is 0.

### Motivations

In drafting this design, our primary goal has been to materialize a direct, simple, clean implementation which solves
the most glaring problems facing us and our partners in the space. We need a way to attach simple attestations
that had predefined definitions in the context of compliance, per-country.

There are components of it, entirely or in part, present in many other blockchain identity and/or compliance protocols. 
The landscape surrounding these efforts is evolving very quickly, and we acknowledge that the eventuality of this design
may give way to simply punting to another protocol or ecosystem (or not). If there are other existing 
protocols which meet the functionality (both technically and mechanically) of this protocol with nearly-equal simplicity 
that are either more well-thought or more well-adopted to a significant degree, please feel free to shit on this one.

In any case, the relative simplicity of this approach enables quick iteration as we hone in on the problem areas. We
anticipate moving quickly on changes in response to our customers' precise needs.





    