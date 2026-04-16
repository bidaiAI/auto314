import { existsSync, readFileSync } from "fs";
import { dirname, join, resolve } from "path";
import { fileURLToPath } from "url";
import { encodeDeployData, getAddress, type Abi, type Hex } from "viem";

export type ContractBuildSpec = {
  contractIdentifier: string;
  sourceName: string;
  contractName: string;
  abi: Abi;
  bytecode: Hex;
  compilerVersion: string;
  stdJsonInput: Record<string, unknown>;
  metadata: Record<string, unknown>;
};

export type BootstrapVerificationTarget = {
  address: `0x${string}`;
  contractIdentifier: string;
  creationTransactionHash: `0x${string}`;
  label: string;
  source: "official";
};

const officialFactoryWhitelistPresetsByChain: Record<number, { thresholds: bigint[]; slotSizes: bigint[] }> = {
  56: {
    thresholds: [4n * 10n ** 18n, 6n * 10n ** 18n, 8n * 10n ** 18n],
    slotSizes: [1n * 10n ** 17n, 2n * 10n ** 17n, 5n * 10n ** 17n, 1n * 10n ** 18n]
  },
  8453: {
    thresholds: [1n * 10n ** 18n, 2n * 10n ** 18n, 3n * 10n ** 18n],
    slotSizes: [4n * 10n ** 16n, 1n * 10n ** 17n, 2n * 10n ** 17n, 25n * 10n ** 16n]
  }
};

type BuildInfoFile = {
  input: Record<string, unknown>;
  output: {
    contracts: Record<string, Record<string, { metadata?: string }>>;
  };
  solcVersion: string;
  solcLongVersion?: string;
};

type ArtifactJson = {
  abi: Abi;
  bytecode: Hex;
  contractName: string;
  sourceName: string;
};

type DebugArtifactJson = {
  buildInfo: string;
};

const moduleDir = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(moduleDir, "..", "..", "..", "..");
const bundledArtifactsRoot = resolve(moduleDir, "..", "..", "verification-artifacts");
const bundledBscLegacyArtifactsRoot = resolve(moduleDir, "..", "..", "verification-artifacts-bsc-legacy");
const currentOfficialBscFactoryAddress = getAddress("0xf264DEf5f915628c57190616931bDf19df2cf225");
const legacyOfficialBscFactoryAddress = getAddress("0xa5d62930AA7CDD332B6bF1A32dB0cC7095FC0314");

const buildSpecCache = new Map<string, ContractBuildSpec>();
const solidityMetadataMarkers = [
  "a264697066735822",
  "a264697066735820",
  "a165627a7a72305820"
] as const;

const officialBscBootstrapTargets: BootstrapVerificationTarget[] = [
  {
    address: getAddress("0x4A4b56885738A950F245F852143Dd75301B5c0dA"),
    contractIdentifier: "contracts/LaunchTokenDeployer.sol:LaunchTokenDeployer",
    creationTransactionHash: "0x439bf06a068baceea7b6e7489bb3af176ee82b6fe78896c57391f8b622ffb861",
    label: "Official LaunchTokenDeployer",
    source: "official"
  },
  {
    address: getAddress("0x4099ed5E06F4a8DfCFE05207f60ed520Cfa2e99c"),
    contractIdentifier: "contracts/LaunchCreate2Deployer.sol:LaunchCreate2Deployer",
    creationTransactionHash: "0x92a6a5e3f0dfd619e03fe6c160ad84253ec2c90348b9f2192741a54161e7cf77",
    label: "Official Whitelist LaunchCreate2Deployer",
    source: "official"
  },
  {
    address: getAddress("0x5CE6613F6640341d7440FD7c2Bb477BB0c91899E"),
    contractIdentifier: "contracts/LaunchTokenTaxedDeployer.sol:LaunchTokenTaxedDeployer",
    creationTransactionHash: "0x2d63f031c300677e79a7c12c7a1e9494c0844af982d97166487e02ffcbf606c1",
    label: "Official LaunchTokenTaxedDeployer",
    source: "official"
  },
  {
    address: getAddress("0x35758F11Eafa76B5cdFCf73d8495FB5D87446646"),
    contractIdentifier: "contracts/LaunchCreate2Deployer.sol:LaunchCreate2Deployer",
    creationTransactionHash: "0xa3b954a5ce6e8da9ba89d8ba4dc54ce89732f7a279fa035f83c63adf95a761b5",
    label: "Official WhitelistTaxed LaunchCreate2Deployer",
    source: "official"
  },
  {
    address: currentOfficialBscFactoryAddress,
    contractIdentifier: "contracts/LaunchFactory.sol:LaunchFactory",
    creationTransactionHash: "0xbd39eadf6b753e05b1d4b8f9fb73d61eae9f72f3964026decbaec7aed825cb8a",
    label: "Official LaunchFactory",
    source: "official"
  }
];

