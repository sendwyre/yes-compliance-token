---
eip: ???
title: "YES Compliance Token"
author:
type: ?
category: ? 
status: Draft
created: 2018-09-08
---

## YES Compliance Token

### Abstract

This document describes the operation of a flexible, lightweight on-chain compliance ecosystem. It provides a simple,
privacy-focused mechanism for _end-users_ to acquire proof-of-compliance tokens, for _validators_ to validate and attest
this proof, and for _integrators_ to query the state of the proof.

We provision the compliance attestation through ERC721-compliant non-fungible tokens. This interfacing allows end-users
to independently, freely, and securely associate or de-associate their compliance status with a large number of Ethereum 
accounts at their own discretion.

These tokens are issued by _validators_. These are organizations which provide specific
verifications for end-users; ultimately, the minter reputation backs the attestations they distribute. The specific 
statements allowable are defined authoritatively by this document and may be country-specific.

When an end-user attempts to interact with some 3rd-party financial service or application which supports this protocol 
(an _integrator_), they can query the compliance status of the end-user on the blockchain. Beyond the ERC721 address 
management interface, a set of query APIs are defined so that the partner can contextualize their needs and 
quickly acquire an authoritative answer. All defined attestations are boolean; they may be present or not, without 
degree.

One deployed contract of this token encompasses a single ecosystem of recognized minters in the space. This
ensures that any partner attempting to query compliance status need not ask many minters separately, but rather
query them all through a single token. The original owner of the contract (Wyre, in our case) ultimately controls
the ecosystem of authorized validators.

_Future_: Token 'proxying' to enable Wyre to delegate token recognition to a specific whitelist of other YES-compatible
tokens so that other top-level minters could maintain their own networks of partners, yet remain queryable through a single
token interface.

### Specification

See the YES interface definition [here](contracts/yes/YesComplianceTokenV1.sol).

The YES system is made of two high-level token types: validator and identity. The token
interface is provided solely for (standardized) flexibility in managing the status/permission of any particular Ethereum 
address.

Validator tokens are those held by the
validators giving them permission to mint new compliance tokens for any identity, and add/remove the YES compliance 
attestations. Identity tokens represent a link to some formally identified entity - business or individual - which has met 
specific compliance requirements, as attested to by the validators. 

Within the context of identity tokens, there are two subtypes: standard and control. Both are linked to an identified
entity so either can be used equivalently as holder-proof-of-compliance. However, control tokens additionally give their 
holder permission to mint new compliance tokens (either control or standard) or burn other tokens (only those linked
to their identity), enabling them the flexibility to manage any set of addresses however they choose.

Attempting to move a token to an address that already possesses a token linking it to a different address is forbidden;
one address can be associated with at most a single entity (but one address could own many tokens linked to their own 
identity).

As such, any entity may have many identity tokens which all link back to a single entity compliance status. That entity
consists of a collection of specific attestations as defined by the section below. Querying the token (via `isYes` or `requireYes`)
without specifying an explicit set of allowable validators implies all validators are considered. 

***Locking:*** An entity may be locked. This may be invoked by any validator against any entity and suspends that entity from 
receiving any compliance approval. This is intended to function in response to any type of compliance flag that throws
the overall validity of the identity into question - as in the case of possible identity theft or fraud. However, in 
the happy case where the alert is cleared, we save a lot of fees and token-holder effort by flipping one bit instead
of needing to re-issue possibly many coins to many addresses. 

***Finalization:*** Permissable to any token holder, this will prevent the token from ever being moved. It could only
get burned. In systems which have no use to move the tokens around once they reach their target, this adds a small 
degree of safety for tokens to be erroneously (or maliciously) moved.

#### Compliance Attestations 

A YES mark (8-bit unsigned integer) is a number which, by convention, maps to a specific compliance attestation as given 
below. 

[*] means all country codes, [840] means US only (probably needs revising) (ISO-3166-1 country code)

    Individual: (lower 4 bits)
    1: financially compliant individual (country-wide/strictest) [*]
    2: 2. accredited investor (individual) [840]

    Business: (upper 4 bits)
    16. financially compliant business (country-wide/strictest) [*] 
    17. MSB [840]

***Regarding MSBs:*** todo

### Motivation

todo

### Rationale

todo


    