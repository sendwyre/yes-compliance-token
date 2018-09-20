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
privacy-focused mechanism for _end-users_ to acquire proof-of-compliance tokens, for _minters_ to validate and attest
this proof, and for _partners_ to query the state of the proof.

We provision the compliance attestation through ERC721-compliant non-fungible tokens. This interfacing allows end-users
to independently, freely, and securely associate or de-associate their compliance status with a large number of Ethereum 
accounts at their own discretion.

These tokens are issued by _minters_. A minter in this context is any organization which provides some degree of 
verification for an end-user; ultimately, the minter reputation backs the attestations they distribute. The specific 
statements allowable are defined authoritatively by this document and may be country-specific.

When an end-user attempts to interact with some 3rd-party financial service which supports this protocol (a _partner_), the
partner can query the compliance status of the end-user via the blockchain. Beyond the ERC721 interface, a set 
of query APIs are defined so that the partner can contextualize their needs and quickly acquire an authoritative 
answer. All defined attestations are boolean; they may be present or not, without degree.

One deployed contract of this token encompasses a single ecosystem of recognized partners in the space. This
ensures that any partner attempting to query compliance status need not ask many partners individually, but rather
query a network of partners by via a single token. Entry into the network as a minter is gated by the 
original owner of the contract (Wyre).

_Future_: Token 'proxying' to enable Wyre to delegate token recognition to a specific whitelist of other YES-compatible
tokens so that other top-level minters could maintain their own networks of partners, yet remain queryable through a single
token interface.

### Specification

todo

See the YES interface definition ![here](contracts/YesComplianceTokenV1.sol).

#### Attributions 

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


    