const officialBaseBootstrapTargets: BootstrapVerificationTarget[] = [
  {
    address: getAddress("0xEf6e2A4012012782520636f92411360Eef04e85F"),
    contractIdentifier: "contracts/LaunchTokenDeployer.sol:LaunchTokenDeployer",
    creationTransactionHash: "0x42276e0768de38e285818c17755dda60dc6f89acd5e3aadf3ea5962633b7b7b7",
    label: "Official LaunchTokenDeployer",
    source: "official"
  },
  {
    address: getAddress("0x7DC13A23cE2Ec1C0958a0edc9B2f48fB9B953Bf8"),
    contractIdentifier: "contracts/LaunchCreate2Deployer.sol:LaunchCreate2Deployer",
    creationTransactionHash: "0x387c963aaf5b1a1b5f6c9e38e709dc1a13c393d8f6a3719431c160627fe4f4ad",
    label: "Official Whitelist LaunchCreate2Deployer",
    source: "official"
  },
  {
    address: getAddress("0xD7d6cc1dD8ad78759b45243722dBb2be548a02b4"),
    contractIdentifier: "contracts/LaunchTokenTaxedDeployer.sol:LaunchTokenTaxedDeployer",
    creationTransactionHash: "0x95d137375a88d8679226dfd00182006859bcdeac87ca3a2f5aae94e273450a4c",
    label: "Official LaunchTokenTaxedDeployer",
    source: "official"
  },
  {
    address: getAddress("0x493F48a18C1c63D2B33bA0883FA85FF044bB70B6"),
    contractIdentifier: "contracts/LaunchCreate2Deployer.sol:LaunchCreate2Deployer",
    creationTransactionHash: "0x2ae6c0300a23052b6e52a1f654106ba58fa02a86b5d4bea33576b91dce11d44b",
    label: "Official WhitelistTaxed LaunchCreate2Deployer",
    source: "official"
  },
  {
    address: getAddress("0x95302fb1Aa9cD62F070E512B3d415d8388742a22"),
    contractIdentifier: "contracts/LaunchFactory.sol:LaunchFactory",
    creationTransactionHash: "0x7f83969f3b8aecec11fc9b2adb98f55703b677e76678b8635973b4abdc7854ce",
    label: "Official LaunchFactory",
    source: "official"
  }
];

const officialBootstrapTargetsByChain: Record<number, BootstrapVerificationTarget[]> = {
  56: officialBscBootstrapTargets,
  8453: officialBaseBootstrapTargets
};

function readJson<T>(path: string): T {
  return JSON.parse(readFileSync(path, "utf-8")) as T;
}

export function shouldUseLegacyBscArtifactsFor(chainId?: number | null, factoryAddress?: string) {
  if (chainId !== 56 || !factoryAddress) {
    return false;
  }

  try {
    return getAddress(factoryAddress) === legacyOfficialBscFactoryAddress;
  } catch {
    return false;
  }
}

function resolveCandidateArtifactsRoots() {
  const runtimeChainId = process.env.INDEXER_CHAIN_ID ? Number(process.env.INDEXER_CHAIN_ID) : null;
  const runtimeFactoryAddress = process.env.INDEXER_FACTORY_ADDRESS;
  const roots = [
    process.env.INDEXER_VERIFICATION_ARTIFACTS_ROOT
      ? resolve(process.env.INDEXER_VERIFICATION_ARTIFACTS_ROOT)
      : null,
    shouldUseLegacyBscArtifactsFor(runtimeChainId, runtimeFactoryAddress) ? bundledBscLegacyArtifactsRoot : null,
    join(repoRoot, "packages", "contracts", "artifacts"),
    bundledArtifactsRoot
  ].filter((root): root is string => Boolean(root));

  return [...new Set(roots)];
}

function resolveArtifactPaths(contractIdentifier: string) {
  const [sourceName, contractName] = contractIdentifier.split(":");
  if (!sourceName || !contractName) {
    throw new Error(`Invalid contract identifier: ${contractIdentifier}`);
  }

  const candidateArtifactsRoots = resolveCandidateArtifactsRoots();

  for (const artifactsRoot of candidateArtifactsRoots) {
    const artifactPath = join(artifactsRoot, sourceName, `${contractName}.json`);
    const debugArtifactPath = join(artifactsRoot, sourceName, `${contractName}.dbg.json`);
    if (existsSync(artifactPath) && existsSync(debugArtifactPath)) {
      return {
        sourceName,
        contractName,
        artifactPath,
        debugArtifactPath
      };
    }
  }

  throw new Error(
    `Missing artifact files for ${contractIdentifier} in ${candidateArtifactsRoots.join(", ")}`
  );
}

