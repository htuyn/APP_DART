class BlockchainConfig {
  BlockchainConfig._();

  static const int sepoliaChainId = 11155111;
  static const String sepoliaRpcUrl = String.fromEnvironment(
    'SEPOLIA_RPC_URL',
    defaultValue: 'https://ethereum-sepolia-rpc.publicnode.com',
  );
  static const String contractAddress =
      '0x40cc19d362d52f6d7bf2a3bc5c3298b204ecfea9';
  static const String issuerRelayerUrl = String.fromEnvironment(
    'ISSUER_RELAYER_URL',
    defaultValue: 'http://localhost:8787',
  );
  static const String issuerRelayerApiKey = String.fromEnvironment(
    'ISSUER_RELAYER_API_KEY',
    defaultValue: 'local-development-relayer-key-change-me',
  );
  static const int eventScanWindow = 5000;
  static const int contractDeploymentBlock = int.fromEnvironment(
    'CERTIFICATE_CONTRACT_DEPLOYMENT_BLOCK',
    defaultValue: 0,
  );
  static const String abiAssetPath = 'assets/blockchain/achievement_abi.json';
  static const String explorerBaseUrl = 'https://sepolia.etherscan.io';

  static String txExplorerUrl(String txHash) => '$explorerBaseUrl/tx/$txHash';
  static String addressExplorerUrl(String address) =>
      '$explorerBaseUrl/address/$address';
}
