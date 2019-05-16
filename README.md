# improved-yarn-audit

This project aims to improve upon the existing Yarn package manager audit functionality.

[![NPM](https://nodei.co/npm/improved-yarn-audit.png)](https://nodei.co/npm/improved-yarn-audit/)

Currently `yarn audit` has several issues making it difficult to use in a CI pipeline:

- No way to ignore advisories
- Unable to filter out low severity issues
- Ongoing network issues with NPM registry cause false positives

`improved-yarn-audit` provides a wrapper around the `yarn audit` command which addresses all of the above problems.

## Installing

Run:

```
yarn add improved-yarn-audit
```

## Running an Audit Check

To execute an audit check, run:

```
yarn run improved-yarn-audit
```

## Setting the Severity Level

You can define a minimum severity level to report, any advisories below this level are ignored.

```
yarn run improved-yarn-audit --min-severity moderate
```

*Run with `--help` to see all levels available*

## Excluding Advisories

Often dev dependencies can become outdated and the package maintainer no long provides updates. This leads to audit advisories that will never affect your production code.

To remedy this, you can pass a csv list of advisory IDs to ignore.

```
yarn run improved-yarn-audit --exclude 253,456,811
```

## Retrying Network Issues

As of May 2019 there are outstanding network issues with the NPM registry audit API, which cause frequent request failues. To work around this until a fix is implemented you can pass a flag to retry any failed requests.

```
yarn run improved-yarn-audit --retry-on-network-failure
```

## NPM Users

If you are an NPM fan looking for a similar solution, checkout the [better-npm-audit](https://www.npmjs.com/package/better-npm-audit) package.