export function loadContractBuildSpec(contractIdentifier: string): ContractBuildSpec {
  const { sourceName, contractName, artifactPath, debugArtifactPath } = resolveArtifactPaths(contractIdentifier);
  const cacheKey = `${artifactPath}:${contractIdentifier}`;
  const cached = buildSpecCache.get(cacheKey);
  if (cached) return cached;

  const artifact = readJson<ArtifactJson>(artifactPath);
  const debugArtifact = readJson<DebugArtifactJson>(debugArtifactPath);
  const buildInfoPath = resolve(dirname(debugArtifactPath), debugArtifact.buildInfo);
  const buildInfo = readJson<BuildInfoFile>(buildInfoPath);
  const metadataRaw = buildInfo.output.contracts[sourceName]?.[contractName]?.metadata;

  if (!metadataRaw) {
    throw new Error(`Missing metadata for ${contractIdentifier}`);
  }

  const spec: ContractBuildSpec = {
    contractIdentifier,
    sourceName,
    contractName,
    abi: artifact.abi,
    bytecode: artifact.bytecode,
    compilerVersion: buildInfo.solcLongVersion ?? buildInfo.solcVersion,
    stdJsonInput: buildInfo.input,
    metadata: JSON.parse(metadataRaw) as Record<string, unknown>
  };

  buildSpecCache.set(cacheKey, spec);
  return spec;
}

export function encodeConstructorArguments(contractIdentifier: string, args: readonly unknown[]): Hex {
  const spec = loadContractBuildSpec(contractIdentifier);
  const deployData = encodeDeployData({
    abi: spec.abi,
    bytecode: spec.bytecode,
    args
  });
  return (`0x${deployData.slice(spec.bytecode.length)}` || "0x") as Hex;
}

export function constructorInputCount(contractIdentifier: string) {
  const spec = loadContractBuildSpec(contractIdentifier);
  const constructorAbi = spec.abi.find((entry) => entry.type === "constructor");
  return constructorAbi?.type === "constructor" ? constructorAbi.inputs.length : 0;
}

function findSolidityMetadataStart(bytecode: Hex) {
  const normalized = bytecode.toLowerCase();
  let index = -1;
  for (const marker of solidityMetadataMarkers) {
    index = Math.max(index, normalized.lastIndexOf(marker));
  }
  return index >= 0 ? index : null;
}

function hasCompatibleCreationPrefix(bytecode: Hex, creationInput: Hex) {
  if (creationInput.startsWith(bytecode)) {
    return true;
  }

  if (creationInput.length < bytecode.length) {
    return false;
  }

  const metadataStart = findSolidityMetadataStart(bytecode);
  if (metadataStart === null) {
    return false;
  }

  const expectedPrefix = bytecode.toLowerCase();
  const actualPrefix = creationInput.slice(0, bytecode.length).toLowerCase();
  return actualPrefix.slice(0, metadataStart) === expectedPrefix.slice(0, metadataStart);
}

export function extractConstructorArgumentsFromCreationInput(contractIdentifier: string, creationInput: Hex): Hex {
  const spec = loadContractBuildSpec(contractIdentifier);
  if (!hasCompatibleCreationPrefix(spec.bytecode, creationInput)) {
    throw new Error(`Creation input for ${contractIdentifier} does not match artifact bytecode prefix`);
  }
  return (`0x${creationInput.slice(spec.bytecode.length)}` || "0x") as Hex;
}

export function findSolidityMetadataStartForTest(bytecode: Hex) {
  return findSolidityMetadataStart(bytecode);
}

export function launchContractIdentifierForMode(mode: number) {
  if (mode === 1) return "contracts/LaunchToken.sol:LaunchToken";
  if (mode === 2) return "contracts/LaunchTokenWhitelist.sol:LaunchTokenWhitelist";
  if (mode >= 3 && mode <= 11) return "contracts/LaunchTokenTaxed.sol:LaunchTokenTaxed";
  if (mode === 12) return "contracts/LaunchTokenWhitelistTaxed.sol:LaunchTokenWhitelistTaxed";
  throw new Error(`Unsupported launch mode for verification: ${mode}`);
}

export function officialBootstrapTargetsFor(chainId: number, factoryAddress?: `0x${string}`) {
  const targets = officialBootstrapTargetsByChain[chainId] ?? [] as BootstrapVerificationTarget[];
  if (chainId === 56) {
    if (factoryAddress && getAddress(factoryAddress) !== officialBscBootstrapTargets[4].address) {
      return [] as BootstrapVerificationTarget[];
    }
    return targets;
  }
  if (chainId === 8453) {
    if (factoryAddress && getAddress(factoryAddress) !== officialBaseBootstrapTargets[4].address) {
      return [] as BootstrapVerificationTarget[];
    }
    return targets;
  }
  return targets;
}

export function officialFactoryWhitelistPresetsFor(chainId: number) {
  return officialFactoryWhitelistPresetsByChain[chainId] ?? null;
}
