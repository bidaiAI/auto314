import test from "node:test";
import assert from "node:assert/strict";
import { officialBootstrapTargetsFor, shouldUseLegacyBscArtifactsFor } from "./specs";

test("officialBootstrapTargetsFor returns the BSC bootstrap set only for BSC", () => {
  const targets = officialBootstrapTargetsFor(56, "0xf264DEf5f915628c57190616931bDf19df2cf225");
  assert.equal(targets.length, 5);
  assert.equal(targets[4]?.label, "Official LaunchFactory");
});

test("officialBootstrapTargetsFor returns the Base bootstrap set for the official Base factory", () => {
  const targets = officialBootstrapTargetsFor(8453, "0x95302fb1Aa9cD62F070E512B3d415d8388742a22");
  assert.equal(targets.length, 5);
  assert.equal(targets[4]?.label, "Official LaunchFactory");
});

test("officialBootstrapTargetsFor returns no Base bootstrap targets for a non-official Base factory", () => {
  const targets = officialBootstrapTargetsFor(8453, "0x0000000000000000000000000000000000000001");
  assert.equal(targets.length, 0);
});

test("shouldUseLegacyBscArtifactsFor only enables legacy artifacts for the official BSC factory", () => {
  assert.equal(
    shouldUseLegacyBscArtifactsFor(56, "0xa5d62930AA7CDD332B6bF1A32dB0cC7095FC0314"),
    true
  );
  assert.equal(
    shouldUseLegacyBscArtifactsFor(56, "0xf264DEf5f915628c57190616931bDf19df2cf225"),
    false
  );
  assert.equal(
    shouldUseLegacyBscArtifactsFor(56, "0x0000000000000000000000000000000000000001"),
    false
  );
  assert.equal(
    shouldUseLegacyBscArtifactsFor(8453, "0xa5d62930AA7CDD332B6bF1A32dB0cC7095FC0314"),
    false
  );
});
